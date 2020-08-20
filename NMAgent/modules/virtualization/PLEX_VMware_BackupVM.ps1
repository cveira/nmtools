##############################################################################
# Module:  PLEX_VMware_BackupVM
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Alberto Ruiz-Zorrilla
#          Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ PLEX_VMware_BackupVM = $true, $false, $true, 'System', 'PLEX_VMware_BackupVM', $false, @(); }


function PLEX_VMware_BackupVM([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  $PLEX_PARAMETER_SOURCEVM = 0
  $PLEX_PARAMETER_TARGETDS = 1
  $BACKUP_TARGET_FOLDER    = "Backup"

  if ( $test ) {
      Write-Host "no Test Command for this Module"
  } else {
    if ( !$PipelineInput ) {
      DisplayPlexHelp "<VirtualMachineName>, <DataStorageName>"
      break
    } else {
      $SourceVM = $PipeLineInput.Split(',')[ $PLEX_PARAMETER_SOURCEVM ]
      $TargetDS = $PipeLineInput.Split(',')[ $PLEX_PARAMETER_TARGETDS ]
    }


    if ( ExistVM( $SourceVM ) -and ExistDS( $TargetDS ) ) {
      $VM                 = Get-VM $SourceVM

      Write-Host -foregroundcolor $COLOR_RESULT "    + Creating SnapShot:   " $SourceVM

      $CloneSnap          = $VM | New-SnapShot -Name "$LogSessionId-$SourceVM-CloneSnapShot"
      $VMView             = $VM | Get-View

# $host.EnterNestedPrompt()
      
      $CloneFolder        = $VMView.Parent
      $CloneSpec          = New-Object Vmware.Vim.VirtualMachineCloneSpec
      $CloneSpec.Snapshot = $VMView.Snapshot.CurrentSnapshot

      $CloneSpec.Location           = New-Object Vmware.Vim.VirtualMachineRelocateSpec
      $CloneSpec.Location.Datastore = $( Get-Datastore -Name $TargetDS | Get-View ).MoRef
      $CloneSpec.Location.Transform = [Vmware.Vim.VirtualMachineRelocateTransformation]::Sparse

      $CloneName                    = "$VM-$LogSessionId-BAK"

      Write-Host -foregroundcolor $COLOR_RESULT "    + Cloning:             " $SourceVM "into" $CloneName

      $VMView.CloneVM( $CloneFolder, $CloneName, $CloneSpec ) | Out-Null

      Write-Host -foregroundcolor $COLOR_RESULT "    + Moving to Folder:    " $BACKUP_TARGET_FOLDER

      Move-VM $CloneName -Destination $BACKUP_TARGET_FOLDER | Out-Null
      Get-VM $CloneName | Out-Null

      Write-Host -foregroundcolor $COLOR_RESULT "    + Deleting SnapShot:   "

      Get-Snapshot -VM $( Get-VM -Name $VM ) -Name $CloneSnap | Remove-Snapshot -confirm:$false

      if ( ExistVM( $CloneName ) ) {
        $ErrorFound  = $false
        $ErrorText   = $( $NodeErrors | Format-List -force * | Out-String )
        $RawOutput   = "$SourceVM Backed Up into $CloneName"
        $ResultValue = "SUCCESS"

        Write-Host -ForegroundColor $COLOR_RESULT "    + $SourceVM has been Cloned into $CloneName "
      } else {
        $ErrorFound  = $false
        $ErrorText   = $( $NodeErrors | Format-List -force * | Out-String )
        $RawOutput   = "Couldn't Back Up $SourceVM into $CloneName"
        $ResultValue = "FAILURE"

        Write-Host -foregroundcolor $COLOR_ERROR "    + ERROR: $SourceVM couldn't be Backed Up!"
        $NodeName >> $FailedNodesFile
      }
    } else {
      . ReportModuleError $SourceVM "ERROR: Either VirtualMachine ($SourceVM) or DataStore ($TargetDS) don't exist!"
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}


