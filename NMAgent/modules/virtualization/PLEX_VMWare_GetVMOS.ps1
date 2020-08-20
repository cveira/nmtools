##############################################################################
# Module:  PLEX_VMWare_GetVMOS
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Alberto Ruiz-Zorrilla
#          Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ PLEX_VMWare_GetVMOS = $true, $false, $true, 'System', 'PLEX_VMWare_GetVMOS', $false, @(); }


function PLEX_VMWare_GetVMOS([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  if ( $test ) {
    Write-Host -foregroundcolor $COLOR_RESULT 'Get-VMguest -VM $PipeLineInput | Select-Object OSFullName -ErrorVariable NodeErrors -ErrorAction silentlycontinue'
  } else {
    if ( !$PipelineInput ) {
      DisplayPlexHelp "<VirtualMachineName>"
      break
    }


    $OSGuest = Get-VMguest -VM $PipeLineInput | Select-Object OSFullName -ErrorVariable NodeErrors -ErrorAction silentlycontinue

    if ( $OSGuest -ne $null ) {
      $ErrorFound  = $false
      $ErrorText   = $( $NodeErrors | Format-List -force * | Out-String )
      $RawOutput   = $OSGuest.OSFullName
      $ResultValue = $RawOutput

      Write-Host -foregroundcolor $COLOR_RESULT "    + Guest OS:            "	$ResultValue
    } else {
      . ReportModuleError $OSGuest "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}