##############################################################################
# Module:  FX_OpenSLIM_Windows_GetClusterType
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ ClusterTypeId = $true, $true, $true, 'System', 'FX_OpenSLIM_Windows_GetClusterType', $false, @(); }


function FX_OpenSLIM_Windows_GetClusterType([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  if ( $test ) {
    if ( $NeedCredentials ) {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class Win32_Service -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    } else {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -class Win32_Service -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    }
  } else {
    if ( $NeedCredentials ) {
      $NodeData = Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class Win32_Service -ErrorVariable NodeErrors -ErrorAction silentlycontinue
    } else {
      $NodeData = Get-WmiObject -ComputerName $TargetNode -class Win32_Service -ErrorVariable NodeErrors -ErrorAction silentlycontinue
    }

    if ( $NodeData -ne $null ) {
      # ClusterTypeId	ClusterTypeName
      # 2  	          N/A
      # 3	            MS Cluster
      # 4	            MS NLB
      # 5	            Veritas Cluster

      $ClusterTypeId	 = 0
      $ClusterTypeName = 1

      $ClusterType = @{
        NotFound   = 2,  'N/A';
        ClusSvc    = 3,  'MS Cluster'
      }

      $ClusterNotFound = $false

      if ( $($NodeData | Where-Object { $_.Name -eq 'ClusSvc' }).Name -ne $null ) {
        $ResultId          = $ClusterType.$($($NodeData | where { $_.Name -eq 'ClusSvc' }).Name)[$ClusterTypeId]
        $ResultDescription = $ClusterType.$($($NodeData | where { $_.Name -eq 'ClusSvc' }).Name)[$ClusterTypeName]
      } else {
        $ClusterNotFound   = $true
      }

      if ( $ClusterNotFound ) {
        $ResultId          = $ClusterType.NotFound[$ClusterTypeId]
        $ResultDescription = $ClusterType.NotFound[$ClusterTypeName]
      }

      $ErrorFound  = $false
      $ErrorText   = $( $NodeErrors | Format-List -force * | Out-String )
      $RawOutput   = "$ResultId - $ResultDescription"
      $ResultValue = "$ResultId"

      Write-Host -foregroundcolor $COLOR_RESULT "    + ClusterType:         " $ResultDescription " [" $ResultId "]"
    } else {
      . ReportModuleError $NodeData "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}
