##############################################################################
# Module:  DynX1_RunWinCmd_DSGridServer_WinAgentInstall
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos de la Fuente -
#          Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################

function DynX1_RunWinCmd_DSGridServer_WinAgentInstall([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  $SUCCESS_EXITCODE = 0
  $SavedExitCode    = $SUCCESS_EXITCODE

  # $PsExecOpts     = "/accepteula -e -d {-f|-v} {-l|-s} -n 30 -w c:\"
  # $PsExecOpts       = "/accepteula -e"
  $PsExecCmd        = "$RemoteSystemDir\cmd.exe /c"
  # $PsExecPayLoad  = "`"<PutYourRemoteCommandHere>`""

  $PsExecPayLoad    = "`"\\$PipeLineInput\network\setup.exe -s -f1\\$PipeLineInput\network\$UIScriptFile -f2c:\datasynapse.log`""

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
      Write-Host -foregroundcolor $COLOR_ERROR "    + ERROR: Incorrect PLEX Syntax"
      Write-Host -foregroundcolor $COLOR_ERROR '      + PLEX Syntax: "<ServerFQDN>" | NMAgent <session-parameters>'
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
        $CmdExitOk = "YES"
      } else {
        $CmdExitOk = "YES (No output)"
      }

      $ErrorFound  = $false
      $RawOutput   = $( $NodeData | Out-String )
      $ResultValue = $CmdExitOk

      Write-Host
      Write-Host -foregroundcolor $COLOR_RESULT "    + CmdExitOk:           " $ResultValue
    } else {
      . ReportModuleError $NodeData "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}