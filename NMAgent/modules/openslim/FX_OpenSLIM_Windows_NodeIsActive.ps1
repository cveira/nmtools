##############################################################################
# Module:  FX_OpenSLIM_Windows_NodeIsActive
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ NodeIsActive = $true, $true, $true, 'System', 'FX_OpenSLIM_Windows_NodeIsActive', $false, @(); }


function FX_OpenSLIM_Windows_NodeIsActive([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  if ( $test ) {
    if ( $NeedCredentials ) {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class Win32_OperatingSystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    } else {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -class Win32_OperatingSystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    }
  } else {
    if ( $NeedCredentials ) {
      $NodeData = $(Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class Win32_OperatingSystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue)
    } else {
      $NodeData = $(Get-WmiObject -ComputerName $TargetNode -class Win32_OperatingSystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue)
    }

    if ( $NodeData -ne $null ) {
      $ErrorFound  = $false
      $ErrorText   = $( $NodeErrors | Format-List -force * | Out-String )
      $RawOutput   = $( $NodeData   | Format-List -force * | Out-String )
      $ResultValue = "YES"

    } else {
      $ErrorFound  = $false
      $ErrorText   = $( $NodeErrors | Format-List -force * | Out-String )
      $RawOutput   = "INFO: unable to retrieve any information."
      $ResultValue = "NO"
    }

    Write-Host -foregroundcolor $COLOR_RESULT "    + NodeIsActive:        " $ResultValue


    . $ModulesDir\_CloseModuleContext.ps1
  }
}