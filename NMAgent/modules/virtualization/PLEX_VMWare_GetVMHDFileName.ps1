##############################################################################
# Module:  PLEX_VMWare_GetVMHDFileName
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Alberto Ruiz-Zorrilla
#          Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ PLEX_VMWare_GetVMHDFileName = $true, $false, $false, 'System', 'PLEX_VMWare_GetVMHDFileName', $false, @(); }


function PLEX_VMWare_GetVMHDFileName([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  if ( $test ) {
    Write-Host -foregroundcolor $COLOR_RESULT 'Get-HardDisk -vm "$PipeLineInput"'
  } else {
    if ( !$PipelineInput ) {
      DisplayPlexHelp "<VirtualMachineName>"
      break
    }


    $VmdkName = Get-HardDisk -vm "$PipeLineInput"

    if ( $VmdkName -ne $null ) {
      $ErrorFound  = $false
      $ErrorText   = $( $NodeErrors | Format-List -force * | Out-String )
      $RawOutput   = $( $VmdkName | Format-Table | Out-String ).Trim()
      $ResultValue = $RawOutput

      . SetConsoleResultTheme

      $ResultValue

      . RestoreConsoleDefaultTheme
    } else {
      . ReportModuleError $VmdkName "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}