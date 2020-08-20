##############################################################################
# Module:  FX_Windows_Shutdown
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ FX_Windows_Shutdown = $true, $false, $true, 'System', 'FX_Windows_Shutdown', $false, @(); }


function FX_Windows_Shutdown([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  $SUCCESS_EXITCODE = 0
  # $PsShutdownOpts   = "/accepteula -c [-s|-k] -f -t 0 -e P,2,4 -m `"FX_Windows_Shutdown`""
  $PsShutdownOpts   = "/accepteula -c -s -f -t 0 -m `"FX_Windows_Shutdown`""

  $TIME_TO_WAIT     = 5
  $MAX_RETRIES      = 121

  $RebootTime       = 0

  if ( $test ) {
    if ( $NeedCredentials ) {
      $ClearTextUserName = GetClearTextUserName $NetworkCredentials
      $ClearTextPassword = GetClearTextPassword $NetworkCredentials

      Write-Host -foregroundcolor $COLOR_RESULT "$BinDir\psshutdown.exe \\$TargetNode -u $ClearTextUserName -p $ClearTextPassword $PsShutdownOpts"
    } else {
      Write-Host -foregroundcolor $COLOR_RESULT "$BinDir\psshutdown.exe \\$TargetNode $PsShutdownOpts"
    }
  } else {
    Write-Host -foregroundcolor $COLOR_RESULT "    + Invoking the Shut down Request (1)"

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
      $ClearTextUserName = GetClearTextUserName $NetworkCredentials
      $ClearTextPassword = GetClearTextPassword $NetworkCredentials

      $RunCmd            = "$BinDir\psshutdown.exe \\$TargetNode -u $ClearTextUserName -p $ClearTextPassword $PsShutdownOpts"
      $NodeData          = Invoke-Expression $RunCmd
      $SavedExitCode     = $LASTEXITCODE
    } else {
      $RunCmd            = "$BinDir\psshutdown.exe \\$TargetNode $PsShutdownOpts"
      $NodeData          = Invoke-Expression $RunCmd
      $SavedExitCode     = $LASTEXITCODE
    }

    if ( $SavedExitCode -ne $SUCCESS_EXITCODE )  {
      Write-Host -foregroundcolor $COLOR_ERROR "    + Unexpected error invoking the Shut down Request (1)"

      $ErrorFound  = $true
      $RawOutput   = "Unexpected error invoking the Shut down Request at step: 1"
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
        $ShutdownTime += $i * $TIME_TO_WAIT

        $ErrorFound   = $false
        $RawOutput    = $($NodeData | Out-String)
        $ResultValue  = $ShutdownTime

        Write-Host -foregroundcolor $COLOR_RESULT "    + System has been shut down (2/$i)"
        Write-Host -foregroundcolor $COLOR_RESULT "      + Time to shut down: $ShutdownTime"

        $i            =  $MAX_RETRIES
      }
    } while ( $i -lt $MAX_RETRIES )

    if ( ( $i -eq $MAX_RETRIES ) -and ( $NodeStatus.StatusCode -eq $STATUS_NODE_ISALIVE ) ) {
      Write-Host -foregroundcolor $COLOR_ERROR "    + Time out: System shut down is still in progress (2/$i)"

      $RebootTime += $i * $TIME_TO_WAIT

      $ErrorFound  = $true
      $RawOutput   = "Time out at step: 2/$i"
      $ResultValue = $RebootTime
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}