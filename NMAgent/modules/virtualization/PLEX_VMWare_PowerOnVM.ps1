##############################################################################
# Module:  PLEX_VMWare_PowerOnVM
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Alberto Ruiz-Zorrilla
#          Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ PLEX_VMWare_PowerOnVM = $true, $false, $true, 'System', 'PLEX_VMWare_PowerOnVM', $false, @(); }


function PLEX_VMWare_PowerOnVM([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  if ( $test ) {
    Write-Host -foregroundcolor $COLOR_RESULT 'Start-VM -vm $PipeLineInput -confirm:$true'
  } else {
    if ( !$PipelineInput ) {
      DisplayPlexHelp "<VirtualMachineName>"
      break
    }


    if ( !$( VMIsPoweredOn $PipeLineInput ) ) {
		  Start-VM -vm $PipeLineInput -confirm:$true

      if ( VMIsPoweredOn $PipeLineInput ) {
        $ErrorFound  = $false
        $ErrorText   = $( $NodeErrors | Format-List -force * | Out-String )
        $RawOutput   = "SUCCESS"
        $ResultValue = "SUCCESS"
      } else {
        $ErrorFound  = $false
        $ErrorText   = $( $NodeErrors | Format-List -force * | Out-String )
        $RawOutput   = "FAILURE"
        $ResultValue = "FAILURE"
      }

      Write-Host
      Write-Host -foregroundcolor $COLOR_RESULT "    + VM Start Up:         " $ResultValue
    } else {
      . ReportModuleError $PipeLineInput "ERROR: VM is already Powered On."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}