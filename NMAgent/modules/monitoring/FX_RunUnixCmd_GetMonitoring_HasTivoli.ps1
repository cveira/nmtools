##############################################################################
# Module:  FX_RunUnixCmd_GetMonitoring_HasTivoli
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ FX_RunUnixCmd_GetMonitoring_HasTivoli = $true, $false, $true, 'System', 'FX_RunUnixCmd_GetMonitoring_HasTivoli', $false, @(); }


function FX_RunUnixCmd_GetMonitoring_HasTivoli([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  $SUCCESS_EXITCODE = 0
  $SavedExitCode    = $SUCCESS_EXITCODE

  # $PuTTYOpts     = "-ssh -telnet -rlogin -raw -batch -noagent -C -i key -v {-t|-T} {-1|-2} {-4|-6} -m file -s"
  $PuTTYOpts       = "-ssh -batch -noagent -P 22 -2 -4 -C"
  $PuTTYCmd        = "`"ps -ef | grep kux`""
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
        $UnixCmdExitOk   = "YES"
      } else {
        $UnixCmdExitOk   = "NO"
      }

      $ErrorFound        = $false
      $RawOutput         = $( $NodeData | Out-String )
      $ResultValue       = $UnixCmdExitOk

      Write-Host
      Write-Host -foregroundcolor $COLOR_RESULT "    + HasTivoli:           " $ResultValue
    } else {
      . ReportModuleError $NodeData "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}