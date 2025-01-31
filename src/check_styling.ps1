[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ })]
    [string]$StylingGuidePath,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ModifiedFiles,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$OpenAIKey
)

function Send-StyleCheckRequest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$FileContent,
        [Parameter(Mandatory)]
        [string]$StyleGuide,
        [Parameter(Mandatory)]
        [string]$ApiKey,
        [Parameter(Mandatory)]
        [string]$FilePath
    )

    $headers = @{
        'Authorization' = "Bearer $ApiKey"
        'Content-Type'  = 'application/json'
    }

    $body = @{
        model       = 'gpt-4'
        messages    = @(
            @{
                role    = 'system'
                content = 'You are a PowerShell code review assistant. Review code against the provided style guide. For each violation, provide both the issue and a suggested fix using code examples. Return "NO_VIOLATIONS" if no issues found. Always include a count of total violations found at the start of your response.'
            }
            @{
                role    = 'user'
                content = @"
Style Guide:
$StyleGuide

PowerShell Code to Review:
$FileContent

Review this PowerShell code against the style guide. Structure your response as follows:

1. Start with "VIOLATION_COUNT:[number]" on its own line
2. Then for each violation:
   - Use the format "### Violation XX - [Category] - [Brief Description]" where XX is the zero-padded number (01, 02, etc.)
   - Under each violation header:
     * Show the current code in a powershell code block
     * Show the suggested fix in a powershell code block
     * Explain why this improves compliance with the style guide

Format each violation consistently following this template:

### Violation XX - [Category] - [Brief Description]
**Current Code:**
\`\`\`powershell
# Problem code here
\`\`\`

**Suggested Fix:**
\`\`\`powershell
# Fixed code here
\`\`\`

**Explanation:** Why this change improves style guide compliance.

If no violations exist, respond with NO_VIOLATIONS.
"@
            }
        )
        temperature = 0.7
    } | ConvertTo-Json -Depth 10

    try {
        $response = Invoke-RestMethod -Uri 'https://api.openai.com/v1/chat/completions' -Method Post -Headers $headers -Body $body
        Write-Host "Debug: Received response from OpenAI"
        return $response.choices[0].message.content
    }
    catch {
        Write-Error "Failed to get OpenAI response: $_"
        throw
    }
}

function Add-PullRequestComment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Content,
        [Parameter()]
        [string]$FilePath = $null
    )

    try {
        if (-not $env:SYSTEM_PULLREQUEST_PULLREQUESTID) {
            Write-Host "Not running in PR context, skipping comment creation"
            return
        }

        $organization = $env:SYSTEM_COLLECTIONURI.TrimEnd('/')
        $project = $env:SYSTEM_TEAMPROJECT
        $repositoryId = $env:BUILD_REPOSITORY_ID
        $pullRequestId = $env:SYSTEM_PULLREQUEST_PULLREQUESTID

        $url = "$organization/$project/_apis/git/repositories/$repositoryId/pullRequests/$pullRequestId/threads?api-version=7.1"

        $body = @{
            comments = @(
                @{
                    content = $Content
                }
            )
            status   = "active"
        }

        if ($FilePath) {
            $body.threadContext = @{
                filePath = $FilePath
            }
        }

        $body = $body | ConvertTo-Json -Depth 10

        $headers = @{
            'Authorization' = "Bearer $env:SYSTEM_ACCESSTOKEN"
            'Content-Type'  = 'application/json'
        }

        Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body
        Write-Host "Successfully created PR comment"
    }
    catch {
        Write-Warning "Unable to create PR comment: $_"
    }
}

try {
    Write-Host "Debug: Start of script"
    Write-Host "Debug: StylingGuidePath = $StylingGuidePath"
    Write-Host "Debug: ModifiedFiles received = $ModifiedFiles"

    # Read the style guide
    $styleGuide = Get-Content -Path $StylingGuidePath -Raw
    Write-Host "Debug: Successfully read style guide"

    Write-Host "Debug: Attempting to parse ModifiedFiles"
    $modifiedFilesList = $ModifiedFiles | ConvertFrom-Json
    Write-Host "Debug: Successfully parsed JSON. Found $($modifiedFilesList.Count) files"

    $totalFiles = 0
    $totalViolations = 0
    $filesWithViolations = @()

    foreach ($file in $modifiedFilesList) {
        Write-Host "Debug: Processing file: $file"
        
        if (Test-Path $file) {
            $totalFiles++
            $fileContent = Get-Content -Path $file -Raw
            Write-Host "Debug: Successfully read file content"

            if ([string]::IsNullOrWhiteSpace($fileContent)) {
                Write-Host "File is empty, skipping style check"
                continue
            }

            $violations = Send-StyleCheckRequest -FileContent $fileContent -StyleGuide $styleGuide -ApiKey $OpenAIKey -FilePath $file

            if ($violations -ne "NO_VIOLATIONS") {
                # Extract violation count from first line
                if ($violations -match "VIOLATION_COUNT:(\d+)") {
                    $violationCount = [int]$Matches[1]
                    $totalViolations += $violationCount
                    
                    # Remove the count line from the response
                    $violations = ($violations -split "`n" | Select-Object -Skip 1) -join "`n"
                }

                Write-Host "Debug: Violations found in $file"
                $filesWithViolations += @{
                    Path           = $file
                    Name           = $file.Split('/')[-1]
                    ViolationCount = $violationCount
                    Violations     = $violations
                }
            }
        }
        else {
            Write-Warning "File not found: $file"
        }
    }

    # Create the report file path
    $reportPath = Join-Path $env:BUILD_ARTIFACTSTAGINGDIRECTORY "StyleViolations.md"

    # Create comments if violations were found
    if ($totalViolations -gt 0) {
        # First post individual file violation comments
        foreach ($file in $filesWithViolations) {
            $fileComment = "### Style Guide Violations for $($file.Name)
**File Path:** $($file.Path)

$($file.Violations)"
            
            Add-PullRequestComment -Content $fileComment -FilePath $file.Path
        }

        # Then post the overview comment last
        $overviewComment = "⚠️ PowerShell Style Guide Violations Found

# PowerShell Style Check Summary

## Overview
- Total files checked: $totalFiles
- Files with violations: $($filesWithViolations.Count)
- Total violations found: $totalViolations

## Files with Violations"

        foreach ($file in $filesWithViolations) {
            $overviewComment += "
- **$($file.Name)** - $($file.ViolationCount) violation(s)"
        }

        $overviewComment += "

Please review the file-specific comments above for detailed information about each violation."
        
        # Post overview comment
        Add-PullRequestComment -Content $overviewComment

        # Create report file for artifact
        $overviewComment | Out-File -FilePath $reportPath -Encoding UTF8

        Write-Error "Style guide violations found. See report for details."
        exit 1
    }
    else {
        Write-Host "✅ No style guide violations found in any files!"
        
        # Create an empty report file to avoid publishing artifact failure
        "# PowerShell Style Check Results`n`n✅ No style guide violations found in any files!" | Out-File -FilePath $reportPath -Encoding UTF8
        
        exit 0
    }
}
catch {
    Write-Host "Debug: Script failed with error: $_"
    Write-Host "Debug: Stack trace: $($_.ScriptStackTrace)"
    Write-Error "Script failed: $_"
    exit 1
}
