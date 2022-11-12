function OSDCloudLogic {
    param (
        [Parameter(ParameterSetName = 'ComputerPrefix', Mandatory = $true)]
        [string]$ComputerPrefix
    )
    #================================================
    #   [PreOS] Update Module
    #================================================

    Write-Host -ForegroundColor Cyan "Updating OSD PowerShell Module"
    Install-Module OSD -Force

    Write-Host  -ForegroundColor Cyan "Importing OSD PowerShell Module"
    Import-Module OSD -Force   

    #=======================================================================
    #   [OS] Params and Start-OSDCloud
    #=======================================================================
    Write-Host -ForegroundColor Cyan "Set the Global Variables for a Driver Pack name --> none"
    if (((Get-MyComputerModel) -like 'Virtual*') -or ((Get-MyComputerModel) -like 'VMware*')) {
        Write-Host -ForegroundColor Cyan "Set the Global Variables for virtual machines"
        $Global:MyOSDCloud = @{
            DriverPackName = 'none'
            SkipRecoveryPartition = $true
        }
    }
    else {
        $Global:MyOSDCloud = @{
            DriverPackName = 'none'
        }
    }
    
    $Params = @{
        OSVersion = "Windows 11"
        OSBuild = "22H2"
        OSEdition = "Pro"
        OSLanguage = "de-de"
        ZTI = $true
        Firmware = $true
    }
    Start-OSDCloud @Params

    #================================================
    #  [PostOS] OOBEDeploy Configuration
    #================================================
    Write-Host -ForegroundColor Cyan "Create C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json"
    $OOBEDeployJson = @'
    {
        "Autopilot":  {
                        "IsPresent":  false
                    },
        "RemoveAppx":  [
                        "Microsoft.549981C3F5F10",
                            "Microsoft.BingWeather",
                            "Microsoft.GetHelp",
                            "Microsoft.Getstarted",
                            "Microsoft.Microsoft3DViewer",
                            "Microsoft.MicrosoftOfficeHub",
                            "Microsoft.MicrosoftSolitaireCollection",
                            "Microsoft.MixedReality.Portal",
                            "Microsoft.Office.OneNote",
                            "Microsoft.People",
                            "Microsoft.SkypeApp",
                            "Microsoft.Wallet",
                            "Microsoft.WindowsCamera",
                            "microsoft.windowscommunicationsapps",
                            "Microsoft.WindowsFeedbackHub",
                            "Microsoft.WindowsMaps",
                            "Microsoft.Xbox.TCUI",
                            "Microsoft.XboxApp",
                            "Microsoft.XboxGameOverlay",
                            "Microsoft.XboxGamingOverlay",
                            "Microsoft.XboxIdentityProvider",
                            "Microsoft.XboxSpeechToTextOverlay",
                            "Microsoft.YourPhone",
                            "Microsoft.ZuneMusic",
                            "Microsoft.ZuneVideo"
                    ],
        "UpdateDrivers":  {
                            "IsPresent":  true
                        },
        "UpdateWindows":  {
                            "IsPresent":  true
                        }
    }
'@
    If (!(Test-Path "C:\ProgramData\OSDeploy")) {
        New-Item "C:\ProgramData\OSDeploy" -ItemType Directory -Force | Out-Null
    }
    $OOBEDeployJson | Out-File -FilePath "C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json" -Encoding ascii -Force

    #================================================
    #  [PostOS] AutopilotOOBE Configuration Staging
    #================================================
    Write-Host -ForegroundColor Cyan "Create C:\ProgramData\OSDeploy\OSDeploy.AutopilotOOBE.json"
    Write-Host -ForegroundColor Gray "Define Computername"
    $Serial = Get-WmiObject Win32_bios | Select-Object -ExpandProperty SerialNumber
    $TargetComputername = $Serial.Substring(0,9)

    $AssignedComputerName = "$ComputerPrefix-AkosCloud-$TargetComputername"
    Write-Host -ForegroundColor Green $AssignedComputerName

    $AutopilotOOBEJson = @"
    {
        "Assign":  {
                        "IsPresent":  true
                    },
        "GroupTag":  "$AssignedComputerName",
        "AddToGroup": "GroupX",
        "Hidden":  [
                        "AssignedComputerName",
                        "AssignedUser",
                        "PostAction",
                        "Assign"
                    ],
        "PostAction":  "Quit",
        "Run":  "NetworkingWireless",
        "Docs":  "https://google.com/",
        "Title":  "Manual Autopilot Register"
    }
"@
    If (!(Test-Path "C:\ProgramData\OSDeploy")) {
        New-Item "C:\ProgramData\OSDeploy" -ItemType Directory -Force | Out-Null
    }
    $AutopilotOOBEJson | Out-File -FilePath "C:\ProgramData\OSDeploy\OSDeploy.AutopilotOOBE.json" -Encoding ascii -Force 
            
    #================================================
    #  [PostOS] AutopilotOOBE CMD Command Line
    #================================================
    Write-Host -ForegroundColor Cyan "Create C:\Windows\System32\OOBE.cmd"
    $OOBE = @'
PowerShell -NoL -Com Set-ExecutionPolicy RemoteSigned -Force
Set Path = %PATH%;C:\Program Files\WindowsPowerShell\Scripts
Start /Wait PowerShell -NoL -C Install-Module OSD -Force
Start /Wait PowerShell -NoL -C Install-Module AutopilotOOBE -Force
Start /Wait PowerShell -NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/AkosBakos/OSDCloud/main/Set-KeyboardLanguage.ps1
Start /Wait PowerShell -NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/AkosBakos/OSDCloud/main/Install-EmbeddedProductKey.ps1
Start /Wait PowerShell -NoL -C Invoke-WebPSScript https://check-autopilotprereq.osdcloud.ch
Start /Wait PowerShell -NoL -C Invoke-WebPSScript https://start-autopilotoobe.osdcloud.ch
Start /Wait PowerShell -NoL -C Start-OOBEDeploy
Start /Wait PowerShell -NoL -C Invoke-WebPSScript https://tpm.osdcloud.ch
Start /Wait PowerShell -NoL -C Invoke-WebPSScript https://cleanup.osdcloud.ch
Start /Wait PowerShell -NoL -C Restart-Computer -Force
'@
    $OOBE | Out-File -FilePath 'C:\Windows\System32\OOBE.cmd' -Encoding ascii -Force

    #================================================
    #  [PostOS] SetupComplete CMD Command Line
    #================================================
    Write-Host -ForegroundColor Cyan "Create C:\Windows\Setup\Scripts\SetupComplete.cmd"
    $SetupCompleteCMD = @'
'@
    $SetupCompleteCMD | Out-File -FilePath 'C:\Windows\Setup\Scripts\SetupComplete.cmd' -Encoding ascii -Width 2000 -Force

    #=======================================================================
    #  [PostOS] Params and Start-OSDCloud
    #=======================================================================
    If((Get-MyComputerManufacturer) -like "*Microsoft*")	
        {									
            Write-Host -ForegroundColor Cyan "Device manufacturer is Microsoft Corporation --> need to download some drivers"
            $Get_Product_Info = (Get-MyComputerProduct)

            Write-Host -ForegroundColor Gray "Getting OSDCloudDriverPackage for this $Get_Product_Info"
            $DriverPack = Get-OSDCloudDriverPacks | Where-Object {($_.Product -contains $Get_Product_Info) -and ($_.OS -match $Params.OSVersion)}
            
            if ($DriverPack) {
                [System.String]$DownloadPath = 'C:\Drivers'
                if (-NOT (Test-Path "$DownloadPath")) {
                    New-Item $DownloadPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
                }

                $OutFile = Join-Path $DownloadPath $DriverPack.FileName

                Write-Host -ForegroundColor Cyan "ReleaseDate: $($DriverPack.ReleaseDate)"
                Write-Host -ForegroundColor Cyan "Name: $($DriverPack.Name)"
                Write-Host -ForegroundColor Cyan "Product: $($DriverPack.Product)"
                Write-Host -ForegroundColor Cyan "Url: $($DriverPack.Url)"
                if ($DriverPack.HashMD5) {
                    Write-Host -ForegroundColor Cyan "HashMD5: $($DriverPack.HashMD5)"
                }
                Write-Host -ForegroundColor Cyan "OutFile: $OutFile"

                Save-WebFile -SourceUrl $DriverPack.Url -DestinationDirectory $DownloadPath -DestinationName $DriverPack.FileName

                if (! (Test-Path $OutFile)) {
                    Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Driver Pack failed to download"
                }

                $DriverPack | ConvertTo-Json | Out-File "$OutFile.json" -Encoding ascii -Width 2000 -Force
            }
        }

    #=======================================================================
    #   Dump some variables
    #=======================================================================
    $Global:OSDCloud | Out-File C:\OSDCloud\Logs\OSDCloud_Variables.log -Force
    $Global:OSDCloud.DriverPack | Out-File C:\OSDCloud\Logs\OSDCloud_DriverPack_Variables.log -Force

    #=======================================================================
    #   Restart-Computer
    #=======================================================================
    Write-Host  -ForegroundColor Cyan "Restarting in 20 seconds!"
    Start-Sleep -Seconds 20
    wpeutil reboot
}