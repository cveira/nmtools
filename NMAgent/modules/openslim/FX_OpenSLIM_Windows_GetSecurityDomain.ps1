##############################################################################
# Module:  FX_OpenSLIM_Windows_GetSecurityDomain
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ SecurityDomainId = $true, $true, $true, 'System', 'FX_OpenSLIM_Windows_GetSecurityDomain', $false, @(); }


function FX_OpenSLIM_Windows_GetSecurityDomain([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  if ( $test ) {
    if ( $NeedCredentials ) {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class Win32_ComputerSystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    } else {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -class Win32_ComputerSystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    }
  } else {
    if ( $NeedCredentials ) {
      $NodeData = Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class Win32_ComputerSystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue
    } else {
      $NodeData = Get-WmiObject -ComputerName $TargetNode -class Win32_ComputerSystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue
    }

    if ( $NodeData -ne $null ) {
      #  6	AD.DOM2
      #  5	AD.DOM1
      #  2	N/A
      #  4	Unassigned
      #  3	Unavailable
      #  1	Unknown

      $SecurityDomainId	  = 0
      $SecurityDomainName = 1

      $SecurityDomain = @{
        NotFound     = 1,   'Unknown';
        NotAplicable = 2,   'N/A';
        Unavailable  = 3,   'Unavailable';
        Unassigned   = 4,   'Unassigned';
        DOM1         = 5,   'dom1.corp';
        DOM2         = 6,   'dom2.corp'        
      }


      $IsUnknown = $true
      switch -regex ( $NodeData.Domain ) {
        $SecurityDomain.DOM1[$SecurityDomainName] { $IsUnknown = $false ; $DomainKey = "DOM1" }
        $SecurityDomain.DOM2[$SecurityDomainName] { $IsUnknown = $false ; $DomainKey = "DOM2" }
        default                                   { $IsUnknown = $true                        }
      }

      if ( $IsUnknown ) {
        $ResultId          = $SecurityDomain.NotFound[$SecurityDomainId]
        $ResultDescription = $SecurityDomain.NotFound[$SecurityDomainName]
      } else {
        $ResultId          = $SecurityDomain.$("$DomainKey")[$SecurityDomainId]
        $ResultDescription = $SecurityDomain.$("$DomainKey")[$SecurityDomainName]
      }


      [PSObject[]] $DomainInfo = @()

      $DomainInfo += $NodeData | ForEach-Object {
        New-Object PSObject -Property @{
            AttributeName      = $ResultDescription
            ExtendedAttributes = ""
            Value              = $ResultId
        }
      }


      $ErrorFound  = $false
      $ErrorText   = $( $NodeErrors | Format-List -force * | Out-String )
      $RawOutput   = "$ResultId - $ResultDescription"
      $ResultValue = $DomainInfo

      Write-Host -foregroundcolor $COLOR_RESULT "    + SecurityDomain:      " $ResultDescription " [" $ResultId "]"
    } else {
      . ReportModuleError $NodeData "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}
