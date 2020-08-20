##############################################################################
# Module:  FX_DSGridServer_WinAgent_GetTotalLogSize
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Alberto Ruiz Zorrilla - sakery [at] yahoo [dot] com
#          Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ FX_DSGridServer_WinAgent_GetTotalLogSize = $true, $false, $true, 'System', 'FX_DSGridServer_WinAgent_GetTotalLogSize', $false, @(); }


function FX_DSGridServer_WinAgent_GetTotalLogSize([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  $TotalFileSize   = 0
	$RemotePath      = "'\\Program Files\\DataSynapse\\Engine\\work\\$($TargetNode.Split('.')[0])-0\\log\\'"
	$RemoteDrive     = "'C:'"
	$RemoteExtension = "'log'"

  $RemoteQuery     = "SELECT FileSize FROM CIM_DataFile WHERE Drive = $RemoteDrive AND Extension = $RemoteExtension AND Path = $RemotePath"

  if ( $test ) {
    if ( $NeedCredentials ) {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -Query $RemoteQuery -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    } else {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -Query $RemoteQuery -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    }
  } else {
    if ( $NeedCredentials ) {
      $NodeData = Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -Query $RemoteQuery -ErrorVariable NodeErrors -ErrorAction silentlycontinue
    } else {
      $NodeData = Get-WmiObject -ComputerName $TargetNode -Query $RemoteQuery -ErrorVariable NodeErrors -ErrorAction silentlycontinue
    }

    if ( $NodeData -ne $null ) {
      $ErrorFound  = -not $?
      $ErrorText   = $($NodeErrors | Format-List -force * | Out-String)
      $RawOutput   = $NodeData

      $NodeData | ForEach-Object { $TotalFileSize += $_.FileSize }

      [int] $ResultValue = $TotalFileSize / $ToKB

      Write-Host -foregroundcolor $COLOR_RESULT "    + TotalFileSize:       " $ResultValue "KB"
    } else {
      . ReportModuleError $NodeData "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}