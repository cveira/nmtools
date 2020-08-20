##############################################################################
# Module:  PLEX_RunPsCmd
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ PLEX_RunPsCmd = $true, $false, $true, 'System', 'PLEX_RunPsCmd', $false, @(); }


function PLEX_RunPsCmd([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  $PsPayLoad = [scriptblock] { param ( $PipeLineInput ) $PipeLineInput }


  if ( $test ) {
    Write-Host -foregroundcolor $COLOR_RESULT "Invoke-Command -scriptblock $PsPayLoad -session $TargetSession -ArgumentList $PipeLineInput"
  } else {
    if ( !$PipelineInput ) {
      DisplayPlexHelp "{<RemotePsCommand>|<RemotePsScriptBlock>}"
      break
    }


    $NodeData = Invoke-Command -scriptblock $PsPayLoad -session $TargetSession -ArgumentList $PipeLineInput

    if ( $NodeData -ne $null ) {
      $CmdExit     = "SUCCESS"

      $ErrorFound  = $false
      $RawOutput   = "PsPayLoad: " + $( [string] $PsPayLoad ) + "`r`n" + $( $NodeData | Out-String )
      $ResultValue = $CmdExit

      Write-Host -foregroundcolor $COLOR_RESULT "    + CmdExit:             " $CmdExit

      . SetConsoleResultTheme

      $( $NodeData | Out-String )

      . RestoreConsoleDefaultTheme
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