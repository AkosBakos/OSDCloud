$Title = "Install EmbeddedProductKey"
$host.UI.RawUI.WindowTitle = $Title
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials

$env:APPDATA = "C:\Windows\System32\Config\SystemProfile\AppData\Roaming"
$env:LOCALAPPDATA = "C:\Windows\System32\Config\SystemProfile\AppData\Local"
$Env:PSModulePath = $env:PSModulePath + ";C:\Program Files\WindowsPowerShell\Scripts"
$env:Path = $env:Path + ";C:\Program Files\WindowsPowerShell\Scripts"

$Global:Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Install-EmbeddedProductKey.log"
Start-Transcript -Path (Join-Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" $Global:Transcript) -ErrorAction Ignore

Write-Host -ForegroundColor Green "Get embedded product key"
$Key = (Get-WmiObject SoftwareLicensingService).OA3xOriginalProductKey

If ($Key) {
    Write-Host -ForegroundColor Green "Installing embedded product key"
    Invoke-Command -ScriptBlock {& 'cscript.exe' "$env:windir\system32\slmgr.vbs" '/ipk' "$($Key)"}
    Start-Sleep -Seconds 5

    Write-Host -ForegroundColor Green "Activating embedded product key"
    Invoke-Command -ScriptBlock {& 'cscript.exe' "$env:windir\system32\slmgr.vbs" '/ato'}
    Start-Sleep -Seconds 5
}

Else {
    Write-Host -ForegroundColor Red 'No embedded product key found.'
}

Stop-Transcript