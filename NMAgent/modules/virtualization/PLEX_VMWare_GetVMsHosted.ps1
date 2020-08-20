##############################################################################
# Module:  PLEX_VMWare_GetVMsHosted
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Alberto Ruiz-Zorrilla
#          Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ PLEX_VMWare_GetVMsHosted = $true, $false, $false, 'System', 'PLEX_VMWare_GetVMsHosted', $false, @(); }


function PLEX_VMWare_GetVMsHosted([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  if ( $test ) {
    Write-Host -foregroundcolor $COLOR_RESULT 'Get-VM  | Where-Object { $_.Host -match "$PipeLineInput" } | Sort-Object Name | Format-Table -autosize Host, Description -ErrorVariable NodeErrors -ErrorAction silentlycontinue'
  } else {
    if ( !$PipelineInput ) {
      DisplayPlexHelp "<ESXHostName>"
      break
    }


    $VMsRunning = Get-VM  | Where-Object { $_.Host -match "$PipeLineInput" } | Sort-Object Name | Format-Table -autosize Host, Name, Description -ErrorVariable NodeErrors -ErrorAction silentlycontinue

    if ( $VMsRunning -ne $null ) {
      $ErrorFound  = $false
      $ErrorText   = $( $NodeErrors | Format-List -force * | Out-String )
      $RawOutput   = $( $VMsRunning | Out-String ).Trim()
      $ResultValue = $RawOutput


      . SetConsoleResultTheme

      $ResultValue

      . RestoreConsoleDefaultTheme
    } else {
      . ReportModuleError $VMsRunning "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}