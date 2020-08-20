##############################################################################
# Module:  PLEX_VMWare_CreateVMSnapShot
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Alberto Ruiz-Zorrilla
#          Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ PLEX_VMWare_CreateVMSnapShot = $true, $false, $true, 'System', 'PLEX_VMWare_CreateVMSnapShot', $false, @(); }


function PLEX_VMWare_CreateVMSnapShot([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  if ( $test ) {
    Write-Host -foregroundcolor $COLOR_RESULT 'New-SnapShot -Name "$LogSessionId-$PipeLineInput-SnapShot" -Description "Automatic SnapShot from PowerCLI" -vm "$PipeLineInput"'
  } else {
    if ( !$PipelineInput ) {
      DisplayPlexHelp "<VirtualMachineName>"
      break
    }


    $SnapShot = New-SnapShot -Name "$LogSessionId-$PipeLineInput-SnapShot" -Description "Automatic SnapShot from PowerCLI" -vm "$PipeLineInput"

    if ( $SnapShot -ne $null ) {
      if ( ExistSnapShot $PipeLineInput $SnapShot ) {
        $ErrorFound  = $false
        $ErrorText   = $( $NodeErrors | Format-List -force * | Out-String )
        $RawOutput   = "SnapShot: $LogSessionId-$PipeLineInput-SnapShot`r`nVirtual Machine: $PipeLineInput"
        $ResultValue = "SUCCESS"

        Write-Host -foregroundcolor $COLOR_RESULT "    + SnapShot Result:     " $ResultValue "[$LogSessionId-$PipeLineInput-SnapShot]"
      } else {
        $ErrorFound  = $true
        $ErrorText   = $( $NodeErrors | Format-List -force * | Out-String )
        $RawOutput   = "SnapShot: $LogSessionId-$PipeLineInput-SnapShot`r`nVirtual Machine: $PipeLineInput"
        $ResultValue = "FAILURE"

        Write-Host -foregroundcolor $COLOR_ERROR "    + ERROR: Couldn't take a Snapshot from $PipeLineInput."
        $NodeName >> $FailedNodesFile
      }
    } else {
      . ReportModuleError $SnapShot "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}