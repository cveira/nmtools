##############################################################################
# Module:  FX_OpenSLIM_Windows_GetNodeType
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ NodeTypeId = $true, $true, $true, 'System', 'FX_OpenSLIM_Windows_GetNodeType', $false, @(); }


function FX_OpenSLIM_Windows_GetNodeType([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  if ( $test ) {
    if ( $NeedCredentials ) {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class Win32_ComputerSystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    } else {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -class Win32_ComputerSystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    }
  } else {
    if ( $NeedCredentials ) {
      $Model = $(Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class Win32_ComputerSystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue).Model
    } else {
      $Model = $(Get-WmiObject -ComputerName $TargetNode -class Win32_ComputerSystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue).Model
    }

    if ( $Model -ne $null ) {
      # NodeTypeId	NodeTypeName
      # 1	          Unknown
      # 3	          Desktop PC
      # 4	          Regular Server
      # 5	          Blade
      # 6	          VMWare Server
      # 7	          MS Virtual Server
      # 14	        MS Virtual Server
      # 15	        Cluster Resource

      $NodeTypeId	  = 0
      $NodeTypeName = 1

      $NodeType = @{
        NotFound          = 1, 'Unknown';
        DesktopPC         = 3, 'Desktop PC';
        RegularServer     = 4, 'Regular Server';
        BladeServer       = 5, 'Blade';
        VMWareServer      = 6, 'VMWare Server';
        MSVirtualServer   = 7, 'MS Virtual Server';
        MSHyperVServer    = 14, 'MS Hyper-V Server';
        MSClusterResource = 15, 'Cluster Resource'
      }

      $IsUnknown = $true
      switch -regex ($Model) {
        'HP NetServer'               { $IsUnknown = $false ; $SysType = "RegularServer" }
        'ProLiant DL'                { $IsUnknown = $false ; $SysType = "RegularServer" }
        'ProLiant BL'                { $IsUnknown = $false ; $SysType = "BladeServer" }
        'HP Compaq dc'               { $IsUnknown = $false ; $SysType = "DesktopPC" }
        'IBM eServer BladeCenter HS' { $IsUnknown = $false ; $SysType = "BladeServer" }
        'eserver xSeries'            { $IsUnknown = $false ; $SysType = "RegularServer" }
        'VMware Virtual Platform'    { $IsUnknown = $false ; $SysType = "VMWareServer" }
        'Virtual Machine'            { $IsUnknown = $false ; $SysType = "MSVirtualServer" }
        'OptiPlex'                   { $IsUnknown = $false ; $SysType = "DesktopPC" }
        default                      { $IsUnknown = $true  }
      }

      if ( $IsUnknown ) {
        $ResultId          = $NodeType.NotFound[$NodeTypeId]
        $ResultDescription = $NodeType.NotFound[$NodeTypeName]
      } else {
        $ResultId          = $NodeType.$("$SysType")[$NodeTypeId]
        $ResultDescription = $NodeType.$("$SysType")[$NodeTypeName]
      }

      $ErrorFound  = $false
      $ErrorText   = $( $NodeErrors | Format-List -force * | Out-String )
      $RawOutput   = "$Model"
      $ResultValue = "$ResultId"

      Write-Host -foregroundcolor $COLOR_RESULT "    + NodeType:            " $ResultDescription " [" $ResultId "]"
    } else {
      . ReportModuleError $Model "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}