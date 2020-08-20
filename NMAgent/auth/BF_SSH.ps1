##############################################################################
# Module:  BF_SSH
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################

function BF_SSH([bool] $SetConnectToHostByIP, [string] $ClearTextUserName, [string] $ClearTextPassword) {
  # $PuTTYOpts       = "-ssh -telnet -rlogin -raw -batch -noagent -C -i key -v {-t|-T} {-1|-2} {-4|-6} -m file -s"
  $PuTTYOpts        = "-ssh -batch -noagent -P 22 -2 -4 -C"
  $PuTTYCmd         = "`"id`""
  # $PuTTYPayLoad    = "`"<PutYourRemoteCommandHere>`""
  $PuTTYPayLoad     = ""


  $SUCCESS_EXITCODE = 0
  $FAILED_EXITCODE  = -1
  $SavedExitCode    = $SUCCESS_EXITCODE
  $FoundUserId      = $false

  if ( $SetConnectToHostByIP ) {
    $RunCmd         = "$BinDir\plink.exe -l $ClearTextUserName -pw $ClearTextPassword $PuTTYOpts $NodeIP $PuTTYCmd $PuTTYPayLoad"
  } else {
    $RunCmd         = "$BinDir\plink.exe -l $ClearTextUserName -pw $ClearTextPassword $PuTTYOpts $NodeName $PuTTYCmd $PuTTYPayLoad"
  }

  trap { $NodeData = $null; $SavedExitCode  = $FAILED_EXITCODE; continue }

  $NodeData         = Invoke-Expression $RunCmd
  $SavedExitCode    = $LASTEXITCODE

  if ( ( $SavedExitCode -eq $SUCCESS_EXITCODE ) -and ( $RunCmd -ne $null ) ) {
    $FoundUserId    = $true
  }

  $FoundUserId
}