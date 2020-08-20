##############################################################################
# Module:  DynX1_RunWinCmd_Microsoft_DotNetFwInstall
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################

function DynX1_RunWinCmd_Microsoft_DotNetFwInstall([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  $SUCCESS_EXITCODE = 0
  $SavedExitCode    = $SUCCESS_EXITCODE


  # $PsExecOpts     = "/accepteula -e -d {-f|-v} {-l|-s} -n 30 -w c:\"
  # $PsExecCmd        = "$RemoteSystemDir\cmd.exe /c"
  # $PsExecPayLoad  = "`"<PutYourRemoteCommandHere>`""

  # WARNING: when you issue the "-c" paramenter on PSEXEC, it will use that FILE as the command on the CLI.
  # That is the reason why $PsExecCmd HAS TO be empty and $PsExecPayLoad ONLY DECLARES PARAMENTERS FOR $CurrentPackage
  $PsExecCmd        = ""
  $PsExecOpts       = "/accepteula -i -c -v `"$CurrentPackage`""
  $PsExecPayLoad    = "/q:a /c:`"install.exe /q`""


  if ( $test ) {
    if ( $NeedCredentials ) {
      $ClearTextUserName = GetClearTextUserName $NetworkCredentials
      $ClearTextPassword = GetClearTextPassword $NetworkCredentials

      Write-Host -foregroundcolor $COLOR_RESULT "$BinDir\psexec.exe \\$TargetNode -u $ClearTextUserName -p $ClearTextPassword $PsExecOpts $PsExecCmd $PsExecPayLoad"
    } else {
      Write-Host -foregroundcolor $COLOR_RESULT "$BinDir\psexec.exe \\$TargetNode $PsExecOpts $PsExecCmd $PsExecPayLoad"
    }
  } else {
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
      Write-Host -foregroundcolor $COLOR_RESULT "      + CmdExitOk:         " $ResultValue
    } else {
      . ReportModuleError $NodeData "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}