<#
.SYNOPSIS
    OSDCloud Logic for PreOS, OS and PostOS Tasks
.DESCRIPTION
    This script is used to perform PreOS, OS and PostOS tasks for OSDCloud.
    It includes the following tasks:
    - Update OSD PowerShell Module
    - Import OSD PowerShell Module
    - Install and configure firmware updates
    - Define Autopilot attributes
    - Setup Unattend.xml for specialize phase
    - Execute OOBE and cleanup scripts
    - Move OSDCloud logs to IntuneManagementExtension
    - Restart the system if not in development mode

.NOTES
    Version:		0.1
    Creation Date:  23.04.2025
    Author:			Akos Bakos
    Company:        SmartCon GmbH
    Contact:		akos.bakos@smartcon.ch

    Copyright (c) 2025 SmartCon GmbH

HISTORY:
Date			By			Comments
----------		---			----------------------------------------------------------
23.04.2025		Akos Bakos	Script created

#>

if (-NOT (Test-Path 'X:\OSDCloud\Logs')) {
    New-Item -Path 'X:\OSDCloud\Logs' -ItemType Directory -Force -ErrorAction Stop | Out-Null
}

#Transport Layer Security (TLS) 1.2
Write-Host -ForegroundColor Green "Transport Layer Security (TLS) 1.2"
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
#[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials

$Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Start-OSDCloudLogic.log"
Start-Transcript -Path (Join-Path "X:\OSDCloud\Logs" $Transcript) -ErrorAction Ignore | Out-Null

#================================================
Write-Host -ForegroundColor DarkGray "========================================================================="
Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) " -NoNewline
Write-Host -ForegroundColor Cyan "[PreOS] Update Module"
#================================================
# Write-Host -ForegroundColor Green "Updating OSD PowerShell Module"
# Install-Module OSD -Force

Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) " -NoNewline
Write-Host -ForegroundColor Green "Importing OSD PowerShell Module"
Import-Module OSD -Force

Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) " -NoNewline
Write-Host -ForegroundColor Green "PSCloudScript at functions.osdcloud.com"
Invoke-Expression (Invoke-RestMethod -Uri functions.osdcloud.com)

#region Helper Functions
function Write-DarkGrayDate {
    [CmdletBinding()]
    param (
        [Parameter(Position=0)]
        [System.String]
        $Message
    )
    if ($Message) {
        Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) $Message"
    }
    else {
        Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) " -NoNewline
    }
}
function Write-DarkGrayHost {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [System.String]
        $Message
    )
    Write-Host -ForegroundColor DarkGray $Message
}
function Write-DarkGrayLine {
    [CmdletBinding()]
    param ()
    Write-Host -ForegroundColor DarkGray "========================================================================="
}
function Write-SectionHeader {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [System.String]
        $Message
    )
    Write-DarkGrayLine
    Write-DarkGrayDate
    Write-Host -ForegroundColor Cyan $Message
}
function Write-SectionSuccess {
    [CmdletBinding()]
    param (
        [Parameter(Position=0)]
        [System.String]
        $Message = 'Success!'
    )
    Write-DarkGrayDate
    Write-Host -ForegroundColor Green $Message
}
#endregion

#region PreOS Tasks
#=======================================================================
Write-SectionHeader "[PreOS] Define OSDCloud Global And Customer Parameters"
#=======================================================================
$Global:WPNinjaCH   = $null
$Global:WPNinjaCH   = [ordered]@{
    Development     = [bool]$false
    TestGroup       = [bool]$false
}
Write-SectionHeader "WPNinjaCH variables"
Write-Host ($Global:WPNinjaCH | Out-String)

$Global:MyOSDCloud = [ordered]@{
    MSCatalogFirmware   = [bool]$true
    HPBIOSUpdate        = [bool]$true
    #IsOnBattery        = [bool]$false
}
Write-SectionHeader "MyOSDCloud variables"
Write-Host ($Global:MyOSDCloud | Out-String)

if ($Global:OSDCloud.ApplyCatalogFirmware -eq $true) {
    #=======================================================================
    Write-SectionHeader "[PreOS] Prepare Firmware Tasks"
    #=======================================================================
    #Register-PSRepository -Default -Verbose
    osdcloud-TrustPSGallery -Verbose
    #Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -Verbose

    osdcloud-InstallPowerShellModule -Name 'MSCatalog'
    #Install-Module -Name MSCatalog -Force -Verbose -SkipPublisherCheck -AllowClobber -Repository PSGallery    
}

#endregion

#region OS Tasks
#=======================================================================
Write-SectionHeader "[OS] Params and Start-OSDCloud"
#=======================================================================
$Params = @{
    OSVersion   = "Windows 11"
    OSBuild     = "24H2"
    OSEdition   = "Pro"
    OSLanguage  = "en-us"
    OSLicense   = "Retail"
    ZTI         = $true
    Firmware    = $true
}
Write-Host ($Params | Out-String)
Start-OSDCloud @Params
#endregion

#region Autopilot Tasks
#================================================
Write-SectionHeader "[PostOS] Define Autopilot Attributes"
#================================================
Write-DarkGrayHost "Define Computername"
$Serial = Get-WmiObject Win32_bios | Select-Object -ExpandProperty SerialNumber
$lastFourChars = $serial.Substring($serial.Length - 4)
#$AssignedComputerName = "NB-2$lastFourChars"

$ChassisType = (Get-WmiObject -Query "SELECT * FROM Win32_SystemEnclosure").ChassisTypes
$HyperV = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem WHERE Manufacturer LIKE '%Microsoft Corporation%' AND Model LIKE '%Virtual Machine%'"
$VMware = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem WHERE Manufacturer LIKE '%VMware%' AND Model LIKE '%VMware%'"

If ($HyperV -or $VMware) {
    $HW         = "VM"
}

If ($ChassisType -eq "8" -or`
    $ChassisType -eq "9" -or`
    $ChassisType -eq "10" -or`
    $ChassisType -eq "11" -or`
    $ChassisType -eq "12" -or`
    $ChassisType -eq "14" -or`
    $ChassisType -eq "18" -or`
    $ChassisType -eq "21" -or`
    $ChassisType -eq "31") {
    $HW = "NB"
}

elseif ($ChassisType -eq "3" -or`
    $ChassisType -eq "4" -or`
    $ChassisType -eq "5" -or`
    $ChassisType -eq "6" -or`
    $ChassisType -eq "7" -or`
    $ChassisType -eq "15" -or`
    $ChassisType -eq "16" -or`
    $ChassisType -eq "35") {
    $HW = "PC"
}

If (!($HW)) {
    $AssignedComputerName = "RENAME_ME$Serial"
}
else {
    $AssignedComputerName = "$HW-2$lastFourChars"        
}

# Device assignment
if ($Global:WPNinjaCH.TestGroup -eq $true){
    Write-DarkGrayHost "Adding device to AZ_COM_TEST Group"
    $AddToGroup = "AZ_COM_TST"
}
else {
    Write-DarkGrayHost "Adding device to AZ_COM_PRD Group"
    $AddToGroup = "AZ_COM_PRD"
}

Write-Host -ForegroundColor Yellow "Computername: $AssignedComputerName"
Write-Host -ForegroundColor Yellow "AddToGroup: $AddToGroup"

#================================================
Write-SectionHeader "[PostOS] AutopilotOOBE Configuration"
#================================================
Write-DarkGrayHost "Create C:\ProgramData\OSDeploy\OSDeploy.AutopilotOOBE.json file"
$AutopilotOOBEJson = @"
{
        "AssignedComputerName" : "$AssignedComputerName",
        "AddToGroup":  "$AddToGroup",
        "Assign":  {
                    "IsPresent":  true
                },
        "GroupTag":  "$GroupTag",
        "Hidden":  [
                    "AddToGroup",
                    "AssignedUser",
                    "PostAction",
                    "GroupTag",
                    "Assign"
                ],
        "PostAction":  "Quit",
        "Run":  "NetworkingWireless",
        "Docs":  "https://google.com/",
        "Title":  "Autopilot Manual Register"
    }
"@

If (!(Test-Path "C:\ProgramData\OSDeploy")) {
    New-Item "C:\ProgramData\OSDeploy" -ItemType Directory -Force | Out-Null
}
$AutopilotOOBEJson | Out-File -FilePath "C:\ProgramData\OSDeploy\OSDeploy.AutopilotOOBE.json" -Encoding ascii -Force
#endregion

#region Specialize Tasks
#================================================
Write-SectionHeader "[PostOS] SetupComplete CMD Command Line"
#================================================
Write-DarkGrayHost "Cleanup SetupComplete Files from OSDCloud Module"
Get-ChildItem -Path 'C:\Windows\Setup\Scripts\SetupComplete*' -Recurse | Remove-Item -Force

#=================================================
Write-SectionHeader "[PostOS] Define Specialize Phase"
#=================================================
$UnattendXml = @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="specialize">
        <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <RunSynchronous>
                <RunSynchronousCommand wcm:action="add">
                    <Order>1</Order>
                    <Description>Start Autopilot Import & Assignment Process</Description>
                    <Path>PowerShell -ExecutionPolicy Bypass C:\Windows\Setup\scripts\autopilot.ps1</Path>
                </RunSynchronousCommand>
            </RunSynchronous>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <InputLocale>de-CH</InputLocale>
            <SystemLocale>de-DE</SystemLocale>
            <UILanguage>de-DE</UILanguage>
            <UserLocale>de-CH</UserLocale>
        </component>
    </settings>
</unattend>
'@ 
# Get-OSDGather -Property IsWinPE
Block-WinOS

if (-NOT (Test-Path 'C:\Windows\Panther')) {
    New-Item -Path 'C:\Windows\Panther'-ItemType Directory -Force -ErrorAction Stop | Out-Null
}

$Panther = 'C:\Windows\Panther'
$UnattendPath = "$Panther\Unattend.xml"
$UnattendXml | Out-File -FilePath $UnattendPath -Encoding utf8 -Width 2000 -Force

Write-DarkGrayHost "Use-WindowsUnattend -Path 'C:\' -UnattendPath $UnattendPath"
Use-WindowsUnattend -Path 'C:\' -UnattendPath $UnattendPath | Out-Null
#endregion

#region OOBE Tasks
#================================================
Write-SectionHeader "[PostOS] OOBE CMD Command Line"
#================================================
Write-DarkGrayHost "Downloading Scripts for OOBE and specialize phase"

#Invoke-RestMethod http://autopilot.osdcloud.ch | Out-File -FilePath 'C:\Windows\Setup\scripts\autopilot.ps1' -Encoding ascii -Force
Invoke-RestMethod http://oobe.osdcloud.ch | Out-File -FilePath 'C:\Windows\Setup\scripts\oobe.ps1' -Encoding ascii -Force
Invoke-RestMethod http://cleanup.osdcloud.ch | Out-File -FilePath 'C:\Windows\Setup\scripts\cleanup.ps1' -Encoding ascii -Force
#Invoke-RestMethod http://osdgather.osdcloud.ch | Out-File -FilePath 'C:\Windows\Setup\scripts\osdgather.ps1' -Encoding ascii -Force

$OOBEcmdTasks = @'
@echo off

REM Wait for Network 10 seconds
REM ping 127.0.0.1 -n 10 -w 1  >NUL 2>&1

REM Execute OOBE Tasks
start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F C:\Windows\Setup\Scripts\oobe.ps1

REM Execute OSD Gather Script
REM start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F C:\Windows\Setup\Scripts\osdgather.ps1

REM Execute Cleanup Script
start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F C:\Windows\Setup\Scripts\cleanup.ps1

REM Below a PS session for debug and testing in system context, # when not needed 
REM start /wait powershell.exe -NoL -ExecutionPolicy Bypass

exit 
'@
$OOBEcmdTasks | Out-File -FilePath 'C:\Windows\Setup\scripts\oobe.cmd' -Encoding ascii -Force

Write-DarkGrayHost "Copying PFX file"
Copy-Item X:\OSDCloud\Config\Scripts C:\OSDCloud\ -Recurse -Force
#endregion

Write-DarkGrayHost "Disabling Shift F10 in OOBE for security Reasons"
$Tagpath = "C:\Windows\Setup\Scripts\DisableCMDRequest.TAG"
New-Item -ItemType file -Force -Path $Tagpath | Out-Null
Write-DarkGrayHost "Shift F10 disabled now!"

#region Development
if ($Global:WPNinjaCH.Development -eq $true){
    #================================================
    Write-SectionHeader "[WINPE] DEVELOPMENT - Activate some debugging features"
    #================================================
    Write-DarkGrayHost "Enabling Shift+F10 in OOBE for security Reasons"
    $Tagpath = "C:\Windows\Setup\Scripts\DisableCMDRequest.TAG"
    Remove-Item -Force -Path $Tagpath | Out-Null
    Write-DarkGrayHost "Shift F10 enabled now!"

    Write-DarkGrayHost "Disable Cursor Suppression"
    #cmd.exe /c reg load HKLM\Offline c:\windows\system32\config\software & cmd.exe /c REG ADD "HKLM\Offline\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableCursorSuppression /t REG_DWORD /d 0 /f & cmd.exe /c reg unload HKLM\Offline
    Invoke-Exe cmd.exe -Arguments "/c reg load HKLM\Offline c:\windows\system32\config\software" | Out-Null
    New-ItemProperty -Path HKLM:\Offline\Microsoft\Windows\CurrentVersion\Policies\System -Name EnableCursorSuppression -Value 0 -Force | Out-Null
    #Invoke-Exe cmd.exe -Arguments "/c REG ADD 'HKLM\Offline\Microsoft\Windows\CurrentVersion\Policies\System' /v EnableCursorSuppression /t REG_DWORD /d 0 /f "
    Invoke-Exe cmd.exe -Arguments "/c reg unload HKLM\Offline" | Out-Null
}
#endregion

#=======================================================================	
Write-SectionHeader "Moving OSDCloud Logs to IntuneManagementExtension\Logs\OSD"	
#=======================================================================	
if (-NOT (Test-Path 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD')) {	
    New-Item -Path 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD' -ItemType Directory -Force -ErrorAction Stop | Out-Null	
}	
Get-ChildItem -Path X:\OSDCloud\Logs\ | Copy-Item -Destination 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD' -Force

if ($Global:WPNinjaCH.Development -eq $false){
    Write-DarkGrayHost "Restarting in 20 seconds!"
    Start-Sleep -Seconds 20

    wpeutil reboot

    Stop-Transcript | Out-Null
}
else {
    Write-DarkGrayHost "Development Mode - No reboot!"
    Stop-Transcript | Out-Null
}