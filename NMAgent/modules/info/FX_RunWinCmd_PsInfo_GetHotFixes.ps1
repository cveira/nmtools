##############################################################################
# Module:  FX_PsTools_PsInfo_GetHotFixes
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ FX_PsTools_PsInfo_GetHotFixes = $true, $false, $false, 'System', 'FX_PsTools_PsInfo_GetHotFixes', $false, @(); }


function FX_PsTools_PsInfo_GetHotFixes([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  $SUCCESS_EXITCODE = 2
  $SavedExitCode    = $SUCCESS_EXITCODE

  # $PsInfoOpts     = "/accepteula {-h|-s|-d}"
  $PsInfoOpts       = "/accepteula -h"

  if ( $test ) {
    if ( $NeedCredentials ) {
      $ClearTextUserName = GetClearTextUserName $NetworkCredentials
      $ClearTextPassword = GetClearTextPassword $NetworkCredentials

      Write-Host -foregroundcolor $COLOR_RESULT "$BinDir\psinfo.exe \\$TargetNode -u $ClearTextUserName -p $ClearTextPassword $PsInfoOpts"
    } else {
      Write-Host -foregroundcolor $COLOR_RESULT "$BinDir\psinfo.exe \\$TargetNode $PsInfoOpts"
    }
  } else {
    if ( $NeedCredentials ) {
      $ClearTextUserName = GetClearTextUserName $NetworkCredentials
      $ClearTextPassword = GetClearTextPassword $NetworkCredentials

      $RunCmd            = "$BinDir\psinfo.exe \\$TargetNode -u $ClearTextUserName -p $ClearTextPassword $PsInfoOpts"
      $NodeData          = Invoke-Expression $RunCmd
      $SavedExitCode     = $LASTEXITCODE
    } else {
      $RunCmd            = "$BinDir\psinfo.exe \\$TargetNode $PsInfoOpts"
      $NodeData          = Invoke-Expression $RunCmd
      $SavedExitCode     = $LASTEXITCODE
    }

    if ( $SavedExitCode -eq $SUCCESS_EXITCODE ) {
      $print             = $false

      $ErrorFound        = $false
      $RawOutput         = $( $NodeData  | ForEach-Object { if ( $_ -eq "Installed     HotFix" ) { $print = $true } else { if ( $print ) { $_ } } } )
      $ResultValue       = $( $RawOutput | Measure-Object ).Count
      $RawOutput         = $RawOutput    | Out-String

      Write-Host
      Write-Host -foregroundcolor $COLOR_RESULT "    + Installed HotFixes:  " $ResultValue
      Write-Host

      . SetConsoleResultTheme

      $RawOutput

      . RestoreConsoleDefaultTheme
    } else {
      . ReportModuleError $NodeData "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}