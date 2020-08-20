if ( $SetConnectToHostByIP ) {
  $TargetNode    = $TargetIP
} else {
  $TargetNode    = $TargetName
}


$NeedCredentials = $false
if ( $NodeName -ne $( Get-WmiObject -Class Win32_ComputerSystem).Name ) { $NeedCredentials = $true }

if ( $MultiCredentialMode ) {
  if ( $NodeCredentials.ContainsKey($TargetNode) ) {
    if ( $CredentialsDbIsEncrypted ) {
      $NodeConnectionUser     = $NodeCredentials.$($TargetNode)[$NodeCredentials_NodeUser]
      $NodeConnectionPassword = $NodeCredentials.$($TargetNode)[$NodeCredentials_NodePassword]     | ConvertTo-SecureString
    } else {
      $NodeConnectionUser     = $NodeCredentials.$($TargetNode)[$NodeCredentials_NodeUser]
      $NodeConnectionPassword = $NodeCredentials.$($TargetNode)[$NodeCredentials_NodePassword]     | ConvertTo-SecureString -AsPlainText -force
    }
  } else {
    if ( $CredentialsDbIsEncrypted ) {
      $NodeConnectionUser     = $NodeCredentials.DefaultCredentials[$NodeCredentials_NodeUser]
      $NodeConnectionPassword = $NodeCredentials.DefaultCredentials[$NodeCredentials_NodePassword] | ConvertTo-SecureString
    } else {
      $NodeConnectionUser     = $NodeCredentials.DefaultCredentials[$NodeCredentials_NodeUser]
      $NodeConnectionPassword = $NodeCredentials.DefaultCredentials[$NodeCredentials_NodePassword] | ConvertTo-SecureString -AsPlainText -force
    }
  }

  $NetworkCredentials  = New-Object System.Management.Automation.PsCredential $NodeConnectionUser, $NodeConnectionPassword
}