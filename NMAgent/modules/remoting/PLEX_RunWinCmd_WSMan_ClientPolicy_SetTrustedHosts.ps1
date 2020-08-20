##############################################################################
# Module:  PLEX_RunWinCmd_WSMan_ClientPolicy_SetTrustedHosts
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ PLEX_RunWinCmd_WSMan_ClientPolicy_SetTrustedHosts = $true, $false, $true, 'System', 'PLEX_RunWinCmd_WSMan_ClientPolicy_SetTrustedHosts', $false, @(); }


function PLEX_RunWinCmd_WSMan_ClientPolicy_SetTrustedHosts([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  $ERROR_EXITCODE   = 1
  $SavedExitCode    = 0
  $SUCCESS_EXITCODE = 0


  $PsExecCmd        = "$RemoteSystemDir\cmd.exe /c"
  $PsExecOpts       = "/accepteula -h"
  # $PsExecPayLoad  = "`"<PutYourRemoteCommandHere>`""
  $PsExecPayLoad  = "`"winrm.cmd set winrm/config/client @{TrustedHosts=#$PipelineInput#}`"" -replace '#', '`"'


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
      DisplayPlexHelp "<NodeName1, NodeName2, [...]>"
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

    if ( $SavedExitCode -ne $ERROR_EXITCODE ) {
      if ( $SavedExitCode -eq $SUCCESS_EXITCODE ) {
        $CmdExit     = "SUCCESS"

        $ErrorFound  = $false
        $RawOutput   = "PayLoad: $PsExecOpts $PsExecCmd $PsExecPayLoad" + "`r`n" + $( $NodeData | Out-String )
        $ResultValue = $CmdExit

        Write-Host
        Write-Host -foregroundcolor $COLOR_RESULT "    + CmdExit:             " $CmdExit
        Write-Host
      } else {
        $CmdExit     = "FAILURE"

        $ErrorFound  = $true
        $RawOutput   = "PayLoad: $PsExecOpts $PsExecCmd $PsExecPayLoad" + "`r`n" + "ERROR: unexpected result."
        $ResultValue = $CmdExit

        Write-Host
        Write-Host -foregroundcolor $COLOR_RESULT "    + CmdExit:             " $CmdExit
        Write-Host -foregroundcolor $COLOR_ERROR  "      + ERROR: unexpected result."
        Write-Host
        $NodeName >> $FailedNodesFile
      }
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


    . SetConsoleResultTheme

    $( $NodeData | Out-String )

    . RestoreConsoleDefaultTheme


    . $ModulesDir\_CloseModuleContext.ps1
  }
}