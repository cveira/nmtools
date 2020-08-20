##############################################################################
# Module:  PLEX_VMWare_GetVMsHostName
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Alberto Ruiz-Zorrilla
#          Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ PLEX_VMWare_GetVMsHostName = $true, $false, $true, 'System', 'PLEX_VMWare_GetVMsHostName', $false, @(); }


function PLEX_VMWare_GetVMsHostName([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  if ( $test ) {
    Write-Host -foregroundcolor $COLOR_RESULT 'Get-VM  | Where-Object { $_.Name -match "$PipeLineInput" }'
  } else {
    if ( !$PipelineInput ) {
      DisplayPlexHelp "<VirtualMachineName>"
      break
    }


	  $VM = $( Get-VM  | Where-Object { $_.Name -match "$PipeLineInput" } )

    if ( $VM -ne $null ) {
      $ErrorFound  = $false
      $ErrorText   = $( $NodeErrors | Format-List -force * | Out-String )
      $RawOutput   = $( $VM | Format-List | Out-String ).Trim()
      $ResultValue = $VM.Host

      Write-Host -foregroundcolor $COLOR_RESULT "    + ESX HostName :       " $ResultValue
    } else {
      . ReportModuleError $VM "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}