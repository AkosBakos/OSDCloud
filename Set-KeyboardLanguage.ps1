Write-Host -ForegroundColor Green "Add de-CH keyboard layout"
$LanguageList = Get-WinUserLanguageList
$LanguageList.Add("de-CH")
Set-WinUserLanguageList $LanguageList -Force

Sleep 5

Write-Host -ForegroundColor Green "Remove de-DE keyboard layout"
$LanguageList = Get-WinUserLanguageList
$LanguageList.Remove(($LanguageList | Where-Object LanguageTag -like 'de-DE'))
Set-WinUserLanguageList $LanguageList -Force