##############################################################################
# Module:  FX_VMware_GetVMWToolsStatus
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Alberto Ruiz-Zorrilla
#          Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ FX_VMware_GetVMWToolsStatus = $true, $false, $false, 'System', 'FX_VMware_GetVMWToolsStatus', $false, @(); }


function FX_VMware_GetVMWToolsStatus([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  if ( $test ) {
    Write-Host -foregroundcolor $COLOR_RESULT 'Get-VM | Sort-Object Name'
  } else {
	   $VMs = Get-VM | Sort-Object Name

    if ( $VMs -ne $null ) {
      $VMWToolsStatus  = @()

      $VMWToolsStatus += $VMs | ForEach-Object {
        $VMView        = Get-View $_.ID

        New-Object PSObject -Property @{
          ToolsStatus  = $VMView.Guest.ToolsStatus
          ToolsVersion = $VMView.Guest.ToolsVersion
          HostName     = $_.Name
        }
      }


      $ErrorFound  = $false
      $ErrorText   = $( $NodeErrors | Format-List -force * | Out-String )
      $RawOutput   = $( $VMWToolsStatus | Format-Table -autosize | Out-String ).Trim()
      $ResultValue = $RawOutput


      $OriginalColor = $host.UI.RawUI.ForegroundColor
      $host.UI.RawUI.ForegroundColor = $COLOR_RESULT

      $VMWToolsStatus | Format-Table -autosize

      $host.UI.RawUI.ForegroundColor = $OriginalColor
    } else {
      . ReportModuleError $VMs "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}