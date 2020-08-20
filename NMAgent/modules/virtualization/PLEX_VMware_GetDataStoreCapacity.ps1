##############################################################################
# Module:  PLEX_VMWare_GetDataStoreCapacity
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Alberto Ruiz-Zorrilla
#          Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ PLEX_VMWare_GetDataStoreCapacity = $true, $false, $false, 'System', 'PLEX_VMWare_GetDataStoreCapacity', $false, @(); }


function PLEX_VMWare_GetDataStoreCapacity([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  if ( $test ) {
      Write-Host -foregroundcolor $COLOR_RESULT 'Get-Datastore | Where-Object { $_.Name -match "$PipeLineInput" } | Select-Object Name, FreeSpaceMB | Sort-Object FreeSpaceMB | Format-Table -autosize'
  } else {
    if ( !$PipelineInput ) {
      DisplayPlexHelp "<DataStoreName>"
      break
    }


    $DSCapacity = Get-Datastore | Where-Object { $_.Name -match "$PipeLineInput" } | Select-Object Name, FreeSpaceMB | Sort-Object FreeSpaceMB | Format-Table -autosize

    if ( $DSCapacity -ne $null ) {
      $ErrorFound  = $false
      $ErrorText   = $( $NodeErrors | Format-List -force * | Out-String )
      $RawOutput   = $( $DSCapacity | Out-String ).Trim()
      $ResultValue = $RawOutput

      . SetConsoleResultTheme

      $ResultValue

      . RestoreConsoleDefaultTheme
    } else {
      . ReportModuleError $DSCapacity "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}