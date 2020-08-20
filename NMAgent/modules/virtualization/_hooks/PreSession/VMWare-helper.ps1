function ExistVM([string] $VMName) {
	Get-VM | Foreach-Object { $FullVMList += $_.Name }

	if ( $FullVMList.Contains( $VMName ) ) {
    $true
  } else {
    $false
  }
}

##############################################################################

function ExistDS([string] $DSName) {
	Get-DataStore | Foreach-Object { $FullDSList += $_.Name }

	if ( $FullDSList.Contains( $DSName ) ) {
    $true
  } else {
    $false
  }
}

##############################################################################

function ExistSnapShot([string] $VMName, [string] $SSName) {
	$SnapShot = Get-Snapshot -VM $( Get-VM -Name $VMName ) -Name $SSName

	if ( $SnapShot -ne $null ) {
    $true
  } else {
    $false
  }
}

##############################################################################

function VMIsPoweredOn([string] $VMName) {
	$PowerStatus = Get-VM $VMName | Select-Object PowerState

	if ( $PowerStatus.PowerState -eq "PoweredOn" ) {
    $true
  } else {
    $false
  }
}

##############################################################################

function ExistFolder([string] $FolderName) {
	Get-Folder | ForEach-Object { $FolderList += $_.Name }

	if ( $FolderList.Contains( $FolderName ) ) {
    $true
  } else {
    $false
  }
}
