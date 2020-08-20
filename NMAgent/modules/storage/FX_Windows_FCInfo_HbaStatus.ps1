##############################################################################
# Module:  FX_Windows_FCInfo_HbaStatus
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Javier Ortiz de Saracho
#          Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################


# LibraryModules ::= {IsEnabled, IsSupportedByOpenSLIM, DataTypeIsString, 'ServiceTag', 'ModuleName', IsDaX, DependsOn}
$script:LibraryModules += @{ FX_Windows_FCInfo_HbaStatus = $true, $false, $false, 'System', 'FX_Windows_FCInfo_HbaStatus', $false, @(); }


function FX_Windows_FCInfo_HbaStatus([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $PropertyName, [bool] $IsSupported, [bool] $IsString) {
  . $ModulesDir\_SetModuleContext.ps1


  if ( $test ) {
    if ( $NeedCredentials ) {
      Write-Host -foregroundcolor $COLOR_RESULT "Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -namespace root\wmi -class MSFC_FCAdapterHBAAttributes -ErrorVariable NodeErrors -ErrorAction silentlycontinue"
    } else {
      Write-Host -foregroundcolor $COLOR_RESULT Get-WmiObject -ComputerName $TargetNode -namespace root\wmi -class MSFC_FCAdapterHBAAttributes -ErrorVariable NodeErrors -ErrorAction silentlycontinue
    }
  } else {
    if ( $NeedCredentials ) {
			# The script uses HBA WMI classes, these are only available if FCInfo has been installed on the server
			$hba   = $( Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -namespace "root\wmi" -class MSFC_FCAdapterHBAAttributes -ErrorVariable NodeErrors -ErrorAction silentlycontinue )

			# Use the HBA FibreChannel Port WMI class to get the port WWN
			$Ports = $( Get-WmiObject -ComputerName $TargetNode -Credential $NetworkCredentials -namespace "root\wmi" -class MSFC_FibrePortHBAAttributes -ErrorVariable NodeErrors -ErrorAction silentlycontinue )

    } else {
			# The script uses HBA WMI classes, these are only available if FCInfo has been installed on the server
			$hba   = $( Get-WmiObject -ComputerName $TargetNode -namespace "root\wmi" -class MSFC_FCAdapterHBAAttributes -ErrorVariable NodeErrors -ErrorAction silentlycontinue )

			# Use the HBA FibreChannel Port WMI class to get the port WWN
			$ports = $( Get-WmiObject -ComputerName $TargetNode -namespace "root\wmi" -class MSFC_FibrePortHBAAttributes -ErrorVariable NodeErrors -ErrorAction silentlycontinue )
	  }

    if ( $hba -eq $null ) {
      . ReportModuleError $hba "INFO: No HBA API or FCInfo installed."
    }	else {
      # We have Only one HBA
      if ( $hba.count -eq $null ) {
        # We need to match the ports to the HBA to give the right info, we use InstanceName as the key
        if ( $ports.instancename -eq $hba.instancename ) {
          # The PortWWN is a seperate object and returned as an 8 byte array
          [byte[]] $wwnarray = $ports.attributes.portwwn
          foreach ( $element in $wwnarray ) {
            # Each element is a hex number, so we convert to decimal and pad to 2 digits
            $wwn = $wwn + ("{0:x2}" -f $element) + ":"
          }

          $wwn = $wwn.trimend(":").ToUpper()
          if ( $hba.hbastatus -eq 0) { $status = "Up"     } else { $status = "Down"         }
          if ( $hba.active         ) { $active = "Active" } else { $active = "Disconnected" }

$WWNList += @"
Port-$($i):           $wwn - $active - $status
Manufacturer:     $( $hba.manufacturer )
Model:            $( $hba.model )
Driver Version:   $( $hba.driverversion )
Firmware Version: $( $hba.firmwareversion )
ROM Bios Version: $( $hba.OptionROMVersion )

"@

        }
			}


      # We have 2 HBA devices each with a port
      for ( $i = 0; $i -le $( $hba.Count - 1 ); $i++ ) {
        $wwn = ''

        # We have two ports in total per server
        foreach ( $port in $ports ) {
          # We need to match the ports to the HBA to give the right info, we use InstanceName as the key
          if ( $port.instancename -eq ($hba[$i]).instancename ) {
            # The PortWWN is a seperate object and returned as an 8 byte array
            [byte[]] $wwnarray = $port.attributes.portwwn
            foreach ($element in $wwnarray) {
              # Each element is a hex number, so we convert to decimal and pad to 2 digits
              $wwn = $wwn + ("{0:x2}" -f $element) + ":"
            }

            $wwn = $wwn.trimend(":").ToUpper()
            if ( $( $hba[$i] ).hbastatus -eq 0 ) { $status = "Up"   } else { $status="Down"         }
            if ( $( $hba[$i] ).active          ) { $active="Active" } else { $active="Disconnected" }

$WWNList += @"
Port-$($i):           $wwn - $active - $status
Manufacturer:     $( $hba[$i].manufacturer )
Model:            $( $hba[$i].model )
Driver Version:   $( $hba[$i].driverversion )
Firmware Version: $( $hba[$i].firmwareversion )
ROM Bios Version: $( $hba[$i].OptionROMVersion )

"@

          }
        }
      }


      if ( $ports -ne $null ) {
        $ErrorFound  = -not $?
        $ErrorText   = $( $NodeErrors | Format-List -force * | Out-String )
        $RawOutput   = $( $WWNList | Out-String )
        $ResultValue = $WWNList

        Write-Host -foregroundcolor $COLOR_RESULT "    + Discovered Information:"
        Write-Host

        $OriginalColor = $host.UI.RawUI.ForegroundColor
        $host.UI.RawUI.ForegroundColor = $COLOR_RESULT

        $ResultValue

        $host.UI.RawUI.ForegroundColor = $OriginalColor
      } else {
        . ReportModuleError $ports "ERROR: unable to retrieve any information."
      }
    }


    . $ModulesDir\_CloseModuleContext.ps1
  }
}
