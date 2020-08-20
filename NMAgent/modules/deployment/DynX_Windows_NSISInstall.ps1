##############################################################################
# Module:  DynX_Windows_NSISInstall
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ DynX_Windows_NSISInstall = $true, $false, $false, 'System', 'DynX_Windows_NSISInstall', $false, @(); }


function DynX_Windows_NSISInstall([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  $DEFAULT_ADDRESS_WIDTH = 32


  Write-Host -foregroundcolor $COLOR_DARK "    + Loading DynX modules: "

  Get-ChildItem $ModulesDir\$CurrentProfile\DynX_Windows_NSISInstall\*.ps1 -exclude _* | ForEach-Object {
    Write-Host -foregroundcolor $COLOR_DARK -noNewLine "      + Loading: "
    Write-Host -foregroundcolor $COLOR_BRIGHT $_.Name

    . $_
  }


  if ( $PipeLineInput -ne $null ) {
    $SX_SoftwareLibrary = $PipeLineInput

    if ( ( $SX_RepositoryServer -eq $null ) -or ( $SX_SoftwareLibrary -eq $null ) ) {
      Write-Host
      . ReportModuleError "$SX_RepositoryServer - $SX_SoftwareLibrary" "ERROR: Software Repository or Store were not defined."
      $SkipCurrentNode = $true
    }
  } else {
    if ( ( $SX_RepositoryServer -eq $null ) -or ( $SX_SoftwareStore -eq $null ) -or ( $SX_SoftwareLibrary -eq $null ) ) {
      Write-Host
      . ReportModuleError "$SX_RepositoryServer - $SX_SoftwareStore - $SX_SoftwareLibrary" "ERROR: Software Repository, Store or Library were not defined."
      $SkipCurrentNode = $true
    }
  }

  if ( !$SkipCurrentNode ) {
    Write-Host
    Write-Host -foregroundcolor $COLOR_RESULT "    + Discovering SystemType..."


    if ( $NeedCredentials ) {
      $InstalledOS   = $(Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class Win32_OperatingSystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue).Caption
      $ProcessorInfo = $(Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class Win32_Processor       -ErrorVariable NodeErrors -ErrorAction silentlycontinue)
    } else {
      $InstalledOS   = $(Get-WmiObject -ComputerName $TargetNode -class Win32_OperatingSystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue).Caption
      $ProcessorInfo = $(Get-WmiObject -ComputerName $TargetNode -class Win32_Processor       -ErrorVariable NodeErrors -ErrorAction silentlycontinue)
    }
  }


  if ( ( $InstalledOS -ne $null ) -and ( $ProcessorInfo -ne $null ) -and ( !$SkipCurrentNode ) ) {
    $DetectedVersion = @{
      NotFound     = 'Unknown';
      winnt4       = 'NT 4.0';
      win2000      = '2000';
      win2003      = '2003';
      win2003x64   = '2003 x64';
      win2003r2    = '2003 R2';
      win2003r2x64 = '2003 R2 x64';
      win2008      = '2008';
      win2008x64   = '2008 x64';
      win2008r2    = '2008 R2';
      win2008r2x64 = '2008 R2 x64';
      winxp        = 'XP';
      winxpx64     = 'XP x64';
      winvista     = 'Vista';
      winvistax64  = 'Vista[\w]{0,1} x64';
      win7         = '7';
      win7x64      = '7 x64'
    }


    # This is a weird workaround/trick: in PowerShell v1.0, some times WMI Objects don't return data when invoked for the first time...
    Try {
      if ( $ProcessorInfo -is [array] ) {
        $AddressWidth = $ProcessorInfo[0].AddressWidth
      } else {
        $AddressWidth = $ProcessorInfo.AddressWidth
      }
    } -catch {
      Write-Host -foregroundcolor $COLOR_ERROR "      + Found Problems detecting CPU Type. Assuming 32 bit Processor."
      $AddressWidth   = $DEFAULT_ADDRESS_WIDTH
    }


    $IsUnknown = $true
    if ( $InstalledOS -match "(?<Name>[A-Za-z\s\(\)]+)(?<Version>(\d+\sR2|\d+)|XP|Vista)(?<Other>[\w\s\.\,]+)" ) { $IsUnknown = $false }

    $DetectedSystem = $Matches.Version.Trim()

    if ( !$IsUnknown ) {
      if ( ( $Matches.Version.Trim() -ne $DetectedVersion.winnt4  ) -and
           ( $Matches.Version.Trim() -ne $DetectedVersion.win2000 ) -and
           ( $AddressWidth -eq 64 ) ) {

        $DetectedSystem    += " x64"
      }

      Write-Host -foregroundcolor $COLOR_RESULT "      + SystemType is:     " $DetectedSystem

      $ErrorFound          = $false
      $RawOutput           = $($InstalledOS | Out-String)
      $ResultValue         = $DetectedSystem

      [string] $SystemType = ""
      $SkipHost            = $false

      switch -regex ( $DetectedSystem ) {
        $DetectedVersion.winnt4       { $SystemType = "winnt4"        }
        $DetectedVersion.win2000      { $SystemType = "win2000"       }
        $DetectedVersion.win2003      { $SystemType = "win2003"       }
        $DetectedVersion.win2003x64   { $SystemType = "win2003x64"    }
        $DetectedVersion.win2003r2    { $SystemType = "win2003r2"     }
        $DetectedVersion.win2003r2x64 { $SystemType = "win2003r2x64"  }
        $DetectedVersion.win2008      { $SystemType = "win2008"       }
        $DetectedVersion.win2008x64   { $SystemType = "win2008x64"    }
        $DetectedVersion.win2008r2    { $SystemType = "win2008r2"     }
        $DetectedVersion.win2008r2x64 { $SystemType = "win2008r2x64"  }
        $DetectedVersion.winxp        { $SystemType = "winxp"         }
        $DetectedVersion.winxpx64     { $SystemType = "winxpx64"      }
        $DetectedVersion.winvista     { $SystemType = "winvista"      }
        $DetectedVersion.winvistax64  { $SystemType = "winvistax64"   }
        $DetectedVersion.win7         { $SystemType = "win7"          }
        $DetectedVersion.win7x64      { $SystemType = "win7x64"       }
        default                       {
          $SkipHost        = $true
          Write-Host -foregroundcolor $COLOR_ERROR "      + Skipping Host: unable to match to a Supported System Type."
        }
      }

      if ( !$SkipHost ) {
        $PackagesToInstall = Get-ChildItem \\$SX_RepositoryServer\$SX_SoftwareStore\$SX_SoftwareLibrary\$SystemType\* -include *.exe -exclude _* | Sort-Object Name

        if ( $PackagesToInstall -ne $null ) {
          $PackagesToInstall | ForEach-Object {
            $CurrentPackage = $_

            Write-Host
            Write-Host -foregroundcolor $COLOR_RESULT "    + Current Package:     " $_.Name
            Write-Host

            DynX1_RunWinCmd_Windows_NSISInstalll $SetConnectToHostByIP $NodeName $NodeIP "PLEX_RunWinCmd_Microsoft_PackageInstall" $IsSupported $IsString
          }
        } else {
          Write-Host -foregroundcolor $COLOR_DARK "      + INFO: no packages to install."
        }
      }
    } else {
      Write-Host -foregroundcolor $COLOR_ERROR "    + Skipping Host: unable to match to a Supported System Type."
      Write-Host -foregroundcolor $COLOR_RESULT "      + Detected SystemType: " + $InstalledOS
    }
  } else {
    . ReportModuleError $InstalledOS "ERROR: unable to retrieve any information."
  }


  . $ModulesDir\_CloseModuleContext.ps1
}