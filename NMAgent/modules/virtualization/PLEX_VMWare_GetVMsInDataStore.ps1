##############################################################################
# Module:  PLEX_VMWare_GetVMsInDataStore
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Alberto Ruiz-Zorrilla
#          Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ PLEX_VMWare_GetVMsInDataStore = $true, $false, $false, 'System', 'PLEX_VMWare_GetVMsInDataStore', $false, @(); }


function PLEX_VMWare_GetVMsInDataStore([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  if ( $test ) {
    Write-Host -foregroundcolor $COLOR_RESULT 'Get-VM | Where-Object { $_.HardDisks[0].FileName -like '*' + "$PipeLineInput" + '*' } | Select-Object Name, Description | Sort-Object Name | Format-Table -autosize'
  } else {
    if ( !$PipelineInput ) {
      DisplayPlexHelp "<DataStoreName>"
      break
    }


    $VMsInDataStore = Get-VM | Where-Object { $_.HardDisks[0].FileName -like '*' + "$PipeLineInput" + '*' } | Select-Object Name, Description | Sort-Object Name | Format-Table -autosize

    if ( $VMsInDataStore -ne $Null ) {
      $ErrorFound  = $false
      $ErrorText   = $( $NodeErrors | Format-List -force * | Out-String )
      $RawOutput   = $( $VMsInDataStore | Out-String ).Trim()
      $ResultValue = $RawOutput

      . SetConsoleResultTheme

      $ResultValue

      . RestoreConsoleDefaultTheme
    } else {
      . ReportModuleError $VMsInDataStore "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}