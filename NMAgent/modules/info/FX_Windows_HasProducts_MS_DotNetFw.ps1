##############################################################################
# Module:  FX_Windows_HasProducts_MS_DotNetFw
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ FX_Windows_HasProducts_MS_DotNetFw = $true, $false, $false, 'System', 'FX_Windows_HasProducts_MS_DotNetFw', $false, @(); }


function FX_Windows_HasProducts_MS_DotNetFw([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  if ( $test ) {
    if ( $NeedCredentials ) {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class Win32_Product -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    } else {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -class Win32_Product -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    }
  } else {
    if ( $NeedCredentials ) {
      $NodeData = Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class Win32_Product -ErrorVariable NodeErrors -ErrorAction silentlycontinue
    } else {
      $NodeData = Get-WmiObject -ComputerName $TargetNode -class Win32_Product -ErrorVariable NodeErrors -ErrorAction silentlycontinue
    }

    if ( $NodeData -ne $null ) {
      $SelectedProducts = $NodeData | Where-Object { $_.Name -like "*NET Framework*" }

      if ( $SelectedProducts -ne $null ) {
        $HasProduct = "YES"
      } else {
        $HasProduct = "NO"
      }

      $ErrorFound   = $false
      $ErrorText    = $( $NodeErrors | Format-List -force * | Out-String )
      $RawOutput    = $( $SelectedProducts | Format-Table -autosize | Out-String ).Trim()
      $ResultValue  = $HasProduct

      Write-Host -foregroundcolor $COLOR_RESULT "    + HasProduct:          " $ResultValue
    } else {
      . ReportModuleError $NodeData "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}