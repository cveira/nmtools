##############################################################################
# Module:  FX_Windows_GetTotalSANStorage.ps1
# Version: 4.54b0
# Date:    2010/12/11
# Author:  David Llerena
#          Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ FX_Windows_GetTotalSANStorage = $true, $false, $true, 'System', 'FX_Windows_GetTotalSANStorage', $false, @(); }


function FX_Windows_GetTotalSANStorage([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  if ( $test ) {
    if ( $NeedCredentials ) {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -Class Win32_DiskDrive -ErrorVariable NodeErrors -ErrorAction continue"
    } else {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -Class Win32_DiskDrive -ComputerName $TargetNode -Credential $NetworkCredentials -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    }
  } else {
    if ( $NeedCredentials ) {
      $NodeData = Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -Class Win32_DiskDrive -ErrorVariable NodeErrors -ErrorAction continue
    } else {
      $NodeData = Get-WmiObject -ComputerName $TargetNode -Class Win32_DiskDrive -ErrorVariable NodeErrors -ErrorAction continue
    }

    if ( $NodeData -ne $null ) {
      $NodeData = $NodeData | Where-Object { ( $_.DeviceID -ne $null ) -and ( $_.Model -match "PowerPath|SDD|Multi-Path" )  }

      if ( $NodeData -ne $null ) {
        $TotalStorage = 0
        $NodeData | ForEach-Object { $TotalStorage += $_.Size }

        $ErrorFound  = -not $?
        $ErrorText   = $( $NodeErrors  | Format-List * -force | Out-String )
        $RawOutput   = $( $NodeData    | Format-List * -force | Out-String ).Trim()
        $ResultValue = $TotalStorage

        Write-Host -foregroundcolor $COLOR_RESULT "    + TotaStorage (GB):    " $( ((($TotalStorage/1024)/1024)/1024).ToString("###,###,##0.00") )
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