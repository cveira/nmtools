##############################################################################
# Module:  FX_Windows_GetProcesses
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ FX_Windows_GetProcesses = $true, $false, $false, 'System', 'FX_Windows_GetProcesses', $false, @(); }


function FX_Windows_GetProcesses([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  # $PROPERTY_SET = "ProcessId", "SessionId", "Name", "VirtualSize", "WorkingSetSize", "KernelModeTime", "UserModeTime", "ThreadCount", "HandleCount", "PageFaults"
  $PROPERTY_SET = "ProcessId", "SessionId", "Name", "CommandLine"
  $ORDER_BY     = "SessionId"


  if ( $test ) {
    if ( $NeedCredentials ) {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class win32_process -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    } else {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -class win32_process -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    }
  } else {
    if ( $NeedCredentials ) {
      $NodeData = Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class win32_process -ErrorVariable NodeErrors -ErrorAction silentlycontinue
    } else {
      $NodeData = Get-WmiObject -ComputerName $TargetNode -class win32_process -ErrorVariable NodeErrors -ErrorAction silentlycontinue
    }

    if ( $NodeData -ne $null ) {
      $SelectedProcesses = $NodeData | Where-Object { $_.Name -ne $null }

      $ErrorFound   = $false
      $ErrorText    = $( $NodeErrors | Format-List -force * | Out-String )
      $RawOutput    = $( $SelectedProcesses | Format-List | Out-String ).Trim()
      $ResultValue  = $( $SelectedProcesses | Select-Object $( $PROPERTY_SET ) | Sort-Object $( $ORDER_BY ) | Format-Table -autosize | Out-String ).Trim()

      Write-Host -foregroundcolor $COLOR_RESULT "    + Processes:           "
      Write-Host

      . SetConsoleResultTheme

      $ResultValue

      . RestoreConsoleDefaultTheme
    } else {
      . ReportModuleError $NodeData "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}