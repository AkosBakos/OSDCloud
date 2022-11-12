Write-Host -ForegroundColor Green "Installing OSDCloudLogic Module"
New-Item -Path "X:\Program Files\WindowsPowerShell\Modules\OSDCloudLogic" -ItemType Directory -Force | Out-Null
Invoke-WebRequest -Uri "http://osdcloudlogic.complianceag.osdcloud.ch/" -OutFile "X:\Program Files\WindowsPowerShell\Modules\OSDCloudLogic\OSDCloudLogic.psm1"
Import-Module OSDCloudLogic.psm1 -Force

Write-Host -ForegroundColor Green "Starting OSDCloud for ZG-NB devices"
OSDCloudLogic -ComputerPrefix "ZG-NB"