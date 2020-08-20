##############################################################################
# Module:  PLEX_VMWare_GetDataStorageUsage
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Alberto Ruiz-Zorrilla
#          Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ PLEX_VMWare_GetDataStorageUsage = $true, $false, $true, 'System', 'PLEX_VMWare_GetDataStorageUsage', $false, @(); }


function PLEX_VMWare_GetDataStorageUsage([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  if ( $test ) {
    Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class Win32_ComputerSystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
  } else {
    if ( !$PipelineInput ) {
      DisplayPlexHelp "<FolderName>"
      break
    }


	  $DiskSizeKB = 0
	  $RAMSizeMB  = 0

    if ( ExistFolder $PipeLineInput ) {
      $VMList   =  Get-VM -location $( Get-Folder -name $PipeLineInput )

      Get-HardDisk -vm $VMList | ForEach-Object { $DiskSizeKB += $_.CapacityKB }
      Get-VM $VMList | ForEach-Object { $RAMSizeMB += $_.MemoryMB }

      $DiskSizeMB         = $DiskSizeKB / 1024
      $TotalDiskUsageGB = $( $DiskSizeMB + $RAMSizeMB ) / 1024


      $ErrorFound  = $false
      $ErrorText   = $( $NodeErrors | Format-List -force * | Out-String )
      $RawOutput   = "FolderName: $PipeLineInput`r`nTotalDiskUsageGB: $TotalDiskUsageGB"
      $ResultValue = "$TotalDiskUsageGB"

      Write-Host -foregroundcolor $COLOR_RESULT "    + VMs in Folder:       " $PipeLineInput
      Write-Host -foregroundcolor $COLOR_RESULT "    + Total VMs Found:     " $VMList.count
      Write-Host -foregroundcolor $COLOR_RESULT "    + Total VMs Disk usage:" $TotalDiskUsageGB "GB"
      Write-Host -foregroundcolor $COLOR_RESULT "    + Total VMs RAM usage: " $( $RAMSizeMB / 1024 ) "GB"
      Write-Host

      . SetConsoleResultTheme

      $VMList | Format-Table Name -autosize

      . RestoreConsoleDefaultTheme
    } else {
      . ReportModuleError $VMList "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}
