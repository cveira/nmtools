##############################################################################
# Module:  FX_Windows_GetMonitoring_HasAll
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ FX_Windows_GetMonitoring_HasAll = $true, $false, $true, 'System', 'FX_Windows_GetMonitoring_HasAll', $false, @(); }


function FX_Windows_GetMonitoring_HasAll([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
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
      $SelectedServices = $NodeData | Where-Object {
        (
          ($_.Name -eq "HP ITO Agent") -or
          ($_.Name -eq "DSIService") -or
          ($_.Name -eq "MIService") -or
          ($_.Name -eq "MWAService") -or
          ($_.Name -eq "MWECService") -or
          ($_.Name -eq "ScopeService") -or
          ($_.Name -eq "TTService") -or
          ($_.Name -eq "OmniVision") -or
          ($_.Name -eq "KNTCMA_Primary") -or
          ($_.Name -eq "WVASvc")
        ) -and ($_.State -eq "Running")
      }

      if ( $SelectedServices -ne $null ) {
        $MonitoringIsOperational = "YES"
      } else {
        $MonitoringIsOperational = "NO"
      }

      $ErrorFound  = $false
      $ErrorText   = $( $NodeErrors | Format-List -force * | Out-String )
      $RawOutput   = $( $SelectedServices | Format-Table -autosize | Out-String ).Trim()
      $ResultValue = $MonitoringIsOperational

      Write-Host -foregroundcolor $COLOR_RESULT "    + HasAll:              " $ResultValue
    } else {
      . ReportModuleError $NodeData "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}