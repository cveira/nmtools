##############################################################################
# Module:  FX_OpenSLIM_Windows_GetArchitectureType
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ ArchitectureTypeId = $true, $true, $true, 'System', 'FX_OpenSLIM_Windows_GetArchitectureType', $false, @(); }


function FX_OpenSLIM_Windows_GetArchitectureType([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  if ( $test ) {
    if ( $NeedCredentials ) {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class Win32_Processor -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    } else {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -class Win32_Processor -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    }
  } else {
    if ( $NeedCredentials ) {
      $NodeData = $(Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class Win32_Processor -ErrorVariable NodeErrors -ErrorAction silentlycontinue)
    } else {
      $NodeData = $(Get-WmiObject -ComputerName $TargetNode -class Win32_Processor -ErrorVariable NodeErrors -ErrorAction silentlycontinue)
    }

    if ( $NodeData -ne $null ) {
      if ( $NodeData.gettype().Name -eq "ManagementObject" ) {
        $AddressWidth = $NodeData.AddressWidth
        $Manufacturer = $NodeData.Manufacturer
      } else {
        $AddressWidth = $NodeData[0].AddressWidth
        $Manufacturer = $NodeData[0].Manufacturer
      }

      # Manufacturer ::= {"GenuineIntel" | "AuthenticAMD"}
      # ArchitectureTypeId	ArchitectureTypeName
      # 1                   Unknown
      # 3                   Intel x86
      # 4                   Intel x64
      # 5                   Intel ia64
      # 12	                AMD x86
      # 13	                AMD x64

      $ArchitectureTypeId	  = 0
      $ArchitectureTypeName = 1

      $ArchitectureType = @{
        NotFound        = 1,  'Unknown';
        GenuineIntel32  = 3,  'Intel x86';
        GenuineIntel64  = 4,  'Intel x64';
        AuthenticAMD32  = 12, 'AMD x86';
        AuthenticAMD64  = 13, 'AMD x64'
      }

      $IsUnknown = $true
      if ( ($Manufacturer -eq 'GenuineIntel') -or ($Manufacturer -eq 'AuthenticAMD')) { $IsUnknown = $false }
      if ( ($AddressWidth -eq 32)             -or ($AddressWidth -eq 64))             { $IsUnknown = $false }

      if ( $IsUnknown ) {
        $ResultId          = $ArchitectureType.NotFound[$ArchitectureTypeId]
        $ResultDescription = $ArchitectureType.NotFound[$ArchitectureTypeName]
      } else {
        $ResultId          = $ArchitectureType.$("$Manufacturer$AddressWidth")[$ArchitectureTypeId]
        $ResultDescription = $ArchitectureType.$("$Manufacturer$AddressWidth")[$ArchitectureTypeName]
      }

      $ErrorFound  = $false
      $ErrorText   = $( $NodeErrors | Format-List -force * | Out-String )
      $RawOutput   = "$Manufacturer - $AddressWidth"
      $ResultValue = "$ResultId"

      Write-Host -foregroundcolor $COLOR_RESULT "    + ArchitectureType:    " $ResultDescription " [" $ResultId "]"
    } else {
      . ReportModuleError $NodeData "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}