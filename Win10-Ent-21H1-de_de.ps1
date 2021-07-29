Write-Host -ForegroundColor Green "Starting OSDCloud ZTI"
Start-Sleep -Seconds 5

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

#Start OSDCloud ZTI the RIGHT way
Write-Host -ForegroundColor Green "Start OSDCloud"
#Start-OSDCloud -OSLanguage de-de -OSBuild "21H1" -OSEdition Enterprise -ZTI
Start-OSDCloud -OSLanguage en-us -OSBuild 20H2 -OSEdition Enterprise -ZTI

Write-Host -ForegroundColor Green "Create C:\Windows\Autopilot.cmd"
$AutopilotCMD = @'
PowerShell -NoL -Com Set-ExecutionPolicy RemoteSigned -Force
Set Path = %PATH%;C:\Program Files\WindowsPowerShell\Scripts
Start PowerShell -NoL -W Mi
Start /Wait PowerShell -NoL -C Install-Module AutopilotOOBE
$Computername = 'PoC-' + ((Get-CimInstance -ClassName Win32_BIOS).SerialNumber).Trim()
Start-AutopilotOOBE -Title 'EDUBS PoC Autopilot Register' -AssignedComputerName $Computername -Hidden AssignedUser -AddToGroup sg-Autopilot -Grouptag sg-Autopilot -Assign -PostAction SysprepReboot
'@

$AutopilotCMD | Out-File -FilePath 'C:\Windows\Autopilot.cmd' -Encoding ascii -Force

#Restart from WinPE
Write-Host  -ForegroundColor Green "Restarting in 20 seconds!"
Start-Sleep -Seconds 20
#wpeutil reboot
