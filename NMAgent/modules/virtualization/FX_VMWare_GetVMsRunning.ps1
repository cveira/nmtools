##############################################################################
# Module:  FX_VMware_GetRunningVM
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Alberto Ruiz-Zorrilla
#          Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ FX_VMWare_GetVMsRunning = $true, $false, $true, 'System', 'FX_VMWare_GetVMsRunning', $false, @(); }


function FX_VMWare_GetVMsRunning([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  if ( $test ) {
    Write-Host -foregroundcolor $COLOR_RESULT 'Get-VM | Where-Object {$_.PowerState -like "*On"} | Select-Object Name | Sort-Object Name -ErrorVariable NodeErrors -ErrorAction silentlycontinue'
  } else {

    $VMRunning = Get-VM | Where-Object {$_.PowerState -like "*On"} | Select-Object Name | Sort-Object Name -ErrorVariable NodeErrors -ErrorAction silentlycontinue

    if ( $VMRunning -ne $null ) {
      $ErrorFound  = $false
      $ErrorText   = $( $NodeErrors | Format-List -force * | Out-String ).Trim()
      $RawOutput   = $( $VMRunning | Format-Table -autosize | Out-String ).Trim()
      $ResultValue = $RawOutput


      $OriginalColor = $host.UI.RawUI.ForegroundColor
      $host.UI.RawUI.ForegroundColor = $COLOR_RESULT

      $VMRunning | Format-Table -autosize

      $host.UI.RawUI.ForegroundColor = $OriginalColor
    } else {
      . ReportModuleError $VMRunning "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}