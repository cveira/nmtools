##############################################################################
# Module:  FX_Windows_GetTotalFreeSpaceLocalStorage.ps1
# Version: 4.54b0
# Date:    2010/12/11
# Author:  David Llerena
#          Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ FX_Windows_GetTotalFreeSpaceLocalStorage = $true, $false, $true, 'System', 'FX_Windows_GetTotalFreeSpaceLocalStorage', $false, @(); }


function FX_Windows_GetTotalFreeSpaceLocalStorage([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  if ( $test ) {
    if ( $NeedCredentials ) {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -Class Win32_LogicalDisk -ErrorVariable NodeErrors -ErrorAction continue"
    } else {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -Class Win32_LogicalDisk -ComputerName $TargetNode -Credential $NetworkCredentials -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    }
  } else {
    if ( $NeedCredentials ) {
      $NodeData = Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -Class Win32_LogicalDisk -ErrorVariable NodeErrors -ErrorAction continue
    } else {
      $NodeData = Get-WmiObject -ComputerName $TargetNode -Class Win32_LogicalDisk -ErrorVariable NodeErrors -ErrorAction continue
    }

    if ( $NodeData -ne $null ) {
      $NodeData = $NodeData | Where-Object { ( $_.DeviceID -ne $null ) -and ( $_.DriveType -match "3" ) -and ( $_.Size -ne $null ) }

      if ( $NodeData -ne $null ) {

	    $TotalFreeSpace = 0
        $NodeData | ForEach-Object { $TotalFreeSpace += $_.FreeSpace }
 
        $ErrorFound  = -not $?
        $ErrorText   = $( $NodeErrors  | Format-List * -force | Out-String )
        $RawOutput   = $( $NodeData    | Format-List * -force | Out-String ).Trim()
        $ResultValue = $TotalFreeSpace

        Write-Host -foregroundcolor $COLOR_RESULT "    + TotalFreeSpace (GB):    " $( ((($ResultValue/1024)/1024)/1024).ToString("###,##0.00") )
        Write-Host
		
      } else {
        . ReportModuleError $NodeData "ERROR: No drive detected."
      }
    } else {
      . ReportModuleError $NodeData "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}