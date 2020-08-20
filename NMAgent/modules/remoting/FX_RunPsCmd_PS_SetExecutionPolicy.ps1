##############################################################################
# Module:  FX_RunPsCmd_PS_SetExecutionPolicy
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ FX_RunPsCmd_PS_SetExecutionPolicy = $true, $false, $true, 'System', 'FX_RunPsCmd_PS_SetExecutionPolicy', $false, @(); }


function FX_RunPsCmd_PS_SetExecutionPolicy([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  $PsPolicy   = "RemoteSigned"
  $PsPayLoad  = [scriptblock] { param ( $PsPolicy ) Set-ExecutionPolicy $PsPolicy -force }


  function GetResult {
    $PsVerificationPayLoad  = [scriptblock] { Get-ExecutionPolicy }
    $VerificationData       = Invoke-Command -scriptblock $PsVerificationPayLoad -session $TargetSession

    $VerificationData
  }


  function ExpectedResult( [string] $CurrentResult ) {
    if ( $CurrentResult -ne $null ) {
      if ( $CurrentResult -eq $PsPolicy ) {
        $true
      } else {
        $false
      }
    } else {
      $false
    }
  }


  if ( $test ) {
    Write-Host -foregroundcolor $COLOR_RESULT "Invoke-Command -scriptblock $PsPayLoad -session $TargetSession -ArgumentList $PsPolicy"
  } else {
    $NodeData = Invoke-Command -scriptblock $PsPayLoad -session $TargetSession -ArgumentList $PsPolicy

    if ( $NodeData -eq $null ) {
      [string] $CurrentPolicy = GetResult

      if ( ExpectedResult $CurrentPolicy ) {
        $CmdExit     = "SUCCESS"

        $ErrorFound  = $false
        $RawOutput   = "PsPayLoad: " + $( [string] $PsPayLoad ) + "`r`n" + "CurrentPolicy: $CurrentPolicy"
        $ResultValue = $CmdExit

        Write-Host -foregroundcolor $COLOR_RESULT "    + CmdExit:             " $CmdExit

        . SetConsoleResultTheme

        $CurrentPolicy

        . RestoreConsoleDefaultTheme
      } else {
        $CmdExit     = "FAILURE"

        $ErrorFound    = $true
        $RawOutput     = "PsPayLoad: " + $( [string] $PsPayLoad ) + "`r`n" + "ERROR: unexpected result." + "`r`n" + "CurrentPolicy: $CurrentPolicy"
        $ResultValue   = $CmdExit

        Write-Host -foregroundcolor $COLOR_RESULT "    + CmdExit:             " $CmdExit
        Write-Host -foregroundcolor $COLOR_ERROR  "      + ERROR: unexpected result."
        $NodeName >> $FailedNodesFile

        . SetConsoleResultTheme

        $CurrentPolicy

        . RestoreConsoleDefaultTheme
      }
    } else {
      $CmdExit     = "FAILURE"

      $ErrorFound  = $true
      $RawOutput   = "PsPayLoad: " + $( [string] $PsPayLoad ) + "`r`n" + "ERROR: unexpected behaviour."
      $ResultValue = $CmdExit

      Write-Host -foregroundcolor $COLOR_RESULT "    + CmdExit:             " $CmdExit
      Write-Host -foregroundcolor $COLOR_ERROR  "      + ERROR: unexpected behaviour."
      $NodeName >> $FailedNodesFile
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}