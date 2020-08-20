###############################################################################
# NOTE:  If you plan to ENCRYPT your passwords with EncryptCredentials.ps1
#        (it is a highly recommended practice) scape any special character
#        on it with a back slash ("\") whenever it could be interpreted as a
#        .NET RegExp special Char.
###############################################################################


param (
  [string]$ProfileName
)

$NodeCredentials_NodePassword = 2

 . .\auth\_settings\credentials.ps1

[string[]] $NodeCredentialsKeys = ($NodeCredentials.Keys | Sort-Object)

$CredentialsDb = Get-Content .\auth\_settings\credentials.ps1 | out-string

for ($i=0; $i -lt $NodeCredentialsKeys.Length; $i++) {
  $CurrentPassword = $NodeCredentials.$($NodeCredentialsKeys[$i])[$NodeCredentials_NodePassword]
  $SecuredPassword = ConvertTo-SecureString $("$CurrentPassword" -replace "\\","") -AsPlainText -force | ConvertFrom-SecureString

  $CredentialsDb   = $($CredentialsDb -replace $("$CurrentPassword" -replace "\\","\\\"), $SecuredPassword)
}

$CredentialsDb > .\auth\_settings\credentials-encrypted.ps1