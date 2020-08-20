##############################################################################
# Module:  FX_RunWinCmd_PS_EnableRemoting
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Héctor Gil Mozos
#          Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ FX_RunWinCmd_PS_EnableRemoting = $true, $false, $true, 'System', 'FX_RunWinCmd_PS_EnableRemoting', $false, @(); }


function FX_RunWinCmd_PS_EnableRemoting([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  $ERROR_EXITCODE   = -1
  $SavedExitCode    = 0

  # $PsExecCmd        = "$RemoteSystemDir\cmd.exe /c"
  $PsExecCmd        = "powershell.exe -command { Enable-PSRemoting -force }"
  $PsExecOpts       = "/accepteula -h -d"
  # $PsExecPayLoad  = "`"<PutYourRemoteCommandHere>`""
  # $PsExecPayLoad    = ""


  function ExpectedResult {
    if ( $NeedCredentials ) {
      $NodeData = $(Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class Win32_Service -ErrorVariable NodeErrors -ErrorAction silentlycontinue)
    } else {
      $NodeData = $(Get-WmiObject -ComputerName $TargetNode -class Win32_Service -ErrorVariable NodeErrors -ErrorAction silentlycontinue)
    }

    if ( $NodeData -ne $null ) {
      if ( ( $( $NodeData | Where-Object { $_.Name -eq 'WinRM' } ).StartMode -eq 'Auto' ) -and ( $( $NodeData | Where-Object { $_.Name -eq 'WinRM' } ).State -eq 'Running' ) ) {
        $true
      } else {
        $false
      }
    } else {
      $false
    }
  }


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

    if ( $SavedExitCode -ne $ERROR_EXITCODE ) {
      if ( ExpectedResult ) {
        $CmdExit     = "SUCCESS"

        $ErrorFound  = $false
        $RawOutput   = "PayLoad: $PsExecOpts $PsExecCmd $PsExecPayLoad"
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


    . $ModulesDir\_CloseModuleContext.ps1
  }
}