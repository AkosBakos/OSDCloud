Write-Host -ForegroundColor Green "Installing OSDCloudLogic Module"
New-Item -Path "X:\Program Files\WindowsPowerShell\Modules\OSDCloudLogic" -ItemType Directory -Force | Out-Null
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/AkosBakos/OSDCloud/main/OSDCloudModules/Module.psm1" -OutFile "X:\Program Files\WindowsPowerShell\Modules\OSDCloudLogic\OSDCloudLogic.psm1"
Import-Module OSDCloudLogic.psm1 -Force

Write-Host -ForegroundColor Green "Starting OSDCloud for Bern devices"
OSDCloudLogic -ComputerPrefix "BE"
