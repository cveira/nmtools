##############################################################################
# Module:  BF_Windows
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################

function BF_Windows([bool] $SetConnectToHostByIP, [string] $ClearTextUserName, [string] $ClearTextPassword) {
  $FoundWindowsId        = $false

  if ( $CredentialsDbIsEncrypted ) {
    $NodeConnectionUser     = $ClearTextUserName
    $NodeConnectionPassword = $ClearTextPassword | ConvertTo-SecureString
  } else {
    $NodeConnectionUser     = $ClearTextUserName
    $NodeConnectionPassword = $ClearTextPassword | ConvertTo-SecureString -AsPlainText -force
  }

  $NetworkCredentials       = New-Object System.Management.Automation.PsCredential $NodeConnectionUser, $NodeConnectionPassword

  Write-Host -foregroundcolor $COLOR_DARK   "      + BF Module:          Windows Native Authentication"

   if ( $SetConnectToHostByIP ) {
    trap { $NodeData = $null; continue }

    $NodeData = Get-WmiObject -ComputerName $NodeIP   -Credential $NetworkCredentials -class win32_computersystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue
  } else {
    trap { $NodeData = $null; continue }

    $NodeData = Get-WmiObject -ComputerName $NodeName -Credential $NetworkCredentials -class win32_computersystem -ErrorVariable NodeErrors -ErrorAction silentlycontinue
  }

  if ( $NodeData -ne $null ) {
    $FoundWindowsId  = $true
  }

  $FoundWindowsId
}