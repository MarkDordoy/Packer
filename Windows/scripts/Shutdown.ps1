param
(
    [Parameter()]
    [switch] $UseCoreOSWorkaround = $false
)

if($UseCoreOSWorkaround)
{
    Write-Warning "Cleaning up PowerShell profile workaround for startup items"

    if(Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon')
    {
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name Shell
    }

    if(Test-Path $PROFILE)
    {
        Remove-Item -Force $PROFILE
    }
}


if(Test-Path $Env:AppData\BoxstarterSection)
{
    Remove-Item -Force -recurse -path $Env:AppData\BoxstarterSection
}

try
{
    Set-Item -Path WSMan:\localhost\Service\AllowUnencrypted -Value false
    Set-Item -Path WSMan:\localhost\Service\Auth\Basic       -Value false
    netsh advfirewall firewall set rule name="WinRM-HTTP" new action=block
}
catch
{
#Do nothing
}
finally
{
    Start-Process -FilePath "C:\windows\system32\sysprep\sysprep.exe" -ArgumentList "/generalize /oobe /unattend:C:\Windows\Panther\Unattend\unattend.xml /shutdown" -Wait
}