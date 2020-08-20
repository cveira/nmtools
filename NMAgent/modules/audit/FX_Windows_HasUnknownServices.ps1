##############################################################################
# Module:  FX_Windows_HasUnknownServices
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ FX_Windows_HasUnknownServices = $true, $false, $true, 'System', 'FX_Windows_HasUnknownServices', $false, @(); }


function FX_Windows_HasUnknownServices([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  if ( $test ) {
    if ( $NeedCredentials ) {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class win32_service -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    } else {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -class win32_service -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    }
  } else {
    if ( $NeedCredentials ) {
      $NodeData = Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -class win32_service -ErrorVariable NodeErrors -ErrorAction silentlycontinue
    } else {
      $NodeData = Get-WmiObject -ComputerName $TargetNode -class win32_service -ErrorVariable NodeErrors -ErrorAction silentlycontinue
    }

    if ( $NodeData -ne $null ) {
      $SelectedServices = $NodeData | Where-Object { $_.Name -ne $null }

      [string[]] $ServiceWhiteList = @()

      Get-ChildItem $ModulesDir\$SX_ServiceWhiteListShortPath\*.txt -exclude _* | ForEach-Object {
        $ServiceWhiteList += Get-Content $_
      }

      $ServiceWhiteList            = $ServiceWhiteList | ForEach-Object { if ( $_ -ne "" ) { $_.Trim() } }
      $ServiceWhiteList            = $ServiceWhiteList | Select-String "#" -NotMatch
      $ServiceWhiteList            = $ServiceWhiteList | Select-Object -unique

      [string[]] $TargetServices   = @()
      $SelectedServices | ForEach-Object { $TargetServices += "$($_.Name.Trim())" }
      $TargetServices              = $TargetServices | Select-Object -unique

      $ResultValue  = Compare-Object $ServiceWhiteList $TargetServices | Where-Object { $_.SideIndicator -eq "=>" } | Select-Object InputObject

      if ( $ResultValue -ne $null ) {
        $HasUnknownServices = "YES"
      } else {
        $HasUnknownServices = "NO"
      }

      $ErrorFound   = $false
      $ErrorText    = $( $NodeErrors | Format-List -force * | Out-String )
      $RawOutput    = $( $ResultValue | Out-String ).Trim()
      $ResultValue  = $HasUnknownServices

      Write-Host -foregroundcolor $COLOR_RESULT "    + HasUnknownServices:  " $HasUnknownServices
    } else {
      . ReportModuleError $NodeData "ERROR: unable to retrieve any information."
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}