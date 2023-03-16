
function Fiddler-Cleanup {

C:\Users\Administrator.PFELABS\AppData\Local\Programs\Fiddler\uninst.exe /S
Get-childitem cert:\CurrentUser\root |where-object {$_.Subject -match "CN=Do_NOT_TRUST"} |remove-item -force

}

function Get-fiddler {

invoke-webrequest 'https://github.com/microsoft/Exo-TroubleshootingWorkshop/raw/main/FiddlerSetup.exe' -Outfile 'c:\temp\Fiddler.exe'

}




function Install-fiddler {

c:\temp\fiddler.exe /S /D=c:\Program Files\Fiddler

}




Function Create-fiddlerLink {

$SourceFilePath = "C:\Program Files\Fiddler\Fiddler.exe"
$ShortcutPath = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Fiddler.lnk"
$WScriptObj = New-Object -ComObject ("WScript.Shell")
$shortcut = $WscriptObj.CreateShortcut($ShortcutPath)
$shortcut.TargetPath = $SourceFilePath
$shortcut.Save()

}

Fiddler-Cleanup
get-fiddler
install-fiddler
create-fiddlerlink

