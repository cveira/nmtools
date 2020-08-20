##############################################################################
# Module:  PLEX_Windows_ReplaceWinsResolvers.ps1
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependensOn}
$script:LibraryModules += @{ PLEX_Windows_ReplaceWinsResolvers = $true,  $false, $true, 'System', 'PLEX_Windows_ReplaceWinsResolvers', $true, @( 'FX_Windows_GetPrimaryDnsResolver', 'FX_Windows_GetSecondaryDnsResolver' ); }


function PLEX_Windows_ReplaceWinsResolvers([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  $PRIMARY_WINS_SERVER   = 0
  $SECONDARY_WINS_SERVER = 1

  if ( $test ) {
    if ( $NeedCredentials ) {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -Class Win32_NetworkAdapterConfiguration -filter IPEnabled=TRUE -ErrorVariable NodeErrors -ErrorAction continue"
    } else {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -Class Win32_NetworkAdapterConfiguration -filter IPEnabled=TRUE -ComputerName $TargetNode -Credential $NetworkCredentials -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    }
  } else {
    if ( !$PipelineInput ) {
      DisplayPlexHelp "<WinsPrimaryResolverIP, WinsSecondaryResolverIP>"
      break
    }


    $ErrorDetected =  $false
    $ChangedOk     =  $null

    $PipelineInput =  $PipelineInput.Split($PLEX_INPUT_DELIMITER)
    $WinsCleanList =  @()
    $PipelineInput | ForEach-Object { $WinsCleanList += $_.Trim() }


    $NodeNics      =  @()
    $NodeNics      += $( $SStoreDT | Where-Object { ( $_.NodeName -eq $NodeName ) -and ( $_.NodeExtendedAttributes -ne "" ) } | Select-Object NodeExtendedAttributes -unique ).NodeExtendedAttributes

    if ( $NodeNics -ne $null ) {
      $NodeNics | ForEach-Object {
        $ChangedOk   = $null
        $SelectedNIC = $_.Split($DAX_VALUE_DELIMITER)[$DAX_PROPERTY_VALUE]

        if ( $NeedCredentials ) {
          $ChangedOk = $( Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -Class Win32_NetworkAdapterConfiguration -filter "IPEnabled=TRUE and Index=$SelectedNIC" -ErrorVariable NodeErrors -ErrorAction continue ).SetWINSServer( $WinsCleanList[$PRIMARY_WINS_SERVER], $WinsCleanList[$SECONDARY_WINS_SERVER] )
        } else {
          $ChangedOk = $( Get-WmiObject -ComputerName $TargetNode -Class Win32_NetworkAdapterConfiguration -filter "IPEnabled=TRUE and Index=$SelectedNIC" -ErrorVariable NodeErrors -ErrorAction continue ).SetWINSServer( $WinsCleanList[$PRIMARY_WINS_SERVER], $WinsCleanList[$SECONDARY_WINS_SERVER] )
        }

        if ( !$ErrorDetected -and ( $ChangedOk -eq $null ) ) { $ErrorDetected = $true }
      }


      if ( !$ErrorDetected ) {
        $ErrorFound  = $false
        $ErrorText   = $( $NodeErrors  | Format-List * -force | Out-String )
        $RawOutput   = $( $WinsCleanList | Out-String ).Trim() + "`n`n" + $( $NodeNics | Out-String ).Trim()
        $ResultValue = "SUCCESS"

        Write-Host -foregroundcolor $COLOR_RESULT "    + SetWinsResolvers:    " $ResultValue
        Write-Host
      } else {
        $ErrorFound  = $true
        $ErrorText   = $( $NodeErrors  | Format-List -force * | Out-String )
        $RawOutput   = $( $WinsCleanList | Out-String ).Trim() + "`n`n" + $( $NodeNics | Out-String ).Trim()
        $ResultValue = "FAILURE"

        Write-Host -foregroundcolor $COLOR_RESULT -noNewLine "    + SetWinsResolvers:     "
        Write-Host -foregroundcolor $COLOR_ERROR $ResultValue
        Write-Host

        $NodeName >> $FailedNodesFile
      }
    } else {
      . ReportModuleError $WinsCleanList "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}