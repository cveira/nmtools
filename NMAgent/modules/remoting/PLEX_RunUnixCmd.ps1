##############################################################################
# Module:  PLEX_RunUnixCmd
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ PLEX_RunUnixCmd = $true, $false, $true, 'System', 'PLEX_RunUnixCmd', $false, @(); }


function PLEX_RunUnixCmd([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  $SUCCESS_EXITCODE = 0
  $SavedExitCode    = $SUCCESS_EXITCODE

  # $PuTTYOpts     = "-ssh -telnet -rlogin -raw -batch -noagent -C -i key -v {-t|-T} {-1|-2} {-4|-6} -m file -s"
  $PuTTYOpts       = "-ssh -batch -noagent -P 22 -2 -4 -C"
  $PuTTYCmd        = "`"$PipeLineInput`""
  # $PuTTYPayLoad  = "`"<PutYourRemoteCommandHere>`""
  $PuTTYPayLoad    = ""


  if ( $test ) {
    if ( $NeedCredentials ) {
      $ClearTextUserName = GetClearTextUserName $NetworkCredentials
      $ClearTextPassword = GetClearTextPassword $NetworkCredentials

      Write-Host -foregroundcolor $COLOR_RESULT "$BinDir\plink.exe -l $ClearTextUserName -pw $ClearTextPassword $PuTTYOpts $TargetNode $PuTTYCmd $PuTTYPayLoad"
    } else {
      Write-Host -foregroundcolor $COLOR_RESULT "$BinDir\plink.exe $PuTTYOpts $TargetNode $PuTTYCmd $PuTTYPayLoad"
    }
  } else {
    if ( !$PipelineInput ) {
      DisplayPlexHelp "<RemoteCommand>"
      break
    }


    if ( $NeedCredentials ) {
      $ClearTextUserName = GetClearTextUserName $NetworkCredentials
      $ClearTextPassword = GetClearTextPassword $NetworkCredentials

      $RunCmd            = "$BinDir\plink.exe -l $ClearTextUserName -pw $ClearTextPassword $PuTTYOpts $TargetNode $PuTTYCmd $PuTTYPayLoad"
      $NodeData          = Invoke-Expression $RunCmd
      $SavedExitCode     = $LASTEXITCODE
    } else {
      $RunCmd            = "$BinDir\plink.exe $PuTTYOpts $TargetNode $PuTTYCmd $PuTTYPayLoad"
      $NodeData          = Invoke-Expression $RunCmd
      $SavedExitCode     = $LASTEXITCODE
    }

    if ( $SavedExitCode -eq $SUCCESS_EXITCODE ) {
      if ( $NodeData -ne $null ) {
        $UnixCmdExitOk = "SUCCESS"
      } else {
        $UnixCmdExitOk = "SUCCESS (No Output)"
      }

      $ErrorFound      = $false
      $RawOutput       = "PayLoad: $PuTTYOpts $PuTTYCmd $PuTTYPayLoad" + "`r`n" + $( $NodeData | Out-String )
      $ResultValue     = $UnixCmdExitOk

      Write-Host
      Write-Host -foregroundcolor $COLOR_RESULT "    + UnixCmdExit:         " $UnixCmdExitOk
      Write-Host

      . SetConsoleResultTheme

      $( $NodeData | Out-String )

      . RestoreConsoleDefaultTheme
    } else {
      $UnixCmdExitOk   = "FAILURE"

      $ErrorFound  = $true
      $RawOutput   = "PayLoad: $PuTTYOpts $PuTTYCmd $PuTTYPayLoad" + "`r`n" + "ERROR: unexpected behaviour."
      $ResultValue = $UnixCmdExitOk

      Write-Host
      Write-Host -foregroundcolor $COLOR_RESULT "    + UnixCmdExit:             " $UnixCmdExitOk
      Write-Host -foregroundcolor $COLOR_ERROR  "      + ERROR: unexpected behaviour."
      Write-Host
      $NodeName >> $FailedNodesFile
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}