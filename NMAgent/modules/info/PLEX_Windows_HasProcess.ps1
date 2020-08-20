##############################################################################
# Module:  PLEX_Windows_HasProcess
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ PLEX_Windows_HasProcess = $true, $false, $true, 'System', 'PLEX_Windows_HasProcess', $false, @(); }


function PLEX_Windows_HasProcess([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  if ( $test ) {
    if ( $NeedCredentials ) {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class win32_process -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    } else {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -class win32_process -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    }
  } else {
    if ( !$PipelineInput ) {
      DisplayPlexHelp "<CommandLinePattern>"
      break
    }


    if ( $NeedCredentials ) {
      $NodeData = Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class win32_process -ErrorVariable NodeErrors -ErrorAction silentlycontinue
    } else {
      $NodeData = Get-WmiObject -ComputerName $TargetNode -class win32_process -ErrorVariable NodeErrors -ErrorAction silentlycontinue
    }

    if ( $NodeData -ne $null ) {
      $SelectedProcesses = $NodeData | Where-Object { $_.CommandLine -match "$PipeLineInput" }

      if ( $SelectedProcesses -ne $null ) {
        $HasProcess = "YES"
      } else {
        $HasProcess = "NO"
      }

      $ErrorFound   = $false
      $ErrorText    = $( $NodeErrors | Format-List -force * | Out-String )
      $RawOutput    = $( $SelectedProcesses | Format-List | Out-String ).Trim()
      $ResultValue  = $HasProcess

      Write-Host -foregroundcolor $COLOR_RESULT "    + HasProcess:          " $ResultValue
    } else {
      . ReportModuleError $NodeData "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}