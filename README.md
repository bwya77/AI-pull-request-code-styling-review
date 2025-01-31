# AI-Powered Code Style Review for Pull Requests

Automate code style reviews in Azure DevOps using AI to detect violations, suggest fixes, and enforce team standards in your pull request pipeline.

## Features

- Automated code style checking on pull requests
- AI-powered violation detection and fix suggestions
- Individual comments for each violation in pull requests
- Pipeline integration with Azure DevOps
- Customizable style guide enforcement
- Build validation policies for automated enforcement

## Project Structure

```
├── README.md
├── powershell-style-check-pipeline.yml
└── tests
    ├── check_styling.ps1
    └── powershell_stylingguide.json
```

## Prerequisites

- Azure DevOps
- OpenAI API Access

## Detailed Guide

For complete implementation details, configuration steps, and examples, read the full blog post:
[Automating Code Compliance: AI-Driven PowerShell Style Enforcement for Pull Requests](https://www.thelazyadministrator.com/2025/01/31/automating-code-compliance-ai-driven-powershell-style-enforcement-for-pull-requests/)

## Example Output

When style violations are detected, the system:
- Creates individual comments for each file with violations
- Provides suggested fixes with explanations
- Generates a summary report
- Optionally blocks PR completion until violations are resolved
