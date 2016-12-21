param
(
    [Parameter()]
    [switch] $UseCoreOSWorkaround = $false
)

Function Install-CoreOSWorkaround
{
    Invoke-WebRequest -UseBasicParsing -Uri "http://7-zip.org/a/7z1604-x64.exe" -OutFile 7zip.exe
    Start-Process -FilePath ".\7Zip.exe" -ArgumentList "/S" -Wait
    $env:chocolateyUseWindowsCompression = $false
    invoke-expression ((New-Object System.net.webclient).DownloadString('https://chocolatey.org/install.ps1'))  

    Set-ItemProperty `
            -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" `
            -Name Shell -Value "PowerShell.exe -NoExit"

    $profileDir = (Split-Path -Parent $PROFILE)

    if (!(Test-Path $profileDir)) 
    {
        New-Item -Type Directory $profileDir
    }

    Copy-Item -Force A:\startup-profile.ps1 $PROFILE
}

$WinlogonPath = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"


Remove-ItemProperty -Path $WinlogonPath -Name AutoAdminLogon
Remove-ItemProperty -Path $WinlogonPath -Name DefaultUserName

invoke-expression ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/mwrock/boxstarter/master/BuildScripts/bootstrapper.ps1'))

if($UseCoreOSWorkaround)
{
    write-warning "Using Powershell profile workaround for startup items"
    Install-CoreOSWorkaround
}

Get-boxstarter -Force

#Installing package here and not within boxstarter package as it does not support the 
# --allow-empty-checksums-secure param. 
choco install sublimetext3 --allow-empty-checksums-secure -y

$secpasswd = ConvertTo-SecureString "vagrant" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("vagrant", $secpasswd)

Import-Module $env:appdata\boxstarter\boxstarter.chocolatey\boxstarter.chocolatey.psd1
Install-BoxstarterPackage -PackageName a:\boxstarterPackage.ps1 -Credential $cred