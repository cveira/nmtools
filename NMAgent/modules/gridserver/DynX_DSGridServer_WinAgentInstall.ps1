##############################################################################
# Module:  DynX_DSGridServer_WinAgentInstall
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ DynX_DSGridServer_WinAgentInstall = $true, $false, $true, 'System', 'DynX_DSGridServer_WinAgentInstall', $false, @(); }


function DynX_DSGridServer_WinAgentInstall([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  Write-Host -foregroundcolor $COLOR_DARK "    + Loading DynX modules: "

  Get-ChildItem $ModulesDir\$CurrentProfile\DynX_DSGridServer_WinAgentInstall\*.ps1 -exclude _* | ForEach-Object {
    Write-Host -foregroundcolor $COLOR_DARK -noNewLine "      + Loading: "
    Write-Host -foregroundcolor $COLOR_BRIGHT $_.Name

    . $_
  }


  $DEFAULT_DRIVE = "C:"
  $TARGET_DRIVE  = "D:"


  if ( $NeedCredentials ) {
    $NodeData = $(Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class Win32_Volume -ErrorVariable NodeErrors -ErrorAction silentlycontinue)
  } else {
    $NodeData = $(Get-WmiObject -ComputerName $TargetNode -class Win32_Volume -ErrorVariable NodeErrors -ErrorAction silentlycontinue)
  }

  if ( $NodeData -ne $null ) {
    Write-Host -foregroundcolor $COLOR_RESULT "    + SystemDrives: " $($NodeData | Measure-Object).Count

    $SelectedDrive = $DEFAULT_DRIVE
    $NodeData | ForEach-Object {
      if ( $_.DriveLetter -eq $TARGET_DRIVE ) {
        $SelectedDrive = $TARGET_DRIVE
      }
    }

    Write-Host -foregroundcolor $COLOR_RESULT "    + SelectedDrive: " $SelectedDrive

    $ErrorFound  = $false
    $RawOutput   = $( $NodeData | Out-String )
    $ResultValue = $SelectedDrive


    switch ( $SelectedDrive ) {
      $DEFAULT_DRIVE { $UIScriptFile = "InstallInC.iss" }
      $TARGET_DRIVE  { $UIScriptFile = "InstallInD.iss" }
      default        { $UIScriptFile = "InstallInC.iss" }
    }

    DynX1_RunWinCmd_DSGridServer_WinAgentInstall $SetConnectToHostByIP $NodeName $NodeIP "DynX1_RunWinCmd_DSGridServer_WinAgentInstall" $IsSupported $IsString
  } else {
    . ReportModuleError $NodeData "ERROR: unable to retrieve any information."
  }


  . $ModulesDir\_CloseModuleContext.ps1
}