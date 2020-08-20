##############################################################################
# Module:  FX_Win2k3_SystemBoot_Has3GB
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ FX_Win2k3_SystemBoot_Has3GB = $true, $true, $true, 'System', 'FX_Win2k3_SystemBoot_Has3GB', $false, @(); }


function FX_Win2k3_SystemBoot_Has3GB([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  if ( $test ) {
    Write-Host -foregroundcolor $COLOR_RESULT "MapNetworkDrive X: \\$TargetNode\c$"
  } else {
    $LocalDrive       = FindFreeLocalDrive
    $ConnectionStatus = MapNetworkDrive $LocalDrive \\$TargetNode\c$

    if ( $ConnectionStatus -eq $OPERATION_SUCCESSFUL ) {
      $NodeData = Get-Content $LocalDrive\boot.ini

      if ( $NodeData -ne $null ) {
        $NodeData = $NodeData | Select-String "PAE|3GB"

        if ( $NodeData -ne $null ) {
          $ResultValue = "YES"
        } else {
          $ResultValue = "NO"
        }

        $ErrorFound  = $false
        $ErrorText   = $( $NodeErrors | Format-List -force * | Out-String )
        $RawOutput   = $( $NodeData | Out-String ).Trim()

        Write-Host -foregroundcolor $COLOR_RESULT "    + System Has PAE/3GB:  " $ResultValue

        $ConnectionStatus = UnMapNetworkDrive $LocalDrive

        if ( $ConnectionStatus -ne $OPERATION_SUCCESSFUL ) {
          . ReportModuleError $NodeData "ERROR: unable to un-map netowrk drive ($LocalDrive)."
        }
      } else {
        . ReportModuleError $NodeData "ERROR: unable read boot.ini file."
      }
    } else {
      . ReportModuleError $NodeData "ERROR: unable to map network drive."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}