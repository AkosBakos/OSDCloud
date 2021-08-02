
#================================================
#   AutopilotOOBE Configuration Staging
#================================================
$AutopilotOOBEJson = @'
{
    "Assign":  {
                   "IsPresent":  true
               },
    "GroupTag":  "Mittelschulen",
    "AddToGroup": "sg-GYMKG",
    "AddToGroupOptions":  [
                    "sg-GYMKG",
                    "sg-GYMWM"
    ],
    "Hidden":  [
                   "AssignedComputerName",
                   "AssignedUser",
                   "PostAction",
                   "GroupTag",
                   "Assign"
               ],
    "PostAction":  "SysprepReboot",
    "Run":  "NetworkingWireless",
    "Docs":  "https://google.com/",
    "Title":  "EDUBS PoC Autopilot Register"
}
'@
If (!(Test-Path "C:\ProgramData\OSDeploy")) {
    New-Item "C:\ProgramData\OSDeploy" -ItemType Directory -Force | Out-Null
}
$AutopilotOOBEJson | Out-File -FilePath "C:\ProgramData\OSDeploy\OSDeploy.AutopilotOOBE.json" -Encoding ascii -Force

#================================================
#   [OS] Starting OSDCloud ZTI
#================================================

#Change Display Resolution for Virtual Machine
if ((Get-MyComputerModel) -match 'Virtual') {
    Write-Host  -ForegroundColor Green "Setting Display Resolution to 1600x"
    Set-DisRes 1600
}

#Make sure I have the latest OSD Content
Write-Host -ForegroundColor Green "Updating OSD PowerShell Module"
Install-Module OSD -Force

Write-Host  -ForegroundColor Green "Importing OSD PowerShell Module"
Import-Module OSD -Force   

#Start OSDCloud ZTI
Write-Host -ForegroundColor Green "Start OSDCloud"
Start-OSDCloud -OSLanguage en-us -OSBuild "20H2" -OSEdition Enterprise -ZTI

Write-Host -ForegroundColor Green "Create C:\Windows\System32\Autopilot.cmd"
$AutopilotCMD = @'
PowerShell -NoL -Com Set-ExecutionPolicy RemoteSigned -Force
Set Path = %PATH%;C:\Program Files\WindowsPowerShell\Scripts
Start /Wait PowerShell -NoL -C Install-Module AutopilotOOBE -Force -Verbose
Start /Wait PowerShell -NoL -C Start-AutopilotOOBE  
'@
$AutopilotCMD | Out-File -FilePath 'C:\Windows\System32\Autopilot.cmd' -Encoding ascii -Force

Write-Host -ForegroundColor Green "Create C:\Windows\System32\PostOOBE.cmd"
$PostOOBECMD = @'
PowerShell -NoL -Com Set-ExecutionPolicy RemoteSigned -Force
Set Path = %PATH%;C:\Program Files\WindowsPowerShell\Scripts
REM Start PowerShell -NoL -W Mi
Start /Wait PowerShell -NoL -C Install-Module AutopilotOOBE -Force -Verbose
Start /Wait PowerShell -NoL -C Start-OOBEDeploy -AddNetFX3 -UpdateDrivers -UpdateWindows -RemoveAppx Xbox,Zune
Start /Wait PowerShell -NoL -C Restart-Computer -Force
'@

$PostOOBECMD | Out-File -FilePath 'C:\Windows\System32\PostOOBE.cmd' -Encoding ascii -Force

#Restart from WinPE
Write-Host  -ForegroundColor Green "Restarting in 20 seconds!"
Start-Sleep -Seconds 20
wpeutil reboot