param
(
    [parameter()]
    [switch] $UseCoreOSWorkaround = $false
)

if($UseCoreOSWorkaround)
{
    Write-Warning "Cleaning up PowerShell profile workaround for startup items"

    Remove-ItemProperty `
            -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" `
            -Name Shell
    Remove-Item -Force $PROFILE
}

Remove-Item -Force -recurse -path $Env:AppData\BoxstarterSection

Set-Item -Path WSMan:\localhost\Service\AllowUnencrypted -Value false
Set-Item -Path WSMan:\localhost\Service\Auth\Basic       -Value false
netsh advfirewall firewall set rule name="WinRM-HTTP" new action=block

Start-Process -FilePath "C:\windows\system32\sysprep\sysprep.exe" -ArgumentList "/generalize /oobe /unattend:C:/Windows/Panther/Unattend/unattend.xml /quiet /shutdown"

   
