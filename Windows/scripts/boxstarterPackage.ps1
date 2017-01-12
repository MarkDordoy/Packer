Function Run-Section
{
    Param
    (
        [parameter(Mandatory=$true)]
        [string]$sectionName,

        [parameter(Mandatory=$true)]
        [scriptblock] $scriptblock,

        [parameter(Mandatory=$false)]
        [switch] $forceCompletePriorToRun
    )

    if(Test-section $sectionName)
    {
        Write-BoxstarterMessage "Section $sectionName is complete"
    }
    else 
    {
        if($forceCompletePriorToRun)
        {
            Write-BoxstarterMessage "ForceComplete triggered for $sectionName"
            Complete-Section $sectionName
        }

        Write-BoxstarterMessage "Section $sectionName is now running"
        & $scriptblock  
        Complete-Section $sectionName      
    }
}

Function Complete-Section
{
    Param
    (
        [parameter(Mandatory=$true)]
        [string]$sectionName
    )

    if(-not(test-path $Env:APPDATA\BoxstarterSection))
    {
        new-item -Type Directory -path $Env:APPDATA\BoxstarterSection
    }

    new-item -Type file -path $Env:APPData\BoxstarterSection\$sectionName -force
}

Function Test-section
{
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]$sectionName
    )

    if(test-path $Env:AppData\BoxstarterSection\$sectionName)
    {
        return $true
    }
    else 
    {
        return $false    
    }
}

Run-Section -sectionName "CompleteSetupProfileWorkaround" -forceCompletePriorToRun -scriptblock {
    invoke-reboot
}

Run-section -sectionName "EnableRDP" -scriptblock {
    Enable-RemoteDesktop -DoNotRequireUserLevelAuthentication
    Set-NetFirewallRule -Name RemoteDesktop-UserMode-In-TCP -Enabled True
}

Run-Section -sectionName "SetPSExecutionPolicy" -scriptblock {
    Update-ExecutionPolicy -policy Unrestricted
}

Run-Section -sectionName "SetupVBGuestAdditions" -forceCompletePriorToRun -scriptblock {
    certutil -addstore -f "TrustedPublisher" E:\cert\vbox-sha256.cer
    Start-Process -FilePath "E:\VBoxWindowsAdditions.exe" -ArgumentList "/S" -Wait
    invoke-reboot  
}

Run-Section -sectionName "RemoveUnusedFeatures" -scriptblock {
    Get-WindowsFeature | 
    where-object { $_.InstallState -eq 'Available' -and $_.Name -notlike "Web-*" } | 
    Uninstall-WindowsFeature -Remove
}

Run-Section -sectionName "InstallWindowsUpdates" -scriptblock {
    
    if($env:InstallUpdates)
    {
        Install-WindowsUpdate -AcceptEula    
        if(Test-PendingReboot){invoke-reboot}
    }
}   

Run-Section -sectionName "CleanSxS" -scriptblock {
    
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
}

Run-section -sectionName "PrepareSysPrep" -scriptblock {
    mkdir C:\Windows\Panther\Unattend
    Copy-Item -Path A:\postunattend.xml -Destination C:\Windows\Panther\Unattend\unattend.xml

    Write-BoxstarterMessage "Recreate agefile after sysprep"
    $System = GWMI Win32_ComputerSystem -EnableAllPrivileges
    $System.AutomaticManagedPagefile = $true
    $System.Put()    
}

Run-section -sectionName "SetupWinRM" -scriptblock {
    
    netsh advfirewall firewall add rule name="WinRM-HTTP" dir=in localport=5985 protocol=TCP action=allow
    Enable-PSRemoting -SkipNetworkProfileCheck -force
    Enable-WSManCredSSP -Force -Role Server

    #Not best practice, but allows packer to access over winrm
    winrm set winrm/config/service/auth '@{Basic="true"}'
    winrm set winrm/config/service '@{AllowUnencrypted="true"}'
    if(Test-PendingReboot){ Invoke-Reboot }
}

Write-BoxstarterMessage "Package Complete"