##############################################################################
# Module:  FX_Windows_Reboot
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ FX_Windows_Reboot = $true, $false, $true, 'System', 'FX_Windows_Reboot', $false, @(); }


function FX_Windows_Reboot([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  $SUCCESS_EXITCODE = 0
  # $PsShutdownOpts   = "/accepteula -c -r -f -t 0 -e P,2,4 -m `"FX_Windows_Reboot`""
  $PsShutdownOpts   = "/accepteula -c -r -f -t 0 -m `"FX_Windows_Reboot`""


  $TIME_TO_WAIT     = 5
  $MAX_RETRIES      = 121

  $RebootTime       = 0

  if ( $test ) {
    if ( $NeedCredentials ) {
      $TargetPtr         = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($NetworkCredentials.Password)
      $ClearTextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($TargetPtr)
      $ClearTextUserName = $NetworkCredentials.UserName.ToString()

      Write-Host -foregroundcolor $COLOR_RESULT "$BinDir\psshutdown.exe \\$TargetNode -u $ClearTextUserName -p $ClearTextPassword $PsShutdownOpts"
    } else {
      Write-Host -foregroundcolor $COLOR_RESULT "$BinDir\psshutdown.exe \\$TargetNode $PsShutdownOpts"
    }
  } else {
    Write-Host -foregroundcolor $COLOR_RESULT "    + Invoking the Reboot Request (1)"

    # NOTE: the following procedure doesn't seem to work reliably on every scenario. We will retry when migrating to PowerShell v2.0
    #
    # if ( $NeedCredentials ) {
    #   $RemoteOS = Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class Win32_OperatingSystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue
    #   $RemoteOS.psbase.Scope.Options.EnablePrivileges = $true
    #   $RemoteOS.Reboot()
    # } else {
    #   $RemoteOS = Get-WmiObject -ComputerName $TargetNode -class Win32_OperatingSystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue
    #   $RemoteOS.psbase.Scope.Options.EnablePrivileges = $true
    #   $RemoteOS.Reboot()
    # }

    if ( $NeedCredentials ) {
      $TargetPtr         = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($NetworkCredentials.Password)
      $ClearTextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($TargetPtr)
      $ClearTextUserName = $NetworkCredentials.UserName.ToString()

      $RunCmd            = "$BinDir\psshutdown.exe \\$TargetNode -u $ClearTextUserName -p $ClearTextPassword $PsShutdownOpts"
      $NodeData          = Invoke-Expression $RunCmd
      $SavedExitCode     = $LASTEXITCODE
    } else {
      $RunCmd            = "$BinDir\psshutdown.exe \\$TargetNode $PsShutdownOpts"
      $NodeData          = Invoke-Expression $RunCmd
      $SavedExitCode     = $LASTEXITCODE
    }

    if ( $SavedExitCode -ne $SUCCESS_EXITCODE )  {
      Write-Host -foregroundcolor $COLOR_ERROR "    + Unexpected error invoking the Reboot Request (1)"

      $ErrorFound  = $true
      $RawOutput   = "Unexpected error invoking the Reboot Request at step: 1"
      $ResultValue = $RebootTime

      . $ModulesDir\_CloseModuleContext.ps1

      break
    }


    Write-Host -foregroundcolor $COLOR_RESULT "    + Shutting down System (2)"

    $i = 1
    do {
      Start-Sleep -seconds $TIME_TO_WAIT

      $NodeStatus = $(Get-WmiObject -Class Win32_PingStatus -Filter "Address='$TargetNode'"   | Select-Object -Property Address, ResponseTime, StatusCode)

      if ( $NodeStatus.StatusCode -eq $STATUS_NODE_ISALIVE ) {
        Write-Host -foregroundcolor $COLOR_RESULT "    + System shut down in progress (2/$i)"
        $i++
      } else {
        Write-Host -foregroundcolor $COLOR_RESULT "    + System has been shut down (2/$i)"
        $RebootTime += $i * $TIME_TO_WAIT
        $i          =  $MAX_RETRIES
      }
    } while ( $i -lt $MAX_RETRIES )

    if ( ( $i -eq $MAX_RETRIES ) -and ( $NodeStatus.StatusCode -eq $STATUS_NODE_ISALIVE ) ) {
      Write-Host -foregroundcolor $COLOR_ERROR "    + Time out: System shut down is still in progress (2/$i)"

      $RebootTime += $i * $TIME_TO_WAIT

      $ErrorFound  = $true
      $RawOutput   = "Time out at step: 2/$i"
      $ResultValue = $RebootTime

      . $ModulesDir\_CloseModuleContext.ps1

      break
    }


    Write-Host -foregroundcolor $COLOR_RESULT "    + Waiting for System boot (3)"

    $i = 1
    do {
      Start-Sleep -seconds $TIME_TO_WAIT

      $NodeStatus = $(Get-WmiObject -Class Win32_PingStatus -Filter "Address='$TargetNode'"   | Select-Object -Property Address, ResponseTime, StatusCode)

      if ( $NodeStatus.StatusCode -ne $STATUS_NODE_ISALIVE ) {
        Write-Host -foregroundcolor $COLOR_RESULT "    + Waiting for System boot (3/$i)"
        $i++
      } else {
        Write-Host -foregroundcolor $COLOR_RESULT "    + System is booting up (4)"
        $RebootTime += $i * $TIME_TO_WAIT
        $i          =  $MAX_RETRIES
      }
    } while ( $i -lt $MAX_RETRIES )

    if ( ( $i -eq $MAX_RETRIES ) -and ( $NodeStatus.StatusCode -ne $STATUS_NODE_ISALIVE ) ) {
      Write-Host -foregroundcolor $COLOR_ERROR "    + Time out: still waiting for System boot (3/$i)"

      $RebootTime += $i * $TIME_TO_WAIT

      $ErrorFound  = $true
      $RawOutput   = "Time out at step: 3/$i"
      $ResultValue = $RebootTime

      . $ModulesDir\_CloseModuleContext.ps1

      break
    }


    $i = 1
    do {
      Start-Sleep -seconds $TIME_TO_WAIT

      if ( $NeedCredentials ) {
        $NodeData = Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class Win32_OperatingSystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue
      } else {
        $NodeData = Get-WmiObject -ComputerName $TargetNode -class Win32_OperatingSystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue
      }

      if ( $NodeData -eq $null ) {
        Write-Host -foregroundcolor $COLOR_RESULT "    + System is booting up (4/$i)"
        $i++
      } else {
        $RebootTime += $i * $TIME_TO_WAIT

        $ErrorFound  = $false
        $RawOutput   = $($NodeData | Out-String)
        $ResultValue = $RebootTime

        Write-Host -foregroundcolor $COLOR_RESULT "    + System on-line (5)"
        Write-Host -foregroundcolor $COLOR_RESULT "      + Time to reboot: $RebootTime"

        $i = $MAX_RETRIES
      }
    } while ( $i -lt $MAX_RETRIES )

    if ( ( $i -eq $MAX_RETRIES ) -and ( $NodeData -eq $null ) ) {
      Write-Host -foregroundcolor $COLOR_ERROR "    + Time out: System is still booting up (4/$i)"

      $RebootTime += $i * $TIME_TO_WAIT

      $ErrorFound  = $true
      $RawOutput   = "Time out at step: 4/$i"
      $ResultValue = $RebootTime
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}