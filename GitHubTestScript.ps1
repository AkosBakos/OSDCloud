function Test-GitHubScript
{
    [CmdletBinding()]
    param()
}

if (Get-Command Test-PutThisToAzureKeyVault)
{
  Write-Host 'Test-PutThisToAzureKeyVault function is added to this PowerShell session' -ForegroundColor Green
  Test-GitHubScript -Verbose
}
