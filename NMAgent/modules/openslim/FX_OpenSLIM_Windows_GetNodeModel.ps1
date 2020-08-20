##############################################################################
# Module:  FX_OpenSLIM_Windows_GetNodeModel
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ NodeModel = $true, $true, $true, 'System', 'FX_OpenSLIM_Windows_GetNodeModel', $false, @(); }


function FX_OpenSLIM_Windows_GetNodeModel([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
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
      $ErrorText   = $( $NodeErrors | Format-List -force * | Out-String )
      $RawOutput   = $( $NodeData.Model | Out-String ).Trim()
      $ResultValue = $( $NodeData.Model | Out-String ).Trim()

      Write-Host -foregroundcolor $COLOR_RESULT "    + NodeModel:           " $ResultValue
    } else {
      . ReportModuleError $NodeData "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}