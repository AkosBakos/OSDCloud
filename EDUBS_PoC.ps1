Write-Host -ForegroundColor Green "Starting OSDCloud ZTI"
Start-Sleep -Seconds 5

#Change Display Resolution for Virtual Machine
if ((Get-MyComputerModel) -match 'Virtual') {
    Write-Host  -ForegroundColor Green "Setting Display Resolution to 1600x"
    Set-DisRes 1600
}

#Make sure I have the latest OSD Content
Write-Host -ForegroundColor Green "Updating OSD PowerShell Module"
Install-Module OSD -Force -Verbose

Write-Host  -ForegroundColor Green "Importing OSD PowerShell Module"
Import-Module OSD -Force -Verbose

#Start OSDCloudScriptPad
Write-Host -ForegroundColor Green "Start OSDCloudScriptPad"
Start-ScriptPad -GitOwner AkosBakos -GitRepo OSDCloud -GitPath ScriptPad