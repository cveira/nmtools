##############################################################################
# Module:  FX_OpenSLIM_Windows_GetMaxSpeedPerCore
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ MaxSpeedPerCore = $true, $true, $true, 'System', 'FX_OpenSLIM_Windows_GetMaxSpeedPerCore', $false, @(); }


function FX_OpenSLIM_Windows_GetMaxSpeedPerCore([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  if ( $test ) {
    if ( $NeedCredentials ) {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class Win32_Processor -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    } else {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -class Win32_Processor -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    }
  } else {
    if ( $NeedCredentials ) {
      $NodeData = $(Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class Win32_Processor -ErrorVariable NodeErrors -ErrorAction silentlycontinue)
    } else {
      $NodeData = $(Get-WmiObject -ComputerName $TargetNode -class Win32_Processor -ErrorVariable NodeErrors -ErrorAction silentlycontinue)
    }

    if ( $NodeData -ne $null ) {
      if ( $NodeData.gettype().Name -eq "ManagementObject" ) {
        $MaxClockSpeed = $NodeData.MaxClockSpeed
      } else {
        $MaxClockSpeed = $NodeData[0].MaxClockSpeed
      }

      $ErrorFound  = $false
      $ErrorText   = $( $NodeErrors | Format-List -force * | Out-String )
      $RawOutput   = "$MaxClockSpeed"
      $ResultValue = "$( [math]::Round($($MaxClockSpeed / $ToGhz),2) )"

      Write-Host -foregroundcolor $COLOR_RESULT "    + MaxClockSpeed:       " $ResultValue
    } else {
      . ReportModuleError $NodeData "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}