[int] $ToKB                = 1024
[int] $ToGB                = 1048576
[int] $ToGhz               = 1024
[char] $Quotes             = [char] 34

$OPERATION_SUCCESSFUL      = 0
$SUCCESS_EXITCODE          = 0

$ERROR_NULL_DATA           = -1

$ERROR_DRIVE_NOTFOUND      = 0
$ERROR_MAPPING_DRIVE       = 1
$ERROR_UNMAPPING_DRIVE     = 2
$ERROR_ITEM_NOTFOUND       = 3

$ERROR_UNKNOWN_SYSTEMTYPE  = 1
$ERROR_MATCHING_SYSTEMTYPE = 2


##############################################################################

function GetSystemDir() {
 $DefaultSystemDir = "C:\WINDOWS\system32"

 if ( $NeedCredentials ) {
   $RemoteSystemDir = $(Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class win32_operatingsystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue).SystemDirectory
 } else {
   $RemoteSystemDir = $(Get-WmiObject -ComputerName $TargetNode -class win32_operatingsystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue).SystemDirectory
 }

 if ( $RemoteSystemRoot -eq $null ) {
   $RemoteSystemDir = $DefaultSystemDir
 }

 $RemoteSystemDir
}

##############################################################################

function GetSystemRoot() {
 $DefaultSystemRoot = "C:\WINDOWS"

 if ( $NeedCredentials ) {
   $RemoteSystemRoot = $(Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class win32_operatingsystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue).WindowsDirectory
 } else {
   $RemoteSystemRoot = $(Get-WmiObject -ComputerName $TargetNode -class win32_operatingsystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue).WindowsDirectory
 }

 if ( $RemoteSystemRoot -eq $null ) {
   $RemoteSystemRoot = $DefaultSystemRoot
 }

 $RemoteSystemRoot
}

##############################################################################

function IsASuccessfulExitCode([int] $ExitCode) {
  $SUCCESS                = 0
  $SUCCESS_REBOOTREQUIRED = 3010

  $IsSuccessful = $false

  if ( $ExitCode -eq $SUCCESS_EXITCODE       ) { $IsSuccessful = $true }
  if ( $ExitCode -eq $SUCCESS_REBOOTREQUIRED ) { $IsSuccessful = $true }

  $IsSuccessful
}

##############################################################################

function StorageIsEMC() {
  $IsEMC = $false

  if ( $NeedCredentials ) {
    $DiskInfo = Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class win32_diskdrive -ErrorVariable NodeErrors -ErrorAction silentlycontinue
  } else {
    $DiskInfo = Get-WmiObject -ComputerName $TargetNode -class win32_diskdrive -ErrorVariable NodeErrors -ErrorAction silentlycontinue
  }

  if ( $DiskInfo -ne $null ) {
    if ( $DiskInfo.gettype().Name -eq "ManagementObject" ) {
      if ( $DiskInfo.Model -match "PowerPath" ) {
        $true
      } else {
        $false
      }
    } else {
      for ($i=0; $i -lt $DiskInfo.Length; $i++) {
        if ( $DiskInfo[$i].Model -match "PowerPath" ) {
          $IsEMC = $true
          break
        } else {
          $IsEMC = $false
        }
      }
    }
  }

  $IsEMC
}

##############################################################################

function GetRemoteSystemType() {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentGetRemoteSystemTypeErrorEvent = @"

===========================================================================================
$(get-date -format u) - GetRemoteSystemType Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())

"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "      + GetRemoteSystemType Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentGetRemoteSystemTypeErrorEvent >> $ErrorLogFile

    continue
  }


  $NMAgentGetRemoteSystemTypeErrorEventHeader = @"

===========================================================================================
$(get-date -format u) - LoadModulesTable Error Event
-------------------------------------------------------------------------------------------

"@

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

  $DEFAULT_ADDRESS_WIDTH = 32
  $SystemType            = $UNKNOWN_ITEM
  $IsUnknown             = $true


  if ( $NeedCredentials ) {
    $InstalledOS   = $(Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class Win32_OperatingSystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue).Caption
    $ProcessorInfo = $(Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class Win32_Processor       -ErrorVariable NodeErrors -ErrorAction silentlycontinue)
  } else {
    $InstalledOS   = $(Get-WmiObject -ComputerName $TargetNode -class Win32_OperatingSystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue).Caption
    $ProcessorInfo = $(Get-WmiObject -ComputerName $TargetNode -class Win32_Processor       -ErrorVariable NodeErrors -ErrorAction silentlycontinue)
  }


  if ( ( $InstalledOS -ne $null ) -and ( $ProcessorInfo -ne $null ) ) {
    # This is a weird workaround/trick: in PowerShell v1.0, some times WMI Objects don't return data when invoked for the first time...
    #
    # Try {
    #   if ( $ProcessorInfo -is [array] ) {
    #     $AddressWidth = $ProcessorInfo[0].AddressWidth
    #   } else {
    #     $AddressWidth = $ProcessorInfo.AddressWidth
    #   }
    # } -catch {
    #   $NMAgentGetRemoteSystemTypeErrorEventHeader                        >> $ErrorLogFile
    #   "+ Found Problems detecting CPU Type. Assuming 32 bit Processor."  >> $ErrorLogFile
    #   $AddressWidth   = $DEFAULT_ADDRESS_WIDTH
    # }

    Try {
      if ( $ProcessorInfo -is [array] ) {
        $AddressWidth = $ProcessorInfo[0].AddressWidth
      } else {
        $AddressWidth = $ProcessorInfo.AddressWidth
      }
    } Catch {
      $NMAgentGetRemoteSystemTypeErrorEventHeader                        >> $ErrorLogFile
      "+ Found Problems detecting CPU Type. Assuming 32 bit Processor."  >> $ErrorLogFile
      $AddressWidth   = $DEFAULT_ADDRESS_WIDTH
    }


    if ( $InstalledOS -match "(?<Name>[A-Za-z\s\(\)]+)(?<Version>(\d+\sR2|\d+)|XP|Vista)(?<Other>[\w\s\.\,]+)" ) { $IsUnknown  = $false }
    $DetectedSystem   = $Matches.Version.Trim()


    if ( !$IsUnknown ) {
      if ( ( $Matches.Version.Trim() -ne $DetectedVersion.winnt4  ) -and
           ( $Matches.Version.Trim() -ne $DetectedVersion.win2000 ) -and
           ( $AddressWidth -eq 64 ) ) {

        $DetectedSystem += " x64"
      }

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
          $NMAgentGetRemoteSystemTypeErrorEventHeader             >> $ErrorLogFile
          "+ ERROR: Unable to match to a Supported System Type."  >> $ErrorLogFile

          return $ERROR_MATCHING_SYSTEMTYPE
        }
      }

      return $SystemType
    } else {
      $NMAgentGetRemoteSystemTypeErrorEventHeader                 >> $ErrorLogFile
      "+ ERROR: Unable to match to a Supported System Type."      >> $ErrorLogFile
      "  + Detected SystemType: " + $InstalledOS                  >> $ErrorLogFile

      return $ERROR_UNKNOWN_SYSTEMTYPE
    }
  } else {
    $NMAgentGetRemoteSystemTypeErrorEventHeader                   >> $ErrorLogFile
    "+ ERROR: Unable to retrieve any information."                >> $ErrorLogFile
    $NodeName                                                     >> $FailedNodesFile

    return $ERROR_NULL_DATA
  }
}

##############################################################################

function GetFileSetSize( $FileSet ) {
  $TotalSize = 0

  if ( $FileSet -ne $null ) {
      $FileSet | ForEach-Object { $TotalSize += $_.Length }
  }

  return $TotalSize
}

##############################################################################

function FindFreeLocalDrive() {
  $EXCLUDED_DRIVES = 'A:', 'B:', 'C:', 'D:', 'E:', 'H:', 'Z:'

  $DriveLetters    = 65..89 | ForEach-Object { ([char]$_)+":" } | Where-Object { $EXCLUDED_DRIVES -notcontains $_ }

  return @( $DriveLetters | Where-Object { $( New-Object System.IO.DriveInfo $_ ).DriveType -eq 'NoRootdirectory' } )[0]
}

##############################################################################

function MapNetworkDrive( [string] $DriveLetter, [string] $RemoteResource ) {
  $net = New-Object -ComObject WScript.Network

  if ( $NeedCredentials ) {
    $ClearTextUserName = $NetworkCredentials.UserName.ToString()
    $TargetPtr         = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($NetworkCredentials.Password)
    $ClearTextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($TargetPtr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR( $TargetPtr )

    $net.MapNetworkDrive( $DriveLetter, $RemoteResource, "false", $ClearTextUserName, $ClearTextPassword )
  } else {
    $net.MapNetworkDrive( $DriveLetter, $RemoteResource, "false" )
  }

  if ( $( New-Object System.IO.DriveInfo $DriveLetter ).DriveType -eq 'Network' ) {
    return $OPERATION_SUCCESSFUL
  } else {
    return $ERROR_MAPPING_DRIVE
  }
}

##############################################################################

function UnMapNetworkDrive( [string] $DriveLetter, [bool] $force = $false ) {
  $net = New-Object -ComObject WScript.Network

  if ( $force ) {
    $net.RemoveNetworkDrive( $DriveLetter, "true", "true" )
  } else {
    $net.RemoveNetworkDrive( $DriveLetter )
  }

  if ( ( $( New-Object System.IO.DriveInfo $DriveLetter ).DriveType -eq 'NoRootdirectory' ) -or
       ( $( New-Object System.IO.DriveInfo $DriveLetter ).DriveType -eq $null ) ) {
    return $OPERATION_SUCCESSFUL
  } else {
    return $ERROR_UNMAPPING_DRIVE
  }
}

##############################################################################

function GetTargetFreeSpace( [string] $RemoteResource ) {
  $LastElementId = $RemoteResource.Split("\").Length - 1
  $RemoteDrive   = $( $RemoteResource.Split("\")[$LastElementId] -replace "\$", ":" ).ToUpper()

  if ( $NeedCredentials ) {
    $NodeData = Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class Win32_LogicalDisk -filter "drivetype=3" -ErrorVariable NodeErrors -ErrorAction silentlycontinue | Select-Object DeviceID, FreeSpace, Size
  } else {
    $NodeData = Get-WmiObject -ComputerName $TargetNode -class Win32_LogicalDisk -filter "drivetype=3" -ErrorVariable NodeErrors -ErrorAction silentlycontinue | Select-Object DeviceID, FreeSpace, Size
  }

  if ( $NodeData -ne $null ) {
    $TargetDrive = $NodeData | Where-Object { $_.DeviceID -eq $RemoteDrive }
    if ( $TargetDrive -ne $null ) {
      return $TargetDrive.FreeSpace
    } else {
      return $ERROR_DRIVE_NOTFOUND
    }
  } else {
    return $ERROR_NULL_DATA
  }
}

##############################################################################

function UploadFilesToCIFS( $FileSet, [string] $RemoteResource ) {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentUploadFilesToCIFSErrorEvent = @"

===========================================================================================
$(get-date -format u) - UploadFilesToCIFS Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())

"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "      + UploadFilesToCIFS Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentUploadFilesToCIFSErrorEvent >> $ErrorLogFile

    continue
  }


  $LocalDrive         = FindFreeLocalDrive
  $ConnectionStatus   = MapNetworkDrive $LocalDrive $RemoteResource

  if ( $ConnectionStatus -eq $OPERATION_SUCCESSFUL ) {
    if ( !$( Test-Path $LocalDrive\NMAWorkArea\$AgentUserName\$LogSessionId ) ) { New-Item -type directory -path $LocalDrive\NMAWorkArea\$AgentUserName -name $LogSessionId }

    $FileSet | ForEach-Object { Copy-Item $_.FullName $LocalDrive\NMAWorkArea\$AgentUserName\$LogSessionId }

    $ConnectionStatus = UnMapNetworkDrive $LocalDrive

    if ( $ConnectionStatus -eq $OPERATION_SUCCESSFUL ) {
      return $OPERATION_SUCCESSFUL
    } else {
      return $ERROR_UNMAPPING_DRIVE
    }
  } else {
    return $ERROR_MAPPING_DRIVE
  }
}

##############################################################################

function CleanRemoteCIFSWorkArea( $FileSet, [string] $RemoteResource ) {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentCleanRemoteCIFSWorkAreaErrorEvent = @"

===========================================================================================
$(get-date -format u) - CleanRemoteCIFSWorkArea Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())

"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "      + CleanRemoteCIFSWorkArea Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentCleanRemoteCIFSWorkAreaErrorEvent >> $ErrorLogFile

    continue
  }


  $LocalDrive         = FindFreeLocalDrive
  $ConnectionStatus   = MapNetworkDrive $LocalDrive $RemoteResource

  if ( $ConnectionStatus -eq $OPERATION_SUCCESSFUL ) {
    if ( Test-Path $LocalDrive\NMAWorkArea\$AgentUserName\$LogSessionId ) {
      $FileSet | ForEach-Object { Remove-Item -path "$LocalDrive\NMAWorkArea\$AgentUserName\$LogSessionId\$($_.Name)" -force }
      if ( $( Get-ChildItem * -recurse $LocalDrive\NMAWorkArea\$AgentUserName\$LogSessionId ) -eq $null ) { Remove-Item $LocalDrive\NMAWorkArea\$AgentUserName\$LogSessionId }

      $ConnectionStatus = UnMapNetworkDrive $LocalDrive

      if ( $ConnectionStatus -eq $OPERATION_SUCCESSFUL ) {
        return $OPERATION_SUCCESSFUL
      } else {
        return $ERROR_UNMAPPING_DRIVE
      }
    } else {
      return $ERROR_ITEM_NOTFOUND
    }
  } else {
    return $ERROR_MAPPING_DRIVE
  }
}

##############################################################################

function GetClearTextUserName( [System.Management.Automation.PSCredential] $Credentials ) {
  $Credentials.UserName.ToString()
}

##############################################################################

function GetClearTextPassword( [System.Management.Automation.PSCredential] $Credentials ) {
  $TargetPtr         = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credentials.Password)
  $ClearTextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($TargetPtr)
  [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR( $TargetPtr )

  $ClearTextPassword
}

##############################################################################

function DisplayPlexHelp( [string] $PlexParameters ) {
  Write-Host -foregroundcolor $COLOR_ERROR "    + ERROR: Incorrect PLEX Syntax"
  Write-Host -foregroundcolor $COLOR_ERROR "      + PLEX Syntax: `"$PlexParameters`" | NMAgent <session-parameters>"
  Write-Host
}

##############################################################################

function SetConsoleResultTheme( [string] $PlexParameters ) {
  Write-Host
  $OriginalColor = $host.UI.RawUI.ForegroundColor
  $host.UI.RawUI.ForegroundColor = $COLOR_RESULT
}

##############################################################################

function RestoreConsoleDefaultTheme( [string] $PlexParameters ) {
  Write-Host
  $host.UI.RawUI.ForegroundColor = $OriginalColor
}

##############################################################################

function ReportModuleError( $ErrorOutput, [string] $ErrorMessage, [string] $ErrorValue = "N/A" ) {
  if ( $ErrorOutput -ne $null ) {
    if ( $ErrorOutput -is [string] ) {
      $RawOutput = $( $ErrorOutput | Out-String ).Trim()
    } else {
      $RawOutput = $( $ErrorOutput | Format-List * -force | Out-String ).Trim()
    }
  } else {
    $RawOutput = "Unavailable"
  }

  $ErrorFound  = $true
  $ErrorText   = $ErrorMessage
  $ResultValue = $ErrorValue

  Write-Host -foregroundcolor $COLOR_ERROR "    +" $ErrorMessage
  $NodeName >> $FailedNodesFile
}