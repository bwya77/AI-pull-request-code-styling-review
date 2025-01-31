## Keywords and Syntax

### Language Keywords
- Rule: All PowerShell language keywords must be lowercase
- Examples:
  ```powershell
  foreach ($item in $collection)
  if ($value -eq $true)
  where-object { $_.name -match 'pattern' }
  dynamicparam {}
  ```

### Help Keywords
- Rule: Keywords in comment-based help must be uppercase
- Examples:
  ```powershell
  .SYNOPSIS
  .DESCRIPTION
  .PARAMETER
  .EXAMPLE
  .INPUTS
  .OUTPUTS
  .NOTES
  ```

## Naming Conventions

### Public Identifiers
- Rule: Use PascalCase for all public identifiers
- Examples:
  ```powershell
  function Get-Process {}
  $Global:ConfigurationValue
  $Script:LoggingPreference
  ```

### Function Naming
- Rule: Use Verb-Noun format with PascalCase for both parts
- Examples:
  ```powershell
  function Get-UserProfile {}
  function Start-ProcessManager {}
  function Update-ServiceConfiguration {}
  ```

### Two-Letter Acronyms
- Rule: Capitalize both letters in two-letter acronyms
- Examples:
  ```powershell
  $PSDefaultParameterValues
  Get-PSHost
  $VMId
  ```

## Code Structure

### Brace Style
- Rules:
  - Opening brace: Place at end of line
  - Closing brace: Place at beginning of line
  - Exception: Small scriptblocks passed as parameters
- Examples:
  ```powershell
  if ($value) {
      # code
  }
  Get-Process | Where-Object { $_.CPU -gt 10 }
  ```

### Function Template
- Rule: All functions must include CmdletBinding and standard blocks
- Example:
  ```powershell
  function Verb-Noun {
      [CmdletBinding()]
      param ()
      begin {
      }
      process {
      }
      end {
      }
  }
  ```

## Formatting

### Line Length
- Rule: Maximum 115 characters per line
- Example:
  ```powershell
  Get-ChildItem -Path $LongPath |
      Where-Object { $_.Length -gt 100MB } |
      Select-Object Name, Length
  ```

### Spacing
- Rules:
  - Single space around parameter names and operators
  - Exceptions: Switch parameters and unary operators
- Examples:
  ```powershell
  $result = Get-Content -Path $file -Wait:$true
  $count++
  $date = (Get-Date).AddDays(-1)
  ```

### Whitespace
- Rules:
  - No trailing whitespace
  - Single space inside braces/parentheses
  - No spaces inside parentheses/brackets
- Examples:
  ```powershell
  $( Get-Process ).Count
  ${variable}
  function Get-Example { $value }
  ```

## Best Practices

### Return Values
- Rules:
  - Don't use return keyword
  - Output objects in process block
- Example:
  ```powershell
  process {
      $result
  }
  ```

### Output Type
- Rule: Specify OutputType for advanced functions
- Examples:
  ```powershell
  [OutputType([System.String])]
  [OutputType('System.IO.FileInfo', ParameterSetName = 'Path')]
  ```

### Parameter Sets
- Rule: Always provide DefaultParameterSetName when using parameter sets
- Example:
  ```powershell
  [CmdletBinding(DefaultParameterSetName = 'Path')]
  param (
      [Parameter(ParameterSetName = 'Path')]
      [string]$Path,
      [Parameter(ParameterSetName = 'LiteralPath')]
      [string]$LiteralPath
  )
  ```

### Parameter Validation
- Rule: Use parameter validation attributes instead of body validation
- Examples:
  ```powershell
  # AllowNull
  param (
      [AllowNull()]
      [string]$ComputerName
  )

  # ValidateRange
  param (
      [ValidateRange(0, 100)]
      [int]$Percentage
  )

  # ValidateSet
  param (
      [ValidateSet('Low', 'Medium', 'High')]
      [string]$Priority
  )
  ```

## Documentation

### Comment-Based Help
- Rule: Place comment-based help inside function at the beginning
- Example:
  ```powershell
  function Get-Example {
      <#
      .SYNOPSIS
          Brief description
      .DESCRIPTION
          Detailed description
      .PARAMETER Name
          Parameter description
      .EXAMPLE
          Example usage
      #>
      [CmdletBinding()]
      param ()
      process {
      }
  }
  ```
### File Ending
- Rule: All script files should end with a single blank line
- Example:
    ``` powershell
	function Get-Process {
	    # Function code here
	}
	# This is the last line of code
	# Below this comment is a single blank line

	```
