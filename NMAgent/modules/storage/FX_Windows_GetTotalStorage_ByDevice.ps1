##############################################################################
# Module:  FX_Windows_GetTotalStorage_ByDevice.ps1
# Version: 4.54b0
# Date:    2010/12/11
# Author:  David Llerena
#          Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ FX_Windows_GetTotalStorage_ByDevice = $true, $false, $true, 'System', 'FX_Windows_GetTotalStorage_ByDevice', $false, @(); }


function FX_Windows_GetTotalStorage_ByDevice([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
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
      $NodeData = $NodeData | Where-Object { $_.DeviceID -ne $null }

      if ( $NodeData -ne $null ) {
        [PSObject[]] $AdapterInfo = @()

        $DriveInfo += $NodeData | ForEach-Object {
          New-Object PSObject -Property @{
            AttributeName      = $_.DeviceID
            ExtendedAttributes = ""
            Value              = $_.Size
          }
        }

        $ErrorFound  = -not $?
        $ErrorText   = $( $NodeErrors  | Format-List * -force | Out-String )
        $RawOutput   = $( $NodeData    | Format-List * -force | Out-String ).Trim()
        $ResultValue = $DriveInfo

        Write-Host -foregroundcolor $COLOR_RESULT "    + TotaStorage (GB):    "
        Write-Host

        . SetConsoleResultTheme

        $DriveInfo | Select-Object AttributeName, @{ Name = "Value (GB)"; Expression = { $( ((( $_.Value /1024)/1024)/1024 ).ToString("###,###,##0.00") ) } } | Format-Table * -autoSize

        . RestoreConsoleDefaultTheme
      } else {
        . ReportModuleError $NodeData "ERROR: No drive detected."
      }
    } else {
      . ReportModuleError $NodeData "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}