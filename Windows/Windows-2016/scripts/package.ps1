$ErrorActionPreference = "Stop"

Write-BoxstarterMessage "Removing page file"
$pageFileMemoryKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
Set-ItemProperty -Path $pageFileMemoryKey -Name PagingFiles -Value ""

try 
{
    Enable-RemoteDesktop -DoNotRequireUserLevelAuthetication -StopError 
}
catch
{
     Write-BoxstarterMessage -message "Caught failure of Enable-RemoteDesktop. $_"
}   

Set-NetFirewallRule -Name RemoteDesktop-UserMode-In-TCP -Enabled True

Update-ExecutionPolicy -Policy Unrestricted

if(-not(test-path -path 'C:\Program Files\Oracle\VirtualBox Guest Additions'))
{
    write-BoxStarterMessage "Installing virtual box additions package"
    certutil -addstore -f "TrustedPublisher" E:\cert\oracle-vbox.cer
    Start-Process -FilePath "E:\VBoxWindowsAdditions.exe" -ArgumentList "/S" -Wait
    if(Test-PendingReboot){ Invoke-Reboot }
}
else 
{
    write-BoxStarterMessage "Virtual box windows additions already installed, skipping install"
}

#Write-BoxstarterMessage "Removing unused features..."
#Get-WindowsFeature | 
#where-object { $_.InstallState -eq 'Available' -and $_.Name -notlike "Web-*" } | 
#Uninstall-WindowsFeature -Remove


#Install-WindowsUpdate -AcceptEula

Write-BoxstarterMessage "Cleaning SxS..."
Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase

@(
    "$env:localappdata\Nuget",
    "$env:localappdata\temp\*",
    "$env:windir\logs",
    "$env:windir\panther",
    "$env:windir\temp\*",
    "$env:windir\winsxs\manifestcache"
) | % {
        if(Test-Path $_) {
            Write-BoxstarterMessage "Removing $_"
            Takeown /d Y /R /f $_
            Icacls $_ /GRANT:r administrators:F /T /c /q  2>&1 | Out-Null
            Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
        }
    }

if(Test-PendingReboot){ Invoke-Reboot }

mkdir C:\Windows\Panther\Unattend
copy-item a:\postunattend.xml C:\Windows\Panther\Unattend\unattend.xml
copy-item a:\packerShutdown.bat C:\Windows\Panther\Unattend\packerShutdown.bat


Write-BoxstarterMessage "Recreate agefile after sysprep"
$System = GWMI Win32_ComputerSystem -EnableAllPrivileges
$System.AutomaticManagedPagefile = $true
$System.Put()


Write-BoxstarterMessage "Setting up winrm"
netsh advfirewall firewall add rule name="WinRM-HTTP" dir=in localport=5985 protocol=TCP action=allow

Enable-PSRemoting -SkipNetworkProfileCheck -force
Enable-WSManCredSSP -Force -Role Server

if(Test-PendingReboot){ Invoke-Reboot }

#Not best practice, but allows packer to access over winrm
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'

Write-BoxstarterMessage "winrm setup complete"

exit 0