##############################################################################
# Module:  FX_Win2k3_SystemBoot_Add3GB
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ FX_Win2k3_SystemBoot_Add3GB = $true, $true, $true, 'System', 'FX_Win2k3_SystemBoot_Add3GB', $false, @(); }


function FX_Win2k3_SystemBoot_Add3GB([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  if ( $test ) {
    Write-Host -foregroundcolor $COLOR_RESULT "MapNetworkDrive X: \\$TargetNode\c$"
  } else {
    $LocalDrive       = FindFreeLocalDrive
    $ConnectionStatus = MapNetworkDrive $LocalDrive \\$TargetNode\c$

    if ( $ConnectionStatus -eq $OPERATION_SUCCESSFUL ) {
      $NodeData = Get-Content $LocalDrive\boot.ini

      if ( $NodeData -ne $null ) {
        $NewBootSettings = ""

        if ( $( $NodeData | Select-String "PAE|3GB" ) -eq $null ) {
          $NewBootSettings =  $NodeData | ForEach-Object {
            if ( $_.SubString(0,5) -eq "multi" ) {
              "$_ /PAE /3GB"
            } else {
              $_
            }
          }

          $NodeData          >> $LocalDrive\_bak_$AgentUserName-$LogSessionId-boot.ini

          attrib.exe          $LocalDrive\boot.ini -H -S -R

          if ( $LASTEXITCODE -eq $OPERATION_SUCCESSFUL ) {
            Remove-Item         $LocalDrive\boot.ini -Force
            $NewBootSettings >> $LocalDrive\boot.ini
            attrib.exe          $LocalDrive\boot.ini +H +S +R

            if ( $LASTEXITCODE -eq $OPERATION_SUCCESSFUL ) {
              $ErrorFound  = $false
              $ErrorText   = ""
              $RawOutput   = $NewBootSettings
              $ResultValue = "SUCCESS"
            } else {
              . ReportModuleError $NodeData "ERROR: unable to restore protection to boot.ini file."
              $ResultValue = "FAILURE"
            }
          } else {
            . ReportModuleError $NodeData "ERROR: unable to unprotect boot.ini file."
            $ResultValue   = "FAILURE"
          }
        } else {
          $ErrorFound      = $false
          $ErrorText       = ""
          $RawOutput       = $NodeData

          $ResultValue     = "SUCCESS (Nothing to change)"
        }

        Write-Host
        Write-Host -foregroundcolor $COLOR_RESULT "    + PAE/3GB Removal:     " $ResultValue
        Write-Host

        $ConnectionStatus = UnMapNetworkDrive $LocalDrive

        if ( $ConnectionStatus -ne $OPERATION_SUCCESSFUL ) {
          . ReportModuleError $NodeData "ERROR: unable to un-map netowrk drive ($LocalDrive)."
        }
      } else {
        . ReportModuleError $NodeData "ERROR: unable read boot.ini file."
      }
    } else {
      . ReportModuleError $NodeData "ERROR: unable to map network drive."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}