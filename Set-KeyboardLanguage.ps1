Start-Transcript -Path %TEMP%\Set-KeyboardLanguage.txt
Write-Host -ForegroundColor Green "Set keyboard language for de-CH"

$LanguageList = Get-WinUserLanguageList
Write-Host -ForegroundColor Green "Keyboard list before change"
Write-Host $LanguageList

$LanguageList.Add("de-CH")
Set-WinUserLanguageList $LanguageList -Force

Start-Sleep -Seconds 5

$LanguageList = Get-WinUserLanguageList
$LanguageList.Remove(($LanguageList | Where-Object LanguageTag -like 'de-DE'))
Set-WinUserLanguageList $LanguageList -Force

$LanguageList = Get-WinUserLanguageList
Write-Host -ForegroundColor Green "Keyboard list after change"
Write-Host $LanguageList

Stop-Transcript