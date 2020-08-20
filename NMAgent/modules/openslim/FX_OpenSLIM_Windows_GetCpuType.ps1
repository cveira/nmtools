##############################################################################
# Module:  FX_OpenSLIM_Windows_GetCpuType
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ CpuTypeId = $true, $true, $true, 'System', 'FX_OpenSLIM_Windows_GetCpuType', $false, @(); }


function FX_OpenSLIM_Windows_GetCpuType([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
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
      # CpuTypeId	CpuTypeName
      # 1         Unknown
      # 36	      Generic AMD x64
      # 37	      Generic Intel x64
      # 41	      Itanium
      # 42	      Itanium 2
      # 43	      Generic AMD x86
      # 44	      Generic Intel x86

      $CpuTypeId	 = 0
      $CpuTypeName = 1

      $CpuType = @{
        NotFound        = 1,  'Unknown';
        GenuineIntel32  = 44, 'Generic Intel x86';
        GenuineIntel64  = 37, 'Generic Intel x64';
        AuthenticAMD32  = 43, 'Generic AMD x86';
        AuthenticAMD64  = 36, 'Generic AMD x64'
      }

      $IsUnknown = $true
      if ( ($Manufacturer -eq 'GenuineIntel') -or ($Manufacturer -eq 'AuthenticAMD')) { $IsUnknown = $false }
      if ( ($AddressWidth -eq 32)             -or ($AddressWidth -eq 64))             { $IsUnknown = $false }

      if ( $IsUnknown ) {
        $ResultId          = $CpuType.NotFound[$CpuTypeId]
        $ResultDescription = $CpuType.NotFound[$CpuTypeName]
      } else {
        $ResultId          = $CpuType.$("$Manufacturer$AddressWidth")[$CpuTypeId]
        $ResultDescription = $CpuType.$("$Manufacturer$AddressWidth")[$CpuTypeName]
      }

      $ErrorFound  = $false
      $ErrorText   = $( $NodeErrors | Format-List -force * | Out-String )
      $RawOutput   = "$Manufacturer - $AddressWidth"
      $ResultValue = "$ResultId"

      Write-Host -foregroundcolor $COLOR_RESULT "    + CpuType:             " $ResultDescription " [" $ResultId "]"
    } else {
      . ReportModuleError $NodeData "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}