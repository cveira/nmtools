##############################################################################
# Module:  PLEX_RunWinCmd
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ PLEX_RunWinCmd = $true, $false, $true, 'System', 'PLEX_RunWinCmd', $false, @(); }


function PLEX_RunWinCmd([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  $SUCCESS_EXITCODE = 0
  $SavedExitCode    = $SUCCESS_EXITCODE

  # $PsExecOpts     = "/accepteula -e -d {-f|-v} {-l|-s} -n 30 -w c:\"
  $PsExecOpts       = "/accepteula -e -h"
  $PsExecCmd        = "$RemoteSystemDir\cmd.exe /c"
  # $PsExecPayLoad  = "`"<PutYourRemoteCommandHere>`""
  $PsExecPayLoad    = "`"$PipeLineInput`""


  if ( $test ) {
    if ( $NeedCredentials ) {
      $ClearTextUserName = GetClearTextUserName $NetworkCredentials
      $ClearTextPassword = GetClearTextPassword $NetworkCredentials

      Write-Host -foregroundcolor $COLOR_RESULT "$BinDir\psexec.exe \\$TargetNode -u $ClearTextUserName -p $ClearTextPassword $PsExecOpts $PsExecCmd $PsExecPayLoad"
    } else {
      Write-Host -foregroundcolor $COLOR_RESULT "$BinDir\psexec.exe \\$TargetNode $PsExecOpts $PsExecCmd $PsExecPayLoad"
    }
  } else {
    if ( !$PipelineInput ) {
      DisplayPlexHelp "<RemoteCommand>"
      break
    }


    if ( $NeedCredentials ) {
      $ClearTextUserName = GetClearTextUserName $NetworkCredentials
      $ClearTextPassword = GetClearTextPassword $NetworkCredentials

      $RunCmd            = "$BinDir\psexec.exe \\$TargetNode -u $ClearTextUserName -p $ClearTextPassword $PsExecOpts $PsExecCmd $PsExecPayLoad"
      $NodeData          = Invoke-Expression $RunCmd
      $SavedExitCode     = $LASTEXITCODE
    } else {
      $RunCmd            = "$BinDir\psexec.exe \\$TargetNode $PsExecOpts $PsExecCmd $PsExecPayLoad"
      $NodeData          = Invoke-Expression $RunCmd
      $SavedExitCode     = $LASTEXITCODE
    }

    if ( $SavedExitCode -eq $SUCCESS_EXITCODE ) {
      if ( $NodeData -ne $null ) {
        $CmdExit     = "SUCCESS"
      } else {
        $CmdExit     = "SUCCESS (No Output)"
      }

      $ErrorFound  = $false
      $RawOutput   = "PayLoad: $PsExecOpts $PsExecCmd $PsExecPayLoad" + "`r`n" + $( $NodeData | Out-String )
      $ResultValue = $CmdExit

      Write-Host
      Write-Host -foregroundcolor $COLOR_RESULT "    + CmdExit:             " $CmdExit
      Write-Host

      . SetConsoleResultTheme

      $ResultValue

      . RestoreConsoleDefaultTheme
    } else {
      $CmdExit     = "FAILURE"

      $ErrorFound  = $true
      $RawOutput   = "PayLoad: $PsExecOpts $PsExecCmd $PsExecPayLoad" + "`r`n" + "ERROR: unexpected behaviour."
      $ResultValue = $CmdExit

      Write-Host
      Write-Host -foregroundcolor $COLOR_RESULT "    + CmdExit:             " $CmdExit
      Write-Host -foregroundcolor $COLOR_ERROR  "      + ERROR: unexpected behaviour."
      Write-Host
      $NodeName >> $FailedNodesFile
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}