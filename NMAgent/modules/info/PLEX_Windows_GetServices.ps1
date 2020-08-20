##############################################################################
# Module:  PLEX_Windows_GetServices
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ PLEX_Windows_GetServices = $true, $false, $false, 'System', 'PLEX_Windows_GetServices', $false, @(); }


# $PROPERTY_SET = "ProcessId", "StartMode", "State", "Name", "DisplayName", "PathName"
$PROPERTY_SET = "ProcessId", "StartMode", "State", "Name", "PathName"
$ORDER_BY     = "StartMode", "State"

function PLEX_Windows_GetServices([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  if ( $test ) {
    if ( $NeedCredentials ) {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class win32_service -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    } else {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -class win32_service -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    }
  } else {
    if ( !$PipelineInput ) {
      DisplayPlexHelp "<ServiceDisplayNamePattern>"
      break
    }


    if ( $NeedCredentials ) {
      $NodeData = Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class win32_service -ErrorVariable NodeErrors -ErrorAction silentlycontinue
    } else {
      $NodeData = Get-WmiObject -ComputerName $TargetNode -class win32_service -ErrorVariable NodeErrors -ErrorAction silentlycontinue
    }

    if ( $NodeData -ne $null ) {
      $SelectedServices = $NodeData | Where-Object { ( $_.Name -ne $null ) -and ( $_.DisplayName -match "$PipeLineInput" ) }

      $ErrorFound   = $false
      $ErrorText    = $( $NodeErrors | Format-List -force * | Out-String )
      $RawOutput    = $( $SelectedServices | Format-Table -autosize | Out-String ).Trim()
      $ResultValue  = $( $SelectedServices | Select-Object $( $PROPERTY_SET ) | Sort-Object $( $ORDER_BY ) | Format-Table -autosize | Out-String ).Trim()

      Write-Host -foregroundcolor $COLOR_RESULT "    + Services:            "
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