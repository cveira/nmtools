##############################################################################
# Module:  FX_Windows_GetPrimaryDnsResolver.ps1
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Hector Gil Mozos     - cveira [at] thinkinbig [dot] org
#          Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ FX_Windows_GetPrimaryDnsResolver = $true, $false, $true, 'System', 'FX_Windows_GetPrimaryDnsResolver', $false, @(); }


function FX_Windows_GetPrimaryDnsResolver([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  $DNS_PRIMARY_RESOLVER_INDEX = 0


  if ( $test ) {
    if ( $NeedCredentials ) {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -Class Win32_NetworkAdapterConfiguration -filter IPEnabled=TRUE -ErrorVariable NodeErrors -ErrorAction continue"
    } else {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -Class Win32_NetworkAdapterConfiguration -filter IPEnabled=TRUE -ComputerName $TargetNode -Credential $NetworkCredentials -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    }
  } else {
    if ( $NeedCredentials ) {
      $NodeData = Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -Class Win32_NetworkAdapterConfiguration -filter IPEnabled=TRUE -ErrorVariable NodeErrors -ErrorAction continue
    } else {
      $NodeData = Get-WmiObject -ComputerName $TargetNode -Class Win32_NetworkAdapterConfiguration -filter IPEnabled=TRUE -ErrorVariable NodeErrors -ErrorAction continue
    }

    if ( $NodeData -ne $null ) {
      $NodeData = $NodeData | Where-Object { $_.DNSServerSearchOrder -ne $null }

      if ( $NodeData -ne $null ) {
        [PSObject[]] $AdapterInfo = @()

        $AdapterInfo += $NodeData | ForEach-Object {
          New-Object PSObject -Property @{
            AttributeName      = ""
            ExtendedAttributes = "NicIndex" + $DAX_VALUE_DELIMITER + $_.Index.ToString()
            Value              = $_.DNSServerSearchOrder[$DNS_PRIMARY_RESOLVER_INDEX]
          }
        }


        $ErrorFound  = -not $?
        $ErrorText   = $( $NodeErrors  | Format-List * -force | Out-String )
        $RawOutput   = $( $NodeData    | Format-List * -force | Out-String ).Trim()
        $ResultValue = $AdapterInfo

        Write-Host -foregroundcolor $COLOR_RESULT "    + PrimaryDnsResolver:  "
        Write-Host

        . SetConsoleResultTheme

        $ResultValue | Format-Table Value, ExtendedAttributes -autoSize

        . RestoreConsoleDefaultTheme
      } else {
        . ReportModuleError $NodeData "ERROR: No NIC with DNS resolver."
      }
    } else {
      . ReportModuleError $NodeData "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}