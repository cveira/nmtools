##############################################################################
# Module:  DynX_Windows_PackageInstall
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ DynX_Windows_PackageInstall = $true, $false, $false, 'System', 'DynX_Windows_PackageInstall', $false, @(); }


function DynX_Windows_PackageInstall([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  # [string[]] $SUPPORTED_PACKAGES = '*.exe','*.msi','*.zip','*.rar'
  [string[]] $SUPPORTED_PACKAGES = '*.exe','*.msi'

  $SkipCurrentNode = $false


  Write-Host -foregroundcolor $COLOR_DARK "    + Loading DynX modules: "

  Get-ChildItem $ModulesDir\$CurrentProfile\DynX_Windows_PackageInstall\*.ps1 -exclude _* | ForEach-Object {
    Write-Host -foregroundcolor $COLOR_DARK -noNewLine "      + Loading: "
    Write-Host -foregroundcolor $COLOR_BRIGHT $_.Name

    . $_
  }


  if ( $PipeLineInput -ne $null ) {
    $SX_SoftwareLibrary = $PipeLineInput

    if ( ( $SX_RepositoryServer -eq $null ) -or ( $SX_SoftwareLibrary -eq $null ) ) {
      Write-Host
      . ReportModuleError "$SX_RepositoryServer - $SX_SoftwareLibrary" "ERROR: Software Repository or Store were not defined."
      $SkipCurrentNode = $true
    }
  } else {
    if ( ( $SX_RepositoryServer -eq $null ) -or ( $SX_SoftwareStore -eq $null ) -or ( $SX_SoftwareLibrary -eq $null ) ) {
      Write-Host
      . ReportModuleError "$SX_RepositoryServer - $SX_SoftwareStore - $SX_SoftwareLibrary" "ERROR: Software Repository, Store or Library were not defined."
      $SkipCurrentNode = $true
    }
  }

  if ( !$SkipCurrentNode ) {
    Write-Host
    Write-Host -foregroundcolor $COLOR_DARK -noNewLine "    + Discovering SystemType... "
    $SystemType       = GetRemoteSystemType
    Write-Host -foregroundcolor $COLOR_RESULT "done"

    switch ( $SystemType ) {
      $ERROR_MATCHING_SYSTEMTYPE { Write-Host -foregroundcolor $COLOR_ERROR  "      + ERROR: Unable to match to a Supported System Type." ; $SystemType = $UNKNOWN_ITEM }
      $ERROR_UNKNOWN_SYSTEMTYPE  { Write-Host -foregroundcolor $COLOR_ERROR  "      + ERROR: Unable to match to a Supported System Type." ; $SystemType = $UNKNOWN_ITEM }
      $ERROR_NULL_DATA           { Write-Host -foregroundcolor $COLOR_ERROR  "      + ERROR: Unable to retrieve any information."         ; $SystemType = $UNKNOWN_ITEM }
      default                    { Write-Host -foregroundcolor $COLOR_DARK -noNewLine "      + INFO: SystemType is: " ; Write-Host -foregroundcolor $COLOR_RESULT $SystemType }
    }


    Write-Host
    Write-Host -foregroundcolor $COLOR_DARK -noNewLine "    + Loading Selected Packages... "
    $PackagesToInstall  = Get-ChildItem \\$SX_RepositoryServer\$SX_SoftwareStore\$SX_SoftwareLibrary\$SystemType\* -include $SUPPORTED_PACKAGES -exclude _* | Sort-Object Name
    Write-Host -foregroundcolor $COLOR_RESULT "done"


    Write-Host -foregroundcolor $COLOR_DARK -noNewLine "      + File Set Size... "
    $FileSetSize        = GetFileSetSize $PackagesToInstall
    Write-Host -foregroundcolor $COLOR_RESULT $( $FileSetSize / 1MB).ToString("#,###,###,##0.00") "MB"


    Write-Host
    Write-Host -foregroundcolor $COLOR_DARK -noNewLine "    + Retrieving Target Free Space... "
    $TargetFreeSpace    = GetTargetFreeSpace "\\$TargetNode\c$"

    switch ( $TargetFreeSpace ) {
      $ERROR_DRIVE_NOTFOUND { Write-Host -foregroundcolor $COLOR_RESULT "0 MB"                                                       }
      $ERROR_NULL_DATA      { Write-Host -foregroundcolor $COLOR_RESULT "0 MB"                                                       }
      default               { Write-Host -foregroundcolor $COLOR_RESULT $( $TargetFreeSpace / 1MB).ToString("#,###,###,##0.00") "MB" }
    }

    if ( $TargetFreeSpace -lt $( $FileSetSize * $SX_SpaceGrowthRate ) ) { $SkipCurrentNode = $true }
  }


  if ( ( $PackagesToInstall -ne $null ) -and ( $FileSetSize -ne 0 ) -and ( !$SkipCurrentNode ) ) {
    if ( $SystemType -ne $UNKNOWN_ITEM ) {
      Write-Host
      Write-Host -foregroundcolor $COLOR_DARK -noNewLine "    + Uploading Packages... "

      if ( $test ) {
         Write-Host -foregroundcolor $COLOR_RESULT "done"
         Write-Host -foregroundcolor $COLOR_RESULT "      + Target: \\$TargetNode\c$"
      } else {
        $UploadStatus = UploadFilesToCIFS $PackagesToInstall "\\$TargetNode\c$"

        Write-Host -foregroundcolor $COLOR_RESULT "done"

        switch ( $UploadStatus ) {
          $ERROR_MAPPING_DRIVE   { Write-Host -foregroundcolor $COLOR_ERROR  "      + ERROR: Unable to map remote CIFS resource."   ; $SkipCurrentNode = $true }
          $ERROR_UNMAPPING_DRIVE { Write-Host -foregroundcolor $COLOR_ERROR  "      + ERROR: Unable to unmap remote CIFS resource." ; $SkipCurrentNode = $true }
        }
      }

      if ( !$SkipCurrentNode ) {
        $PackagesToInstall | ForEach-Object {
          $CurrentPackage          = $_
          $CurrentPackageName      = $_.Name
          $CurrentPackageShortName = $_.Name.Split('.')[0]
          $CurrentPackageExtension = $_.Extension

          Write-Host
          Write-Host -foregroundcolor $COLOR_RESULT "    + Current Package:     " $CurrentPackageName
          Write-Host

          switch ( $CurrentPackageExtension ) {
            ".exe" {
              switch ( $CurrentPackageName.Split('.')[0] ) {
                { $_ -like "*IExpress*" }      { DynX1_RunWinCmd_Microsoft_IExpressInstall    $SetConnectToHostByIP $NodeName $NodeIP "DynX_Windows_PackageInstall" $IsSupported $IsString }
                { $_ -like "*InnoSetup*" }     { DynX1_RunWinCmd_Windows_InnoSetupInstall     $SetConnectToHostByIP $NodeName $NodeIP "DynX_Windows_PackageInstall" $IsSupported $IsString }
                { $_ -like "*InstallShield*" } { DynX1_RunWinCmd_Windows_InstallShieldInstall $SetConnectToHostByIP $NodeName $NodeIP "DynX_Windows_PackageInstall" $IsSupported $IsString }
                { $_ -like "*NSIS*" }          { DynX1_RunWinCmd_Windows_NSISInstall          $SetConnectToHostByIP $NodeName $NodeIP "DynX_Windows_PackageInstall" $IsSupported $IsString }
                default                        { DynX1_RunWinCmd_Microsoft_SfxCabInstall      $SetConnectToHostByIP $NodeName $NodeIP "DynX_Windows_PackageInstall" $IsSupported $IsString }
              }
            }

            ".msi" {
              switch ( $CurrentPackageName.Split('.')[0] ) {
                { $_ -like "*InstallShield*" } { DynX1_RunWinCmd_Windows_InstallShieldInstall $SetConnectToHostByIP $NodeName $NodeIP "DynX_Windows_PackageInstall" $IsSupported $IsString }
                default                        { DynX1_RunWinCmd_Microsoft_MsiInstall         $SetConnectToHostByIP $NodeName $NodeIP "DynX_Windows_PackageInstall" $IsSupported $IsString }
              }
            }

            default {
              Write-Host -foregroundcolor $COLOR_DARK "    + INFO: Skipping Package. Unknown Package type."
            }
          }
        }


        Write-Host
        Write-Host -foregroundcolor $COLOR_RESULT -noNewLine "    + Clearing Remote Work Area... "

        if ( $test ) {
          Write-Host -foregroundcolor $COLOR_RESULT "done"
          Write-Host -foregroundcolor $COLOR_RESULT "      + Target: \\$TargetNode\c$"
        } else {
          $CleanStatus = CleanRemoteCIFSWorkArea $PackagesToInstall "\\$TargetNode\c$"

          Write-Host -foregroundcolor $COLOR_NORMAL "done"

          switch ( $CleanStatus ) {
            $ERROR_MAPPING_DRIVE   { Write-Host -foregroundcolor $COLOR_ERROR  "      + ERROR: Unable to map remote CIFS resource."   }
            $ERROR_UNMAPPING_DRIVE { Write-Host -foregroundcolor $COLOR_ERROR  "      + ERROR: Unable to unmap remote CIFS resource." }
            $ERROR_ITEM_NOTFOUND   { Write-Host -foregroundcolor $COLOR_ERROR  "      + ERROR: Could not find Remote Work Area." }
          }
        }
      } else {
        Write-Host
        . ReportModuleError "N/A" "INFO: Skipping Host. Problems uploading files to the Remote System."
      }
    } else {
      Write-Host
      . ReportModuleError "N/A" "INFO: Skipping Host. Unknown System Type."

    }
  } else {
    Write-Host
    . ReportModuleError "N/A" "INFO: Skipping Host. No Packages to Deploy."

  }


  . $ModulesDir\_CloseModuleContext.ps1
}