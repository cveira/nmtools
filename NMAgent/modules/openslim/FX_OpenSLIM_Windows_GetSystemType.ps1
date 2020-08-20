##############################################################################
# Module:  FX_OpenSLIM_Windows_GetSystemType
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ SystemTypeId = $true, $true, $true, 'System', 'FX_OpenSLIM_Windows_GetSystemType', $false, @(); }


function FX_OpenSLIM_Windows_GetSystemType([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  if ( $test ) {
    if ( $NeedCredentials ) {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class Win32_OperatingSystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    } else {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -class Win32_OperatingSystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    }
  } else {
    if ( $NeedCredentials ) {
      $InstalledOS = $(Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class Win32_OperatingSystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue).Caption
    } else {
      $InstalledOS = $(Get-WmiObject -ComputerName $TargetNode -class Win32_OperatingSystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue).Caption
    }

    if ( $InstalledOS -ne $null ) {
      # SystemTypeId	SystemTypeName
      # 1	            Unknown
      # 3	            Windows NT 4.0
      # 4	            Windows 2000
      # 5	            Windows 2003
      # 6	            Windows 2008
      # 18	          Windows XP
      # 19	          Windows Vista
      # 20	          Windows 2003 R2
      # 21	          Windows 2008 R2
      # 22	          Windows 7


      $SystemTypeId	 = 0
      $SystemTypeName = 1

      $SystemType = @{
        NotFound  = 1,  'Unknown';
        winnt4    = 3,  'Windows NT 4.0';
        win2000   = 4,  'Windows 2000';
        win2003   = 5,  'Windows 2003';
        win2003R2 = 20, 'Windows 2003 R2';
        win2008   = 6,  'Windows 2008';
        win2008R2 = 21, 'Windows 2008 R2';
        winxp     = 18, 'Windows XP';
        winvista  = 19, 'Windows Vista';
        win7      = 22, 'Windows 7'
      }

      $DetectedVersion = @{
        NotFound  = 'Unknown';
        winnt4    = 'NT 4.0';
        win2000   = '2000';
        win2003   = '2003';
        win2003R2 = '2003 R2';
        win2008   = '2008';
        win2008R2 = '2008 R2';
        winxp     = 'XP';
        winvista  = 'Vista';
        win7      = '7'
      }

      $IsUnknown = $true
      if ( $InstalledOS -match "(?<Name>[A-Za-z\s\(\)]+)(?<Version>(\d+\sR2|\d+)|XP|Vista)(?<Other>[\w\s\.\,]+)" ) { $IsUnknown = $false }

      if ( !$IsUnknown ) {
        switch -regex ( $Matches.Version.Trim() ) {
          $DetectedVersion.winnt4    { $ResultId = $SystemType.winnt4[$SystemTypeId];    $ResultDescription = $SystemType.winnt4[$SystemTypeName] }
          $DetectedVersion.win2000   { $ResultId = $SystemType.win2000[$SystemTypeId];   $ResultDescription = $SystemType.win2000[$SystemTypeName] }
          $DetectedVersion.win2003   { $ResultId = $SystemType.win2003[$SystemTypeId];   $ResultDescription = $SystemType.win2003[$SystemTypeName] }
          $DetectedVersion.win2003R2 { $ResultId = $SystemType.win2003R2[$SystemTypeId]; $ResultDescription = $SystemType.win2003R2[$SystemTypeName] }
          $DetectedVersion.win2008   { $ResultId = $SystemType.win2008[$SystemTypeId];   $ResultDescription = $SystemType.win2008[$SystemTypeName] }
          $DetectedVersion.win2008R2 { $ResultId = $SystemType.win2008R2[$SystemTypeId]; $ResultDescription = $SystemType.win2008R2[$SystemTypeName] }
          $DetectedVersion.winxp     { $ResultId = $SystemType.winxp[$SystemTypeId];     $ResultDescription = $SystemType.winxp[$SystemTypeName] }
          $DetectedVersion.winvista  { $ResultId = $SystemType.winvista[$SystemTypeId];  $ResultDescription = $SystemType.winvista[$SystemTypeName] }
          $DetectedVersion.win7      { $ResultId = $SystemType.win7[$SystemTypeId];      $ResultDescription = $SystemType.win7[$SystemTypeName] }
          default                    { $ResultId = $SystemType.NotFound[$SystemTypeId];  $ResultDescription = $SystemType.NotFound[$SystemTypeName] }
        }
      } else {
        $ResultId          = $SystemType.NotFound[$SystemTypeId]
        $ResultDescription = $SystemType.NotFound[$SystemTypeName]
      }


      $ErrorFound  = -not $?
      $ErrorText   = $( $NodeErrors | Format-List -force * | Out-String )
      $RawOutput   = "$InstalledOS"
      $ResultValue = "$ResultId"

      Write-Host -foregroundcolor $COLOR_RESULT "    + SystemType:          " $ResultDescription " [" $ResultId "]"
    } else {
      . ReportModuleError $InstalledOS "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}