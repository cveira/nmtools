##############################################################################
# Module:  FX_OpenSLIM_Windows_GetSupplier
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ SupplierId = $true, $true, $true, 'System', 'FX_OpenSLIM_Windows_GetSupplier', $false, @(); }


function FX_OpenSLIM_Windows_GetSupplier([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  if ( $test ) {
    if ( $NeedCredentials ) {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class Win32_ComputerSystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    } else {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -class Win32_ComputerSystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    }
  } else {
    if ( $NeedCredentials ) {
      $Manufacturer = $(Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class Win32_ComputerSystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue).Manufacturer
    } else {
      $Manufacturer = $(Get-WmiObject -ComputerName $TargetNode -class Win32_ComputerSystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue).Manufacturer
    }

    if ( $Manufacturer -ne $null ) {
      # SupplierId	SupplierName
      # 1	          Unknown
      # 3	          Sun
      # 4	          IBM
      # 5	          HP
      # 7	          Dell

      $SupplierId	  = 0
      $SupplierName = 1

      $Supplier = @{
        NotFound = 1, 'Unknown';
        Sun      = 3, 'Sun';
        IBM      = 4, 'IBM';
        HP       = 5, 'HP';
        Dell     = 7, 'Dell'
      }

      $IsUnknown = $true
      switch -case ($Manufacturer) {
        'Sun'   { $IsUnknown = $false }
        'IBM'   { $IsUnknown = $false }
        'HP'    { $IsUnknown = $false }
        'Dell'  { $IsUnknown = $false }
        default { $IsUnknown = $true  }
      }

      if ( $IsUnknown ) {
        $ResultId          = $Supplier.NotFound[$SupplierId]
        $ResultDescription = $Supplier.NotFound[$SupplierName]
      } else {
        $ResultId          = $Supplier.$("$Manufacturer")[$SupplierId]
        $ResultDescription = $Supplier.$("$Manufacturer")[$SupplierName]
      }

      $ErrorFound  = $false
      $ErrorText   = $( $NodeErrors | Format-List -force * | Out-String )
      $RawOutput   = "$Manufacturer"
      $ResultValue = "$ResultId"

      Write-Host -foregroundcolor $COLOR_RESULT "    + Supplier:            " $ResultDescription " [" $ResultId "]"
    } else {
      . ReportModuleError $Manufacturer "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}