##############################################################################
# Module:  FX_OpenSLIM_Windows_GetMajorPatchLevel
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ MajorPatchLevelId = $true, $true, $true, 'System', 'FX_OpenSLIM_Windows_GetMajorPatchLevel', $false, @(); }


function FX_OpenSLIM_Windows_GetMajorPatchLevel([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  if ( $test ) {
    if ( $NeedCredentials ) {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class Win32_OperatingSystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    } else {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -class Win32_OperatingSystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    }
  } else {
    if ( $NeedCredentials ) {
      $MajorPatchLevel = $(Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class Win32_OperatingSystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue).ServicePackMajorVersion
    } else {
      $MajorPatchLevel = $(Get-WmiObject -ComputerName $TargetNode -class Win32_OperatingSystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue).ServicePackMajorVersion
    }

    if ( $MajorPatchLevel -ne $null ) {
      # MajorPatchLevelId	MajorPatchLevelName
      # 1	                Unknown
      # 24	              N/A
      # 25	              SP0
      # 26	              SP1
      # 27	              SP2
      # 28	              SP3
      # 29	              SP4
      # 30	              SP5
      # 31	              SP6
      # 32	              SP7
      # 33	              SP8
      # 34	              SP9
      # 35	              SP10

      $PatchLevelId	  = 0
      $PatchLevelName = 1

      $PatchLevel = @{
        NotFound = 1,  'Unknown';
        0        = 25, 'SP0';
        1        = 26, 'SP1';
        2        = 27, 'SP2';
        3        = 28, 'SP3';
        4        = 29, 'SP4';
        5        = 30, 'SP5';
        6        = 31, 'SP6';
        7        = 32, 'SP7';
        8        = 33, 'SP8';
        9        = 34, 'SP9';
        10       = 35, 'SP10'
      }

      $IsUnknown = $false
      if ( $MajorPatchLevel -eq $null ) { $IsUnknown = $true  }
      if ( $MajorPatchLevel -lt 0     ) { $IsUnknown = $true  }
      if ( $MajorPatchLevel -gt 10    ) { $IsUnknown = $true  }

      if ( $IsUnknown ) {
        $ResultId          = $PatchLevel.NotFound[$PatchLevelId]
        $ResultDescription = $PatchLevel.NotFound[$PatchLevelName]
      } else {
        $ResultId          = $PatchLevel[[int] $MajorPatchLevel][$PatchLevelId]
        $ResultDescription = $PatchLevel[[int] $MajorPatchLevel][$PatchLevelName]
      }

      $ErrorFound  = -not $?
      $ErrorText   = $( $NodeErrors | Format-List -force * | Out-String )
      $RawOutput   = "$MajorPatchLevel"
      $ResultValue = "$ResultId"

      Write-Host -foregroundcolor $COLOR_RESULT "    + MajorPatchLevel:     " $ResultDescription " [" $ResultId "]"
    } else {
      . ReportModuleError $MajorPatchLevel "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}