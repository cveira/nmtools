##############################################################################
# Module:  FX_Windows_GetUnknownProcesses
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ FX_Windows_GetUnknownProcesses = $true, $false, $false, 'System', 'FX_Windows_GetUnknownProcesses', $false, @(); }


function FX_Windows_GetUnknownProcesses([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
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

      [string[]] $ProcessWhiteList = @()

      Get-ChildItem $ModulesDir\$SX_ProcessWhiteListShortPath\*.txt -exclude _* | ForEach-Object {
        $ProcessWhiteList += Get-Content $_
      }

      $ProcessWhiteList            = $ProcessWhiteList | ForEach-Object { if ( $_ -ne "" ) { $_.Trim() } }
      $ProcessWhiteList            = $ProcessWhiteList | Select-String "#" -NotMatch
      $ProcessWhiteList            = $ProcessWhiteList | Select-Object -unique

      [string[]] $TargetProcesses  = @()
      $SelectedProcesses | ForEach-Object { $TargetProcesses += "$($_.Name.Trim())" }
      $TargetProcesses             = $TargetProcesses | Select-Object -unique

      $ResultValue  = Compare-Object $ProcessWhiteList $TargetProcesses | Where-Object { $_.SideIndicator -eq "=>" } | Select-Object InputObject

      if ( $ResultValue -eq $null ) { $ResultValue = "N/A" }

      $ErrorFound   = $false
      $ErrorText    = $( $NodeErrors | Format-List -force * | Out-String )
      $RawOutput    = $( $SelectedProcesses | Format-Table -auto | Out-String ).Trim()
      $ResultValue  = $( $ResultValue | Out-String ).Trim()

      Write-Host -foregroundcolor $COLOR_RESULT "    + Unknown Processes:   "
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