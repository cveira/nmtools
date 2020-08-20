##############################################################################
# Module:  FX_DSGridServer_WinAgent_GetDirTotalLogSize
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
#          Alberto Ruiz Zorrilla - sakery [at] yahoo [dot] com
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ FX_DSGridServer_WinAgent_GetDirTotalLogSize = $true, $false, $true, 'System', 'FX_DSGridServer_WinAgent_GetDirTotalLogSize', $false, @(); }


function FX_DSGridServer_WinAgent_GetDirTotalLogSize([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  $TotalFileSize     = 0
	$RemoteRootPath    = "'\\Program Files\\DataSynapse\\Engine\\work\\'"
	$CurrentTargetPath = ""
	$RemoteDrive       = "'C:'"
	$RemoteExtension   = "'log'"

  $RemoteDirQuery    = "SELECT FileName FROM Win32_Directory WHERE Drive = $RemoteDrive AND Path = $RemoteRootPath"
  $RemoteFileQuery   = {"SELECT FileSize FROM CIM_DataFile WHERE Drive = $RemoteDrive AND Extension = $RemoteExtension AND Path = $CurrentTargetPath"}


  function GetDirList([string] $RemoteDrive = "'C:'", [string] $RemoteRootPath = "'\\Program Files\\DataSynapse\\Engine\\work\\'") {
    if ( $NeedCredentials ) {
      $NodeData = Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -Query $RemoteDirQuery -ErrorVariable NodeErrors -ErrorAction silentlycontinue
    } else {
      $NodeData = Get-WmiObject -ComputerName $TargetNode -Query $RemoteDirQuery -ErrorVariable NodeErrors -ErrorAction silentlycontinue
    }

    if ( $NodeData -ne $null ) {
      $NodeData | Select-Object FileName
    } else {
      $null
    }
  }


  if ( $test ) {
    if ( $NeedCredentials ) {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -Query $(. $RemoteFileQuery) -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    } else {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -Query $(. $RemoteFileQuery) -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    }
  } else {
    $RemoteDirList = GetDirList $RemoteDrive $RemoteRootPath

    if ( $null -ne $RemoteDirList ) {
      Write-Host -foregroundcolor $COLOR_DARK "    + INFO: Total Remote Directories: $($RemoteDirList.Length)"

      foreach ($CurrentDir in $RemoteDirList) {
        $CurrentTargetPath = "'\\Program Files\\DataSynapse\\Engine\\work\\$($CurrentDir.FileName)\\log\\'"
        $CurrentFileQuery  = . $RemoteFileQuery

        if ( $NeedCredentials ) {
          $NodeData = Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -Query $CurrentFileQuery -ErrorVariable NodeErrors -ErrorAction silentlycontinue
        } else {
          $NodeData = Get-WmiObject -ComputerName $TargetNode -Query $CurrentFileQuery -ErrorVariable NodeErrors -ErrorAction silentlycontinue
        }

        if ( $NodeData -ne $null ) {
          $ErrorFound  =  -not $?
          $ErrorText   =  $($NodeErrors | Format-List -force * | Out-String)
          $RawOutput   += $($NodeData | Format-Table | Out-String)

          $NodeData | ForEach-Object { $TotalFileSize += $_.FileSize }
        } else {
          Write-Host -foregroundcolor $COLOR_NORMAL "    + WARNING: unable to retrieve information from Remote Directory: $($CurrentDir.FileName)"
        }
      }

      [int] $ResultValue = $TotalFileSize / $ToKB

      Write-Host -foregroundcolor $COLOR_RESULT "    + TotalFileSize:       " $ResultValue "KB"
    } else {
      . ReportModuleError $NodeData "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}