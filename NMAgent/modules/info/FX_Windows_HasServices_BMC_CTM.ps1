##############################################################################
# Module:  FX_Windows_HasServices_BMC_CTM
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ FX_Windows_HasServices_BMC_CTM = $true, $false, $false, 'System', 'FX_Windows_HasServices_BMC_CTM', $false, @(); }


function FX_Windows_HasServices_BMC_CTM([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  if ( $test ) {
    if ( $NeedCredentials ) {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class win32_service -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    } else {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -class win32_service -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    }
  } else {
    if ( $NeedCredentials ) {
      $NodeData = Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class win32_service -ErrorVariable NodeErrors -ErrorAction silentlycontinue
    } else {
      $NodeData = Get-WmiObject -ComputerName $TargetNode -class win32_service -ErrorVariable NodeErrors -ErrorAction silentlycontinue
    }

    if ( $NodeData -ne $null ) {
      $SelectedServices = $NodeData | Where-Object { $_.Name -like "ctm*" }

      if ( $SelectedServices -ne $null ) {
        $HasService = "YES"
      } else {
        $HasService = "NO"
      }

      $ErrorFound   = $false
      $ErrorText    = $( $NodeErrors | Format-List -force * | Out-String )
      $RawOutput    = $( $SelectedServices | Format-Table -autosize | Out-String ).Trim()
      $ResultValue  = $HasService

      Write-Host -foregroundcolor $COLOR_RESULT "    + HasService:          " $ResultValue
    } else {
      . ReportModuleError $NodeData "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}