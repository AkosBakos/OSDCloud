$LanguageList = Get-WinUserLanguageList
$LanguageList.Add("de-CH")
Set-WinUserLanguageList $LanguageList -Force

Sleep 5

$LanguageList = Get-WinUserLanguageList
$LanguageList.Remove(($LanguageList | Where-Object LanguageTag -like 'de-DE'))
Set-WinUserLanguageList $LanguageList -Force