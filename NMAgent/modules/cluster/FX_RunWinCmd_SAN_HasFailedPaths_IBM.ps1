##############################################################################
# Module:  FX_RunWinCmd_SAN_HasFailedPaths_IBM
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ FX_RunWinCmd_SAN_HasFailedPaths_IBM = $true, $false, $true, 'System', 'FX_RunWinCmd_SAN_HasFailedPaths_IBM', $false, @(); }


function FX_RunWinCmd_SAN_HasFailedPaths_IBM([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  $SUCCESS_EXITCODE = 0
  $SavedExitCode    = $SUCCESS_EXITCODE

  # $PsExecOpts     = "/accepteula -e -d {-f|-v} {-l|-s} -n 30 -w c:\"
  $PsExecOpts       = "/accepteula -e -w `"C:\Program Files\IBM\SDDDSM`""
  $PsExecCmd        = "$RemoteSystemDir\cmd.exe /c"
  # $PsExecPayLoad  = "`"<PutYourRemoteCommandHere>`""
  $PsExecPayLoad    = "`"datapath query adapter`""


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
        $TotalPaths  = $( $NodeData | Select-String "FAILED" | Measure-Object ).Count
        if ( $TotalPaths -eq $null ) { $TotalPaths  = 0 }
      } else {
        $TotalPaths  = 0
      }

      $ErrorFound    = $false
      $RawOutput     = $( $NodeData | Out-String )
      $ResultValue   = $TotalPaths

      Write-Host
      Write-Host -foregroundcolor $COLOR_RESULT "    + TotalPaths:          " $ResultValue
    } else {
      . ReportModuleError $NodeData "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}