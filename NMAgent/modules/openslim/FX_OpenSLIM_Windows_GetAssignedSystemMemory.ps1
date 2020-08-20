##############################################################################
# Module:  FX_OpenSLIM_Windows_GetAssignedSystemMemory
# Version: 3.80b0
# Date:    2009/12/14
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ AssignedSystemMemory = $true, $true, $true, 'System', 'FX_OpenSLIM_Windows_GetAssignedSystemMemory', $false, @(); }


function FX_OpenSLIM_Windows_GetAssignedSystemMemory([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  if ( $test ) {
    if ( $NeedCredentials ) {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class win32_computersystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    } else {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -class win32_computersystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    }
  } else {
    if ( $NeedCredentials ) {
      $NodeData = Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class win32_computersystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue
    } else {
      $NodeData = Get-WmiObject -ComputerName $TargetNode -class win32_computersystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue
    }

    if ( $NodeData -ne $null ) {
      $ErrorFound   = -not $?
      $ErrorText   = $($NodeErrors | Format-List -force * | Out-String)
      $RawOutput   = "$NodeData.TotalPhysicalMemory"
      $ResultValue = "$([math]::Round($($NodeData.TotalPhysicalMemory / $ToGB),2))"

      Write-Host -foregroundcolor $COLOR_RESULT "    + TotalPhysicalMemory: " $ResultValue
    } else {
      . ReportModuleError $NodeData "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}