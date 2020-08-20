function SaveNodeData([string] $NodeName, [string] $NodeIP, [string] $PropertyName, [string] $AttributeName, [string] $ExtendedAttributes, [bool] $PropertyIsSupported, [bool] $ErrorFound, [string] $ErrorText, [bool] $ValueIsString, $Value, [string] $RawOutput) {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentSaveDataErrorEvent = @"

===========================================================================================
$(get-date -format u) - Data Persistance Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())
-------------------------------------------------------------------------------------------
CurrentNode:        $NodeName - $NodeIP
SStorePropertyName: $PropertyName
SStorePropertyName: $AttributeName
SStoreIsSupported:  $PropertyIsSupported
SStoreIsString:     $ValueIsString
SStoreValue:        $Value
SStoreRawOutput:    $RawOutput

ErrorFound:         $ErrorFound
ErrorText:          $ErrorText

+ Added Records:

$( if ($SStoreDS.GetChanges("Added").Tables -ne $null) { $($SStoreDS.GetChanges("Added").Tables[0] | Format-Table RecordId, NodeName  -autosize | Out-String).Trim() } )

"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  + SaveNodeData Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentSaveDataErrorEvent >> $ErrorLogFile

    # $NMAgentDb.Close()

    break
  }


  function ValueObjectIsOk {
    $IsOk               = $false
    $DetectedProperties = 0

    $( $Value | Get-Member | Select-Object Name ) | ForEach-Object {
      if ( $_.Name -eq "AttributeName" )      { $DetectedProperties++ }
      if ( $_.Name -eq "ExtendedAttributes" ) { $DetectedProperties++ }
      if ( $_.Name -eq "Value" )              { $DetectedProperties++ }
    }

    if ( $DetectedProperties -eq 3 ) { $IsOk = $true }

    $IsOk
  }


  if ( $Value -is [array] ) {
    if ( ValueObjectIsOk ) {
      $Value | ForEach-Object {
        $NewItem                         = $SStoreDT.NewRow()

        $NewItem.RecordId                = $NodeIdCollisionOffSet
        $NewItem.RecordDate              = $(Get-Date).ToUniversalTime()

        $NewItem.SessionId               = $SessionId
        $NewItem.AgentUserId             = $script:AgentUserId
        $NewItem.AgentUserName           = $script:AgentUserName
        $NewItem.AgentNodeName           = $AgentNodeName

        if ($NodeName -eq $UNKNOWN_HOSTNAME) {
          $NewItem.NodeName              = $NodeName + "_" + $SessionId
        } else {
          $NewItem.NodeName              = $NodeName
        }

        $NewItem.NodeIP                  = $NodeIP

        $NewItem.NodePropertyIsSupported = $PropertyIsSupported
        $NewItem.NodePropertyName        = $PropertyName

        $NewItem.NodeAttributeName       = $( $_.AttributeName      | Out-String ).Trim()
        $NewItem.NodeExtendedAttributes  = $( $_.ExtendedAttributes | Out-String ).Trim()

        $NewItem.ErrorFound              = $ErrorFound
        $NewItem.ErrorText               = $ErrorText

        $NewItem.NodeQueryOutput         = $RawOutput

        if ( $ValueIsString ) {
          $NewItem.NodeValue             = $( $_.Value | Out-String ).Trim()
        } else {
          $NewItem.NodeValue_Memo        = $( $_.Value | Out-String ).Trim()
        }

        $SStoreDT.Rows.Add($NewItem)

        if ( $save ) {
          if ($SStoreDS.HasChanges("Added")) {
            $NewItemsAtSStoreDS = $SStoreDS.GetChanges("Added")

            if ($NewItemsAtSStoreDS -ne $null) {
              if (-not $NewItemsAtSStoreDS.HasErrors) {
                [void] $SStoreDA.Update($NewItemsAtSStoreDS)
                $SStoreDS.AcceptChanges()
              } else {
                $SStoreDS.RejectChanges()
              }
            } else {
              Write-Host -foregroundcolor $COLOR_ERROR "  # SaveNodeData:              NO changes in data were detected and NO change has been persisted."
            }
          }
        }
      }
    } else {
      Write-Host -foregroundcolor $COLOR_ERROR "  # SaveNodeData:              The information has an incorrect format. Nothing has been persisted."
    }
  } else {
    if ( $Value -is [PSCustomObject] ) {
      if ( ValueObjectIsOk ) {
        $NewItem                         = $SStoreDT.NewRow()

        $NewItem.RecordId                = $NodeIdCollisionOffSet
        $NewItem.RecordDate              = $(Get-Date).ToUniversalTime()

        $NewItem.SessionId               = $SessionId
        $NewItem.AgentUserId             = $script:AgentUserId
        $NewItem.AgentUserName           = $script:AgentUserName
        $NewItem.AgentNodeName           = $AgentNodeName

        if ($NodeName -eq $UNKNOWN_HOSTNAME) {
          $NewItem.NodeName              = $NodeName + "_" + $SessionId
        } else {
          $NewItem.NodeName              = $NodeName
        }

        $NewItem.NodeIP                  = $NodeIP

        $NewItem.NodePropertyIsSupported = $PropertyIsSupported
        $NewItem.NodePropertyName        = $PropertyName
        $NewItem.NodeAttributeName       = $Value.AttributeName
        $NewItem.NodeExtendedAttributes  = $Value.ExtendedAttributes

        $NewItem.ErrorFound              = $ErrorFound
        $NewItem.ErrorText               = $ErrorText

        $NewItem.NodeQueryOutput         = $RawOutput

        if ( $ValueIsString ) {
          $NewItem.NodeValue             = $Value.Value
        } else {
          $NewItem.NodeValue_Memo        = $Value.Value
        }

        $SStoreDT.Rows.Add($NewItem)

        if ( $save ) {
          if ($SStoreDS.HasChanges("Added")) {
            $NewItemsAtSStoreDS = $SStoreDS.GetChanges("Added")

            if ($NewItemsAtSStoreDS -ne $null) {
              if (-not $NewItemsAtSStoreDS.HasErrors) {
                [void] $SStoreDA.Update($NewItemsAtSStoreDS)
                $SStoreDS.AcceptChanges()
              } else {
                $SStoreDS.RejectChanges()
              }
            } else {
              Write-Host -foregroundcolor $COLOR_ERROR "  # SaveNodeData:              NO changes in data were detected and NO change has been persisted."
            }
          }
        }
      } else {
        Write-Host -foregroundcolor $COLOR_ERROR "  # SaveNodeData:              The information has an incorrect format. Nothing has been persisted."
      }
    } else {
      $NewItem                         = $SStoreDT.NewRow()

      $NewItem.RecordId                = $NodeIdCollisionOffSet
      $NewItem.RecordDate              = $(Get-Date).ToUniversalTime()

      $NewItem.SessionId               = $SessionId
      $NewItem.AgentUserId             = $script:AgentUserId
      $NewItem.AgentUserName           = $script:AgentUserName
      $NewItem.AgentNodeName           = $AgentNodeName

      if ($NodeName -eq $UNKNOWN_HOSTNAME) {
        $NewItem.NodeName              = $NodeName + "_" + $SessionId
      } else {
        $NewItem.NodeName              = $NodeName
      }

      $NewItem.NodeIP                  = $NodeIP

      $NewItem.NodePropertyIsSupported = $PropertyIsSupported
      $NewItem.NodePropertyName        = $PropertyName
      $NewItem.NodeAttributeName       = $AttributeName
      $NewItem.NodeExtendedAttributes  = $ExtendedAttributes

      $NewItem.ErrorFound              = $ErrorFound
      $NewItem.ErrorText               = $ErrorText

      $NewItem.NodeQueryOutput         = $RawOutput

      if ( $ValueIsString ) {
        $NewItem.NodeValue             = $Value
      } else {
        $NewItem.NodeValue_Memo        = $Value
      }

      $SStoreDT.Rows.Add($NewItem)

      if ( $save ) {
        if ($SStoreDS.HasChanges("Added")) {
          $NewItemsAtSStoreDS = $SStoreDS.GetChanges("Added")

          if ($NewItemsAtSStoreDS -ne $null) {
            if (-not $NewItemsAtSStoreDS.HasErrors) {
              [void] $SStoreDA.Update($NewItemsAtSStoreDS)
              $SStoreDS.AcceptChanges()
            } else {
              $SStoreDS.RejectChanges()
            }
          } else {
            Write-Host -foregroundcolor $COLOR_ERROR "  # SaveNodeData:              NO changes in data were detected and NO change has been persisted."
          }
        }
      }
    }
  }
}

##############################################################################

function GetTargetIdentity([bool] $SetConnectToHostByIP, [string] $NodeName, [string] $NodeIP, [string] $ServiceTag) {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentGetTargetIdentityErrorEvent = @"

===========================================================================================
$(get-date -format u) - GetTargetIdentity Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())
-------------------------------------------------------------------------------------------
SetConnectToHostByIP: $SetConnectToHostByIP
NodeName:             $NodeName
NodeIP:               $TargetIP
ServiceTag:           $ServiceTag

"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  + GetTargetIdentity Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentGetTargetIdentityErrorEvent >> $ErrorLogFile

    [string] $NodeIdentity = ""
    return $NodeIdentity
}


  [string] $NodeIdentity = ""
  $FoundWindowsId        = $false
  $FoundOtherId          = $false
  $ServiceTagMisMatch    = $false

  Write-Host -foregroundcolor $COLOR_NORMAL   "  + Launching Network Identity Discovery Process:"

  :IdentityLookup foreach ($CurrentId in $NodeCredentialsKeys) {
    Write-Host -foregroundcolor $COLOR_DARK   "    + Trying Password for:  User ["  $NodeCredentials.$($CurrentId)[$NodeCredentials_NodeUser] "]"
    Write-Host

    if ( ( $($NodeCredentials.$($CurrentId)[$NodeCredentials_NodePassword]).length -ne 0     ) -and
         ( $NodeCredentials.$($CurrentId)[$NodeCredentials_NodePassword]           -ne $null ) ) {

      if ( $PerHostBFLogin -or ( $ServiceTag -eq $SystemServiceTag ) ) {
        if ( $CredentialsDbIsEncrypted ) {
          $NodeConnectionUser     = $NodeCredentials.$($CurrentId)[$NodeCredentials_NodeUser]
          $NodeConnectionPassword = $NodeCredentials.$($CurrentId)[$NodeCredentials_NodePassword] | ConvertTo-SecureString
        } else {
          $NodeConnectionUser     = $NodeCredentials.$($CurrentId)[$NodeCredentials_NodeUser]
          $NodeConnectionPassword = $NodeCredentials.$($CurrentId)[$NodeCredentials_NodePassword] | ConvertTo-SecureString -AsPlainText -force
        }

        $NetworkCredentials       = New-Object System.Management.Automation.PsCredential $NodeConnectionUser, $NodeConnectionPassword

        $TargetPtr                = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($NetworkCredentials.Password)
        $ClearTextPassword        = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($TargetPtr)
        $ClearTextUserName        = $NetworkCredentials.UserName.ToString()


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
      }

      if ( $EnableBFLoginExtensions -and !$FoundWindowsId ) {
        if ( $NodeCredentials.$($CurrentId)[$NodeCredentials_ServiceTag] -eq $ServiceTag ) {
          $ServiceTagMisMatch       = $false

          if ( -not ( $PerHostBFLogin -or ( $ServiceTag -eq $SystemServiceTag ) ) ) {
            if ( $CredentialsDbIsEncrypted ) {
              $NodeConnectionUser     = $NodeCredentials.$($CurrentId)[$NodeCredentials_NodeUser]
              $NodeConnectionPassword = $NodeCredentials.$($CurrentId)[$NodeCredentials_NodePassword] | ConvertTo-SecureString
            } else {
              $NodeConnectionUser     = $NodeCredentials.$($CurrentId)[$NodeCredentials_NodeUser]
              $NodeConnectionPassword = $NodeCredentials.$($CurrentId)[$NodeCredentials_NodePassword] | ConvertTo-SecureString -AsPlainText -force
            }

            $NetworkCredentials       = New-Object System.Management.Automation.PsCredential $NodeConnectionUser, $NodeConnectionPassword

            $TargetPtr                = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($NetworkCredentials.Password)
            $ClearTextPassword        = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($TargetPtr)
            $ClearTextUserName        = $NetworkCredentials.UserName.ToString()
          }

          :ServiceIdentityLookup foreach ($CurrentModule in $BFModules.Keys) {
            if ( $BFModules.$($CurrentModule)[$BFModules_IsEnabled] ) {
              Write-Host -foregroundcolor $COLOR_DARK   "      + BF Module:          " $BFModules.$($CurrentModule)[$BFModules_ModuleName]

              if ( $BFModules.$($CurrentModule)[$BFModules_ServiceTag] -eq $ServiceTag ) {
                $FoundOtherId = & $BFModules.$($CurrentModule)[$BFModules_ModuleName] $SetConnectToHostByIP $ClearTextUserName $ClearTextPassword
              } else {
                Write-Host -foregroundcolor $COLOR_DARK   "      + Skipping BF Module: ServiceTag mismatch [Current: " $BFModules.$($CurrentModule)[$BFModules_ServiceTag] " - Requested: " $ServiceTag "]"
              }

              if ( $FoundOtherId ) {
                break ServiceIdentityLookup
              }
            }
          }
        } else {
          Write-Host -foregroundcolor $COLOR_DARK   "      + Skipping User:      ServiceTag mismatch [Current: " $NodeCredentials.$($CurrentId)[$NodeCredentials_ServiceTag] " - Requested: " $ServiceTag "]"
          $ServiceTagMisMatch  = $true
        }
      }

      if ( !$FoundWindowsId -and !$FoundOtherId ) {
        if ( !$ServiceTagMisMatch ) {
          Write-Host -foregroundcolor $COLOR_ERROR  "        + Credentials       FAILED!"
          Write-Host

          if ( $SaveBFLoginResults ) {
            if ( $SetConnectToHostByIP ) {
              "$ServiceTag;$NodeIP;$ClearTextUserName;$ClearTextPassword"   >> $FailedUsersFile
            } else {
              "$ServiceTag;$NodeName;$ClearTextUserName;$ClearTextPassword" >> $FailedUsersFile
            }
          }
        }
      } else {
        Write-Host -foregroundcolor $COLOR_RESULT  "        + Credentials       FOUND!"
        Write-Host

        if ( $SaveBFLoginResults ) {
          if ( $SetConnectToHostByIP ) {
            "$ServiceTag;$NodeIP;$ClearTextUserName;$ClearTextPassword"   >> $SuccessfulUsersFile
          } else {
            "$ServiceTag;$NodeName;$ClearTextUserName;$ClearTextPassword" >> $SuccessfulUsersFile
          }
        }

        [string] $NodeIdentity = $CurrentId
        break IdentityLookup
      }
    } else {
      Write-Host -foregroundcolor $COLOR_ERROR   "      + Skipping User:      Empty/Invalid Password"
      Write-Host
    }
  }

  return $NodeIdentity
}

##############################################################################

function ScanNode([string] $TargetName, [string] $TargetIP) {
  # Preconditions:
  #   - Hosts Names have been previously resolved: TargetName can NEVER be an IP inside this function.
  #   - When SuppliedHostName and ResolvedHostName don't match the Node is skipped.

  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentScanNodeErrorEvent = @"

===========================================================================================
$(get-date -format u) - ScanNode Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())
-------------------------------------------------------------------------------------------
TargetName:         $TargetName
TargetIP:           $TargetIP
NodeStatus:         $NodeStatus

"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  + ScanNode Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentScanNodeErrorEvent >> $ErrorLogFile
  }


  $PingStatus = @{
    0     = 'Success'                          ;
    11001 = 'Buffer Too Small'                 ;
    11002 = 'Destination Net Unreachable'      ;
    11003 = 'Destination Host Unreachable'     ;
    11004 = 'Destination Protocol Unreachable' ;
    11005 = 'Destination Port Unreachable'     ;
    11006 = 'No Resources'                     ;
    11007 = 'Bad Option'                       ;
    11008 = 'Hardware Error'                   ;
    11009 = 'Packet Too Big'                   ;
    11010 = 'Request Timed Out'                ;
    11011 = 'Bad Request'                      ;
    11012 = 'Bad Route'                        ;
    11013 = 'TimeToLive Expired Transit'       ;
    11014 = 'TimeToLive Expired Reassembly'    ;
    11015 = 'Parameter Problem'                ;
    11016 = 'Source Quench'                    ;
    11017 = 'Option Too Big'                   ;
    11018 = 'Bad Destination'                  ;
    11032 = 'Negotiating IPSEC'                ;
    11050 = 'General Failure'
  }


  $SetConnectToHostByIP = $false
  $SetSkipHost          = $false
  $SetSkipModule        = $false


  if ( $TargetName -eq $UNKNOWN_HOSTNAME ) {
    $SetConnectToHostByIP = $true
  } else {
    $NodeStatus           = $(Get-WmiObject -Class Win32_PingStatus -Filter "Address='$TargetName'" | Select-Object -Property Address, ResponseTime, StatusCode)

    if ( $NodeStatus.StatusCode -ne $STATUS_NODE_ISALIVE ) {
      Write-Host -foregroundcolor $COLOR_ERROR "  + DNS resolution failed:  trying with FQDN resolution."
      Write-Host

      # $TargetName         = [System.Net.Dns]::GetHostEntry($TargetName).Hostname
      $TargetName         = [System.Net.Dns]::GetHostByName($TargetName).Hostname

      $NodeStatus         = $(Get-WmiObject -Class Win32_PingStatus -Filter "Address='$TargetName'" | Select-Object -Property Address, ResponseTime, StatusCode)

      if ( $NodeStatus.StatusCode -ne $STATUS_NODE_ISALIVE ) {
        $SetConnectToHostByIP = $true

        Write-Host -foregroundcolor $COLOR_ERROR "  + Skipping 2nd NodeName:  Fail to connect to $TargetName]. Trying direct IP connection."
        Write-Host
      }
    }
  }

  if ( $SetConnectToHostByIP ) {
    $NodeStatus           = $(Get-WmiObject -Class Win32_PingStatus -Filter "Address='$TargetIP'"   | Select-Object -Property Address, ResponseTime, StatusCode)
  }

  if ( $NodeStatus.StatusCode -ne $STATUS_NODE_ISALIVE ) {
    $SetSkipHost          = $true
  }

  if ( !$SetSkipHost ) {
    Write-Host -foregroundcolor $COLOR_NORMAL       "  + Network Response Time: " $NodeStatus.ResponseTime
    Write-Host

    if ( $BruteForceLoginMode -and $PerHostBFLogin ) {
      [string] $NodeIdentity = GetTargetIdentity $SetConnectToHostByIP $TargetName $TargetIP $SystemServiceTag

      if ( $NodeIdentity.Length -ne 0 ) {
        if ( $CredentialsDbIsEncrypted ) {
          $NodeConnectionUser     = $NodeCredentials.$($NodeIdentity)[$NodeCredentials_NodeUser]
          $NodeConnectionPassword = $NodeCredentials.$($NodeIdentity)[$NodeCredentials_NodePassword] | ConvertTo-SecureString
        } else {
          $NodeConnectionUser     = $NodeCredentials.$($NodeIdentity)[$NodeCredentials_NodeUser]
          $NodeConnectionPassword = $NodeCredentials.$($NodeIdentity)[$NodeCredentials_NodePassword] | ConvertTo-SecureString -AsPlainText -force
        }

        $NetworkCredentials       = New-Object System.Management.Automation.PsCredential $NodeConnectionUser, $NodeConnectionPassword
      } else {
        Write-Host -foregroundcolor $COLOR_ERROR        "  + Skipping Host:          Unable to discover Network Identity for this Node."
        Write-Host

        $SetSkipHost              = $true
      }
    }

    if ( !$SetSkipHost ) {
      if ( $EnableGlobalPreNodeHooks   ) { . RunHooks $HookTarget_IsNode $HookScope_IsGlobal  $HookTrigger_IsBefore }
      if ( $EnableLibraryPreNodeHooks  ) { . RunHooks $HookTarget_IsNode $HookScope_IsLibrary $HookTrigger_IsBefore }

      for ( $i=0; $i -lt $NMAModulesKeys.Length; $i++ ) {
        if ($NMAModules.$($NMAModulesKeys[$i])[$NMAModules_IsEnabled]) {
          $SetSkipModule                    = $false

          $CurrentModule                    = $NMAModules.$($NMAModulesKeys[$i])[$NMAModules_ModuleName]
          $CurrentModule_SStorePropertyName = $NMAModulesKeys[$i]
          $CurrentModule_SStoreIsSupported  = $NMAModules.$($NMAModulesKeys[$i])[$NMAModules_IsSupported]
          $CurrentModule_SStoreIsString     = $NMAModules.$($NMAModulesKeys[$i])[$NMAModules_DataTypeIsString]
          $CurrentModule_ServiceTag         = $NMAModules.$($NMAModulesKeys[$i])[$NMAModules_ServiceTag]

          if ( ($(Get-Item function:\$CurrentModule).Name.Length -ne 0) -and ( $(Get-Item function:\$CurrentModule).Name.Length -ne $null ) ) {
            $ModStartTime = Get-Date

            Write-Host -foregroundcolor $COLOR_NORMAL -noNewLine "  + Processing Module:     " $NMAModules.$($NMAModulesKeys[$i])[$NMAModules_ModuleName]
            Write-Host -foregroundcolor $COLOR_DARK   -noNewLine "  [Node Progress:" $( '{0:p}' -f $($($i+1)/$NMAModulesKeys.Length) )
            Write-Host -foregroundcolor $COLOR_DARK              " `($($i+1)`/$($NMAModulesKeys.Length)`)]"
            Write-Host -foregroundcolor $COLOR_DARK              "    + start:               " $(get-date -format u)
            Write-Host


            if ( $NMAModules.$($NMAModulesKeys[$i])[$NMAModules_DependsOn].Count -ne 0 ) {
              Write-Host -foregroundcolor $COLOR_DARK      -noNewLine "    + depends on:           "
              Write-Host -foregroundcolor $COLOR_ENPHASIZE            $( "$( $NMAModules.$($NMAModulesKeys[$i])[$NMAModules_DependsOn] )" -replace " ", ", " )
              Write-Host
            }


            if ( $BruteForceLoginMode -and $PerModuleBFLogin ) {
              [string] $NodeIdentity = GetTargetIdentity $SetConnectToHostByIP $TargetName $TargetIP $CurrentModule_ServiceTag

              if ( $NodeIdentity.Length -ne 0 ) {
                if ( $CredentialsDbIsEncrypted ) {
                  $NodeConnectionUser     = $NodeCredentials.$($NodeIdentity)[$NodeCredentials_NodeUser]
                  $NodeConnectionPassword = $NodeCredentials.$($NodeIdentity)[$NodeCredentials_NodePassword] | ConvertTo-SecureString
                } else {
                  $NodeConnectionUser     = $NodeCredentials.$($NodeIdentity)[$NodeCredentials_NodeUser]
                  $NodeConnectionPassword = $NodeCredentials.$($NodeIdentity)[$NodeCredentials_NodePassword] | ConvertTo-SecureString -AsPlainText -force
                }

                $NetworkCredentials       = New-Object System.Management.Automation.PsCredential $NodeConnectionUser, $NodeConnectionPassword
              } else {
                Write-Host -foregroundcolor $COLOR_ERROR        "  + Skipping Module:        Unable to discover Network Identity for this Module."
                Write-Host

                $SetSkipModule            = $true
              }
            }

            if ( !$SetSkipModule ) {
              trap {
                $NMAgentModuleErrorEvent = @"

===========================================================================================
$(get-date -format u) - Module Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())
-------------------------------------------------------------------------------------------
CurrentNode:        $TargetName - $TargetIP
SStorePropertyName:  $CurrentModule_SStorePropertyName
SStoreIsSupported:   $CurrentModule_SStoreIsSupported
SStoreIsString:      $CurrentModule_SStoreIsString

"@

                $NodeName     = $TargetName
                $NodeIP       = $TargetIP
                $PropertyName = $CurrentModule_SStorePropertyName
                $IsSupported  = $CurrentModule_SStoreIsSupported
                $IsString     = $CurrentModule_SStoreIsString
                $NodeData     = $null
                $ResultValue  = "Unknown"
                $ErrorFound   = $true
                $ErrorText    = "$_ [$($($_.FullyQualifiedErrorId | Out-String).Trim())] [$($_.InvocationInfo.ScriptLineNumber):$($_.InvocationInfo.OffsetInLine)]"
                $RawOutput    = $($NMAgentModuleErrorEvent | Out-String).Trim()

                Write-Host -foregroundcolor $COLOR_ERROR  "    + Module Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"

                $NMAgentModuleErrorEvent >> $ErrorLogFile
                $NodeName                >> $FailedNodesFile

                . $ModulesDir\_CloseModuleContext.ps1

                continue
              }

              & {
                if ( $EnableGlobalPreModuleHooks  ) { . RunHooks $HookTarget_IsModule $HookScope_IsGlobal  $HookTrigger_IsBefore }
                if ( $EnableLibraryPreModuleHooks ) { . RunHooks $HookTarget_IsModule $HookScope_IsLibrary $HookTrigger_IsBefore }

                & $CurrentModule $SetConnectToHostByIP $TargetName $TargetIP $CurrentModule_SStorePropertyName $CurrentModule_SStoreIsSupported $CurrentModule_SStoreIsString

                if ( $EnableGlobalPostModuleHooks  ) { . RunHooks $HookTarget_IsModule $HookScope_IsGlobal  $HookTrigger_IsAfter }
                if ( $EnableLibraryPostModuleHooks ) { . RunHooks $HookTarget_IsModule $HookScope_IsLibrary $HookTrigger_IsAfter }
              }
            }

            Write-Host
            Write-Host -foregroundcolor $COLOR_DARK   "    + end:                 " $(get-date -format u)
            Write-Host -foregroundcolor $COLOR_DARK   "    + elapsed time:        " $($(Get-Date) - $ModStartTime)
            Write-Host
          } else {
            Write-Host -foregroundcolor $COLOR_ERROR  "    + Skipping Module:     " $CurrentModule "[Unloaded Module]"
            Write-Host
          }
        }
      }

      if ( $EnableGlobalPostNodeHooks  ) { . RunHooks $HookTarget_IsNode $HookScope_IsGlobal  $HookTrigger_IsAfter }
      if ( $EnableLibraryPostNodeHooks ) { . RunHooks $HookTarget_IsNode $HookScope_IsLibrary $HookTrigger_IsAfter }
    } else {
      $TargetName >> $SkippedNodesFile
    }
  } else {
    if ( $NodeStatus.StatusCode -eq $null ) {
      [string] $StatusMessage = "Unable to identify the communication problem"
    } else {
      # this expression also works: $PingStatus.$([int] $NodeStatus.StatusCode)
      [string] $StatusMessage = $PingStatus[$([int] $NodeStatus.StatusCode)]
    }

    Write-Host -foregroundcolor $COLOR_ERROR        "  + Skipping Host:          Network communicaton problems detected [" $StatusMessage "]"
    Write-Host

    $TargetName >> $SkippedNodesFile
  }
}

##############################################################################

function BackUpNodeState($CurrentNode) {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentBackUpNodeStateErrorEvent = @"

===========================================================================================
$(get-date -format u) - BackUpNodeState Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())
-------------------------------------------------------------------------------------------
+ Modified Records:

$( if ($NodesDS.GetChanges("Modified").Tables -ne $null) { $($NodesDS.GetChanges("Modified").Tables[0] | Format-Table RecordId, NodeName  -autosize | Out-String).Trim() } )

+ Added Records:

$( if ($NodesDS.GetChanges("Added").Tables -ne $null) { $($NodesDS.GetChanges("Added").Tables[0] | Format-Table RecordId, NodeName  -autosize | Out-String).Trim() } )

"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  + BackUpNodeState Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentUpdateErrorEvent >> $ErrorLogFile

    break
  }


  $FieldsCollection = $($NodesDT | Select-Object -first 1 | Get-Member -membertype property)
  $NewNodeTemplate  = $CurrentNode

  if ( $NewNodeTemplate -eq $null ) {
    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR "  + ERROR: Can't retrieve NodesHistory NewNodeTemplate"
    Write-Host

    break
  }

  $NewNode = $NodesHistoryDT.NewRow()

  for ($j=0;$j -lt $FieldsCollection.Length;$j++) {
    $NewNode.$($FieldsCollection[$j].Name) = $NewNodeTemplate.$($FieldsCollection[$j].Name)
  }

  $NewNode.RecordId             = $NodeIdCollisionOffSet
  $NewNode.RecordDate           = $(Get-Date).Date

  $NodesHistoryDT.Rows.Add($NewNode)

  if ($NodesHistoryDS.HasChanges("Added")) {
    $NewItemsAtNodesHistoryDS = $NodesHistoryDS.GetChanges("Added")

    if ($NewItemsAtNodesHistoryDS -ne $null) {
      if (-not $NewItemsAtNodesHistoryDS.HasErrors) {
        [void] $NodesHistoryDA.Update($NewItemsAtNodesHistoryDS)
        $NodesHistoryDS.AcceptChanges()
      } else {
        $NodesHistoryDS.RejectChanges()
      }
    } else {
      Write-Host -foregroundcolor $COLOR_ERROR "  # SaveNodeHistory:          NO changes in data were detected and NO change has been persisted."
    }
  }
}

##############################################################################

function UpdateCMDB($ItemsCollection) {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentUpdateErrorEvent = @"

===========================================================================================
$(get-date -format u) - UpdateCMDB Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())
-------------------------------------------------------------------------------------------
+ Modified Records:

$( if ($NodesDS.GetChanges("Modified").Tables -ne $null) { $($NodesDS.GetChanges("Modified").Tables[0] | Format-Table RecordId, NodeName  -autosize | Out-String).Trim() } )

+ Added Records:

$( if ($NodesDS.GetChanges("Added").Tables -ne $null) { $($NodesDS.GetChanges("Added").Tables[0] | Format-Table RecordId, NodeName  -autosize | Out-String).Trim() } )

"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  + Update Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentUpdateErrorEvent >> $ErrorLogFile

    if ($ChangesAtNodesDS -ne $null) {
        $NodesDS.RejectChanges()
    }

    continue
  }


  $STR2BOOL_YES   = "yes"
  $STR2BOOL_NO    = "no"
  $STR2BOOL_TRUE  = "true"
  $STR2BOOL_FALSE = "false"
  $STR2BOOL_ZERO  = "0"

  $FieldsCollection = $($NodesDT | Select-Object -first 1 | Get-Member -membertype property)
  $NewNodeTemplate  = $NodesDT.Select("NodeId = $NewNodeTemplateId")

  if ( $NewNodeTemplate -eq $null ) {
    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR "  + ERROR: Can't retrieve NewNodeTemplate"
    Write-Host

    break
  }

  Write-Host
  Write-Host -foregroundcolor $COLOR_BRIGHT  "  # Selected Sessions:       " $($ItemsCollection | Select-Object SessionId -unique | Measure-Object).Count

  [string] $LastBackedUpNode = ""
  [string] $CurrentSession   = ""

  foreach ( $Item in $ItemsCollection ) {
$NMAgentUpdateMemoValue = @"

===========================================================================================
$(get-date -format u) - $($Item.NodePropertyName.Trim())
-------------------------------------------------------------------------------------------
$($Item.NodeValue_Memo)

"@

$NMAgentUpdateStringValue = @"

===========================================================================================
$(get-date -format u) - $($Item.NodePropertyName.Trim())
-------------------------------------------------------------------------------------------
$($Item.NodeValue)

"@

$NMAgentUpdateQueryOutputValue = @"

===========================================================================================
$(get-date -format u) - $($Item.NodePropertyName.Trim())
-------------------------------------------------------------------------------------------
$($Item.NodeQueryOutput)

"@

    if ($CurrentSession -ne $Item.SessionId) {
      $CurrentSession                      = $Item.SessionId
      [object[]] $CurrentSessionProperties = $ItemsCollection | Where-Object { $_.SessionId -eq $Item.SessionId }

      Write-Host -foregroundcolor $COLOR_BRIGHT "  # Selected SessionId:      " $CurrentSession
      Write-Host -foregroundcolor $COLOR_NORMAL "  + Total Properties:        " $CurrentSessionProperties.Length
    }

    $SourceNode = $Item.NodeName.Trim()
    $SourceIP   = $Item.NodeIP.Trim()

    if ( -not $Item.ErrorFound ) {
      if ($SourceNode -match "(?<CurrentNodeName>[\w]+)(?<DnsSuffix>\.[\w\.]+)|(?<CurrentNodeName>[\w]+)") {
        $SourceNode  = $Matches.CurrentNodeName

        [object[]] $TargetNodes = $NodesDT | Where-Object {
          ( $_.NodeName  -eq $SourceNode ) -or
          ( $_.ServiceIP -eq $SourceIP )   -or
          ( $_.AdminIP   -eq $SourceIP )
        }

        if ( $TargetNodes -ne $null ) {
          if ( $TargetNodes.Length -gt 1 ) {
            $CurrentNode = $TargetNodes | Where-Object { $_.NodeName -eq $SourceNode }
            if ( $CurrentNode -eq $null ) {
              $CurrentNode = $TargetNodes | Where-Object { $_.AdminIP -eq $SourceIP }
              if ( $CurrentNode -eq $null ) {
                $CurrentNode = $TargetNodes | Where-Object { $_.ServiceIP -eq $SourceIP }
              }
            }
          } else {
            $CurrentNode = $TargetNodes[0]
          }

          if ( $LastBackedUpNode -ne $SourceNode ) {
            Write-Host
            Write-Host -foregroundcolor $COLOR_NORMAL "  + Backing up Previous Node Sate"

            BackUpNodeState($CurrentNode)
            $LastBackedUpNode = $SourceNode
          }

          Write-Host -foregroundcolor $COLOR_DARK "  + Updating Property:      [" $Item.NodePropertyName.Trim() "] on Node [" $CurrentNode.NodeName "]"

          if ( ( ( $Item.NodeValue -eq $null ) -or ( $Item.NodeValue.Length -eq 0 ) ) -and
               ( $Item.NodeValue_Memo -is [DBNull] ) ) {
            Write-Host -foregroundcolor $COLOR_ERROR "    + Skipping Update:      [" $Item.NodePropertyName.Trim() "] on Node [" $CurrentNode.NodeName "] - Can't update Null values."
          } else {
            if ($Item.NodePropertyIsSupported) {
              if ( ( $Item.NodeValue.Length -ne 0 ) -and ( $Item.NodeValue.Length -ne $null ) ) {
                if ( $CurrentNode.$($Item.NodePropertyName.Trim()).GetType().Name -eq "Boolean" ) {
                  switch ( $Item.NodeValue.Trim() ) {
                    $STR2BOOL_YES   { $CurrentNode.$($Item.NodePropertyName.Trim()) = $true  }
                    $STR2BOOL_NO    { $CurrentNode.$($Item.NodePropertyName.Trim()) = $false }
                    $STR2BOOL_TRUE  { $CurrentNode.$($Item.NodePropertyName.Trim()) = $true  }
                    $STR2BOOL_FALSE { $CurrentNode.$($Item.NodePropertyName.Trim()) = $false }
                    $STR2BOOL_ZERO  { $CurrentNode.$($Item.NodePropertyName.Trim()) = $false }
                  }
                } else {
                  $CurrentNode.$($Item.NodePropertyName.Trim()) = $Item.NodeValue.Trim()
                }
              } else {
                $CurrentNode.$($Item.NodePropertyName.Trim())   = $NMAgentUpdateMemoValue
              }
            } else {
              if ($Item.NodeValue.Length -ne 0) {
                $CurrentNode.SystemInformationDump              = $NMAgentUpdateStringValue      + $CurrentNode.SystemInformationDump
              } else {
                $CurrentNode.SystemInformationDump              = $NMAgentUpdateMemoValue        + $CurrentNode.SystemInformationDump
              }

              $CurrentNode.SystemInformationDump                = $NMAgentUpdateQueryOutputValue + $CurrentNode.SystemInformationDump
            }

            $CurrentNode.InventoryLastUpdateDate                = $(Get-Date).Date
            $CurrentNode.InventoryUpdaterId                     = $AgentUserId

            if ($NodesDS.HasChanges("Modified")) {
              $ChangesAtNodesDS = $NodesDS.GetChanges("Modified")

              if ($ChangesAtNodesDS -ne $null) {
                if (-not $ChangesAtNodesDS.HasErrors) {
                  trap {
                    $NMAgentUpdateErrorEvent = @"

===========================================================================================
$(get-date -format u) - UpdateCMDB Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())
-------------------------------------------------------------------------------------------
+ Modified Records:

$( if ($NodesDS.GetChanges("Modified").Tables -ne $null) { $($NodesDS.GetChanges("Modified").Tables[0] | Format-Table RecordId, NodeName  -autosize | Out-String).Trim() } )

+ Added Records:

$( if ($NodesDS.GetChanges("Added").Tables -ne $null) { $($NodesDS.GetChanges("Added").Tables[0] | Format-Table RecordId, NodeName  -autosize | Out-String).Trim() } )

"@

                    Write-Host
                    Write-Host -foregroundcolor $COLOR_ERROR "    + Skipping Update:      [" $Item.NodePropertyName.Trim() "] on Node [" $CurrentNode.NodeName "]"
                    Write-Host -foregroundcolor $COLOR_ERROR "      + Error details:     " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
                    Write-Host

                    $NMAgentUpdateErrorEvent >> $ErrorLogFile

                    if ($ChangesAtNodesDS -ne $null) {
                        $NodesDS.RejectChanges()
                    }

                    continue
                  }

                  & {
                    [void] $NodesDA.Update($ChangesAtNodesDS)
                    $NodesDS.AcceptChanges()
                  }
                } else {
                  $NodesDS.RejectChanges()
                }
              } else {
                Write-Host -foregroundcolor $COLOR_ERROR "  # UpdateSession:            NO changes in data were detected and NO change has been persisted."
              }
            }
          }
        } else {
          if ( ( ( $Item.NodeValue -eq $null ) -or ( $Item.NodeValue.Length -eq 0 ) ) -and
               ( $Item.NodeValue_Memo -is [DBNull] ) ) {
            Write-Host -foregroundcolor $COLOR_ERROR "    + Skipping Update:      [" $Item.NodePropertyName.Trim() "] on Node [" $CurrentNode.NodeName "] - Can't update Null values."
          } else {
            Write-Host
            Write-Host -foregroundcolor $COLOR_BRIGHT "  # Adding New Node:         " $SourceNode
            Write-Host

            $NewNode = $NodesDT.NewRow()

            for ($j=0;$j -lt $FieldsCollection.Length;$j++) {
              $NewNode.$($FieldsCollection[$j].Name) = $NewNodeTemplate[0].$($FieldsCollection[$j].Name)
            }

            $NewNode.NodeId                  = $NewNode.NodeId + $NodeIdCollisionOffSet
            $NewNode.NodeName                = $SourceNode
            $NewNode.InventoryCreationDate   = $(Get-Date).Date
            $NewNode.InventoryLastUpdateDate = $(Get-Date).Date
            $NewNode.InventoryUpdaterId      = $AgentUserId


            Write-Host -foregroundcolor $COLOR_DARK "  + Updating Property:      [" $Item.NodePropertyName.Trim() "] on Node [" $NewNode.NodeName "]"

            if ($Item.NodePropertyIsSupported) {
              if ($Item.NodeValue.Length -ne 0) {
                if ( $NewNode.$($Item.NodePropertyName.Trim()).GetType().Name -eq "Boolean" ) {
                  switch ( $Item.NodeValue.Trim() ) {
                    $STR2BOOL_YES   { $NewNode.$($Item.NodePropertyName.Trim()) = $true  }
                    $STR2BOOL_NO    { $NewNode.$($Item.NodePropertyName.Trim()) = $false }
                    $STR2BOOL_TRUE  { $NewNode.$($Item.NodePropertyName.Trim()) = $true  }
                    $STR2BOOL_FALSE { $NewNode.$($Item.NodePropertyName.Trim()) = $false }
                    $STR2BOOL_ZERO  { $NewNode.$($Item.NodePropertyName.Trim()) = $false }
                  }
                } else {
                  $NewNode.$($Item.NodePropertyName.Trim()) = $Item.NodeValue.Trim()
                }
              } else {
                $NewNode.$($Item.NodePropertyName.Trim())   = $NMAgentUpdateMemoValue
              }
            } else {
              if ($Item.NodeValue.Length -ne 0) {
                $NewNode.SystemInformationDump              = $NMAgentUpdateStringValue
              } else {
                $NewNode.SystemInformationDump              = $NMAgentUpdateMemoValue
              }

              $NewNode.SystemInformationDump                = $NMAgentUpdateQueryOutputValue + $NewNode.SystemInformationDump
            }

            $NodesDT.Rows.Add($NewNode)

            if ($NodesDS.HasChanges("Added")) {
              $NewItemsAtNodesDS = $NodesDS.GetChanges("Added")

              if ($NewItemsAtNodesDS -ne $null) {
                if (-not $NewItemsAtNodesDS.HasErrors) {
                  trap {
                    $NMAgentUpdateErrorEvent = @"

===========================================================================================
$(get-date -format u) - UpdateCMDB Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())
-------------------------------------------------------------------------------------------
+ Modified Records:

$( if ($NodesDS.GetChanges("Modified").Tables -ne $null) { $($NodesDS.GetChanges("Modified").Tables[0] | Format-Table RecordId, NodeName  -autosize | Out-String).Trim() } )

+ Added Records:

$( if ($NodesDS.GetChanges("Added").Tables -ne $null) { $($NodesDS.GetChanges("Added").Tables[0] | Format-Table RecordId, NodeName  -autosize | Out-String).Trim() } )

"@

                    Write-Host
                    Write-Host -foregroundcolor $COLOR_ERROR "    + Skipping Update:      [" $Item.NodePropertyName.Trim() "] on Node [" $CurrentNode.NodeName "]"
                    Write-Host -foregroundcolor $COLOR_ERROR "      + Error details:     " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
                    Write-Host

                    $NMAgentUpdateErrorEvent >> $ErrorLogFile

                    if ($ChangesAtNodesDS -ne $null) {
                        $NodesDS.RejectChanges()
                    }

                    continue
                  }

                  & {
                    [void] $NodesDA.Update($NewItemsAtNodesDS)
                    $NodesDS.AcceptChanges()
                  }
                } else {
                  $NodesDS.RejectChanges()
                }
              } else {
                Write-Host -foregroundcolor $COLOR_ERROR "  # UpdateSession:            NO changes in data were detected and NO change has been persisted."
              }
            }
          }
        }
      } else {
          Write-Host
          Write-Host -foregroundcolor $COLOR_ERROR "  + Skipping Node:         " $SourceNode "[Can't extract a Host Name]"
          Write-Host
      }
    } else {
      Write-Host
      Write-Host -foregroundcolor $COLOR_ERROR "  + Skipping Node:          ErrorFound - " $SourceNode "[" $Item.NodePropertyName.Trim() "]"
      Write-Host
    }
  }
}

##############################################################################

function PurgeSStore($ItemsCollection) {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentPurgeErrorEvent = @"

===========================================================================================
$(get-date -format u) - Purge Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())
-------------------------------------------------------------------------------------------
+ Deleted Records:

$( if ($SStoreDS.GetChanges("Deleted").Tables -ne $null) { $($SStoreDS.GetChanges("Deleted").Tables[0] | Format-Table RecordId, NodeName  -autosize | Out-String).Trim() } )

"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  + Purge Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentPurgeErrorEvent >> $ErrorLogFile

    break
  }

  Write-Host
  Write-Host -foregroundcolor $COLOR_NORMAL  "  + Selected Sessions:            " -noNewLine
  Write-Host -foregroundcolor $COLOR_RESULT  $($ItemsCollection | Select-Object SessionId -unique | Measure-Object).Count
  Write-Host

  [string] $CurrentSession   = ""

  foreach ($Item in $ItemsCollection) {
    if ($CurrentSession -ne $Item.SessionId) {
      $CurrentSession                      = $Item.SessionId
      [object[]] $CurrentSessionProperties = $ItemsCollection | Where-Object { $_.SessionId -eq $Item.SessionId }

      Write-Host -foregroundcolor $COLOR_NORMAL "  + Selected SessionId:           " -noNewLine
      Write-Host -foregroundcolor $COLOR_RESULT $CurrentSession
      Write-Host -foregroundcolor $COLOR_NORMAL "  + Total Properties:             " -noNewLine
      Write-Host -foregroundcolor $COLOR_RESULT $CurrentSessionProperties.Length
      Write-Host
    }

    $Item.Delete()
  }

  if ($SStoreDS.HasChanges("Deleted")) {
    $DeletedAtSStoreDS = $SStoreDS.GetChanges("Deleted")

    if ($DeletedAtSStoreDS -ne $null) {
      if (-not $DeletedAtSStoreDS.HasErrors) {
        [void] $SStoreDA.Update($DeletedAtSStoreDS)
        $SStoreDS.AcceptChanges()
      } else {
        $SStoreDS.RejectChanges()
      }
    } else {
      Write-Host -foregroundcolor $COLOR_ERROR "  # INFO: NO changes in data were detected and NO change has been persisted."
    }
  }
}

##############################################################################

function Get-IPRange {
  # Original Code from Gaurhoth
  # http://thepowershellguy.com/blogs/gaurhoth/archive/2007/03/29/finding-a-range-of-ip-addresses.aspx
  # http://thepowershellguy.com/user/Profile.aspx?UserID=2132

  param([string]$ipaddress="",[switch]$AsString,[switch]$AsDecimal,[switch]$AsIPAddress)

  begin {
    # support functions
    function ToDecimal {
      # Convert a string IP ("192.168.1.1") to it's Decimal Equivalent
      # Convert a Binary IP ("11011011111101011101110001111111") to it's Decimal Equivalent
      param([string]$paddress)

      if ($paddress.length -gt 15) {
        # Possibly Binary as it's too long for Dot-Decimal
        return [system.Convert]::ToInt64($paddress.replace(".",""),2)
      } else {
        # Possibly Dot-Decimal.
        # Converting an IP address to decimal involves shifting bits
        # for each octect. Powershell doesn't have any bit shifting operators
        # so we'll use some math (YUCK!)
        [byte[]]$b = ([system.Net.IPAddress]::Parse($paddress)).GetAddressBytes()
        $longip = 0
        for ($i = 0; $i -lt 4; $i++) {
          $num = $b[$i]
          $longip += (($num % 256) * ([math]::pow(256,3-$i)))
        }
        return [int64]$longip
      }
    }

    function ToIP {
      param ($paddress)

      if ($paddress.Length -gt 15) {
        # Possibly Binary as it's too long for Decimal
        # If it's not a string, it'll also fail this test
         return [system.Net.IPAddress]::Parse( (ToDecimal $paddress) )
      } else {
        # Most likely Decimal which the Parse method understands on its own.
        return [system.Net.IPAddress]::Parse($paddress)
      }
    }

    function ToBinary {
      param($paddress)

      if ($paddress.GetType().Name -eq "string") {
        #Dot-Decimal
        return ([system.Convert]::ToString((ToDecimal $paddress),2)).padleft(32,[char]"0")
      } else {
        #Decimal
        return ([system.Convert]::ToString($paddress,2)).padleft(32,[char]"0")
      }
    }

    function SplitAddress {
      param([string]$paddress)
      $address = ($paddress.split("/")[0])
      $cidr = ([int]($paddress.split("/")[1]))
      if (($cidr -lt 0) -or ($cidr -gt 32)) {
        #invalid CIDR.
        throw "$_ is not a valid CIDR notation for a range of IP addresses."
      } else {
        write-Output $address
        write-Output $cidr
      }
    }
  }

  process {
    ################################################
    # Support both pipeline and argument input.
    if ($_) {
      # Pipeline Input
      $address,$cidr = SplitAddress $_
    } else {
      # Argument Input
      if (!$ipaddress) { Throw "You must specify an IP Range in CIDR notation (I.e. `"192.168.1.0/24`")" }
      $address,$cidr = SplitAddress $ipaddress
    }

    $binaddress = ToBinary ( ToDecimal $address )
    $binmask = ("1" * $cidr).padright(32,[char]"0")

    $binnetwork = ""
    $binbroadcast = ""
    for ($i = 0; $i -lt 32; $i++) {
      # faking a bitwise comparison since powershell's -BAND only handles Int32.
      # Determine the Network Address (first in range) by doing a bitwise AND
      # between the address and mask specified.
      $binnetwork += [string]( $binmask.Substring($i,1) -band $binaddress.substring($i,1) )
      # Determine the Broadcast Address by flipping only the HOST bits to 1
      if ($i -lt $cidr) {
        $binbroadcast += [string]( $binaddress.Substring($i,1) )
      } else {
        $binbroadcast += [string]"1"
      }
    }

    # Convert the binary results back to Decimal
    $longnetwork =  ToDecimal $binnetwork
    $longbroadcast =  ToDecimal $binbroadcast

    #Pipe each IP object up the pipeline:
    # I'm skipping the network address and the Broadcast address
    for ($i = $longnetwork+1; $i -lt $longbroadcast; $i++) {
      if ($AsString) {
        write-Output (ToIP $i).IPAddressToString
      } elseif ($AsDecimal) {
        write-Output $i
      } else {
        #AsIPAddress
        write-Output (ToIP $i)
      }
    }
  }
}

##############################################################################

function GetTimeToComplete([timespan] $NodeAverageTime, [int] $RemainingNodes) {
  trap {
    $NMAgentGetTimeToCompleteErrorEvent = @"

===========================================================================================
$(get-date -format u) - GetTimeToComplete Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())

"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "    + GetTimeToComplete Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentGetTimeToCompleteErrorEvent >> $ErrorLogFile

    continue
  }


  [timespan] $TimeToComplete = 0

  for ($i=0;$i -lt $RemainingNodes;$i++) { $TimeToComplete += $NodeAverageTime }

  $TimeToComplete
}

##############################################################################

function GetNodeAverageTime([timespan] $NodeAverageTime, [timespan] $NodeElapsedTime) {
  trap {
    $NMAgentGetNodeAverageTimeErrorEvent = @"

===========================================================================================
$(get-date -format u) - GetNodeAverageTime Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())

"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "    + GetNodeAverageTime Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentGetNodeAverageTimeErrorEvent >> $ErrorLogFile

    continue
  }


  [long]     $NewAverage = [math]::Round( $( $($NodeAverageTime + $NodeElapsedTime).Ticks / 2 ), 0 )
  [timespan] $NewAverage = $NewAverage

  # [timespan] $NewAverage       = $NodeAverageTime + $NodeElapsedTime

  # [int]      $AverageInSeconds = $NewAverage.TotalSeconds / 2
  # [int]      $AverageSeconds   = $AverageInSeconds.TotalSeconds % 60
  # [int]      $AverageDays      = $AverageInSeconds / 86400
  # [int]      $AverageHours     = ($AverageInSeconds / 3600) - ($AverageDays * 24)
  # [int]      $AverageMinutes   = ($AverageInSeconds / 60) - ($AverageHours * 60)

  # if ( $AverageDays -gt 0 ) {
  #   [timespan] $NewAverage     = "$AverageDays" + "." + "$($AverageHours):$($AverageMinutes):$($AverageSeconds)"
  # } else {
  #   [timespan] $NewAverage     = "$($AverageHours):$($AverageMinutes):$($AverageSeconds)"
  # }

  $NewAverage
}

##############################################################################

function AnalyzeData() {
  trap {
    $NMAgentAnalyzeDataErrorEvent = @"

===========================================================================================
$(get-date -format u) - AnalyzeData Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())

"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "    + AnalyzeData Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentAnalyzeDataErrorEvent >> $ErrorLogFile

    continue
  }


  $OriginalColor = $host.UI.RawUI.ForegroundColor

  if ( $DisableFormatOutput ) {
    Write-Host -foregroundcolor $COLOR_BRIGHT "  -------------------------------------------------------------------------------------------"
  }

  Write-Host -foregroundcolor $COLOR_BRIGHT "  # Global Analysis:"
  Write-Host
  Write-Host -foregroundcolor $COLOR_NORMAL "    + Sessions:                  " $($SStoreDT | Select-Object SessionId        -Unique    | Measure-Object).Count
  Write-Host -foregroundcolor $COLOR_NORMAL "    + Nodes:                     " $($SStoreDT | Select-Object NodeName         -Unique    | Measure-Object).Count
  Write-Host -foregroundcolor $COLOR_NORMAL "    + Properties:                " $($SStoreDT | Select-Object NodePropertyName -Unique    | Measure-Object).Count
  Write-Host -foregroundcolor $COLOR_NORMAL "    + Properties with Data:      " $($SStoreDT | Where-Object { !$_.ErrorFound } | Measure-Object).Count
  Write-Host -foregroundcolor $COLOR_NORMAL "    + Properties with Errors:    " $($SStoreDT | Where-Object {  $_.ErrorFound } | Measure-Object).Count
  Write-Host
  Write-Host -foregroundcolor $COLOR_BRIGHT "  -------------------------------------------------------------------------------------------"
  Write-Host -foregroundcolor $COLOR_BRIGHT "  # Error Analysis:"

  $host.UI.RawUI.ForegroundColor = $COLOR_RESULT

  $SStoreDT | Where-Object { $_.ErrorFound } | Group-Object ErrorText | Sort-Object Count -descending | Format-Table Count, Name -autosize
  $SStoreDT | Where-Object { $_.ErrorFound } | Group-Object NodeValue           | Sort-Object Count -descending | Format-Table Count, Name -autosize

  $host.UI.RawUI.ForegroundColor = $OriginalColor

  Write-Host -foregroundcolor $COLOR_BRIGHT "  -------------------------------------------------------------------------------------------"
  Write-Host -foregroundcolor $COLOR_BRIGHT "  # Results Analysis:"
  Write-Host

  $SelectedProperties = $SStoreDT | Select-Object NodePropertyName -Unique

  $SelectedProperties | ForEach-Object {
    $PropertyName = $_.NodePropertyName

    Write-Host -foregroundcolor $COLOR_NORMAL -noNewLine "  + Current Property: "
    Write-Host -foregroundcolor $COLOR_BRIGHT $PropertyName

    $host.UI.RawUI.ForegroundColor = $COLOR_RESULT

    $SStoreDT | Where-Object { $_.NodePropertyName -eq $PropertyName } | Group-Object NodeValue | Sort-Object Count -descending | Format-Table Count, Name -autosize

    $host.UI.RawUI.ForegroundColor = $OriginalColor
  }

  if ( $DisableFormatOutput ) {
    Write-Host -foregroundcolor $COLOR_BRIGHT "  -------------------------------------------------------------------------------------------"
  }
}

##############################################################################

function CompareData([Object[]] $FirstDT, [Object[]] $SecondDT) {
  trap {
    $NMAgentCompareDataErrorEvent = @"

===========================================================================================
$(get-date -format u) - CompareData Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())

"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "    + CompareData Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentCompareDataErrorEvent >> $ErrorLogFile

    continue
  }


  $OriginalColor = $host.UI.RawUI.ForegroundColor

  if ( $DisableFormatOutput ) {
    Write-Host -foregroundcolor $COLOR_NORMAL "  -------------------------------------------------------------------------------------------"
  }

  Write-Host -foregroundcolor $COLOR_NORMAL "  + NodeName Differences:"

  $host.UI.RawUI.ForegroundColor = $COLOR_RESULT

  Compare-Object $FirstDT $SecondDT -property NodeName | Sort-Object SideIndicator | Format-Table NodeName -autosize -groupBy SideIndicator

  $host.UI.RawUI.ForegroundColor = $OriginalColor

  Write-Host -foregroundcolor $COLOR_NORMAL "  -------------------------------------------------------------------------------------------"
  Write-Host -foregroundcolor $COLOR_NORMAL "  + NodePropertyName Differences:"

  $host.UI.RawUI.ForegroundColor = $COLOR_RESULT

  Compare-Object $FirstDT $SecondDT -property NodePropertyName, NodeName, NodeAttributeName | Sort-Object NodeName, NodeAttributeName, SideIndicator | Format-Table NodeName, NodeAttributeName, SideIndicator -autosize -groupBy NodePropertyName

  $host.UI.RawUI.ForegroundColor = $OriginalColor

  Write-Host -foregroundcolor $COLOR_NORMAL "  -------------------------------------------------------------------------------------------"
  Write-Host -foregroundcolor $COLOR_NORMAL "  + NodeAttributeName Differences:"

  $host.UI.RawUI.ForegroundColor = $COLOR_RESULT

  Compare-Object $FirstDT $SecondDT -property NodeAttributeName, NodeName, NodePropertyName | Sort-Object NodeName, NodePropertyName, SideIndicator | Format-Table NodeName, NodePropertyName, SideIndicator -autosize -groupBy NodeAttributeName

  $host.UI.RawUI.ForegroundColor = $OriginalColor

  Write-Host -foregroundcolor $COLOR_NORMAL "  -------------------------------------------------------------------------------------------"
  Write-Host -foregroundcolor $COLOR_NORMAL "  + NodeValue Differences:"

  $host.UI.RawUI.ForegroundColor = $COLOR_RESULT

  Compare-Object $FirstDT $SecondDT -property NodeName, NodePropertyName, NodeValue | Sort-Object NodePropertyName, NodeAttributeName, NodeName, SideIndicator | Format-Table NodeName, NodeAttributeName, NodeValue, SideIndicator -autosize -groupBy NodePropertyName

  $host.UI.RawUI.ForegroundColor = $OriginalColor

  if ( $DisableFormatOutput ) {
    Write-Host -foregroundcolor $COLOR_NORMAL "  -------------------------------------------------------------------------------------------"
  }
}

##############################################################################

function BuildFilterString() {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentBuildFilterStringEvent = @"

===========================================================================================
$(get-date -format u) - BuildFilterString Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())

"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  + BuildFilterString Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentBuildFilterStringEvent >> $ErrorLogFile

    break
  }


  [string]   $QueryString   = ""
  [string[]] $QueryElements = "", "", "", "", "", "", "", "", "", ""
  $PopulatedElements        = @{}
  $ElementIndex             = 0
  $TotalCriteria            = 0


  $UserFilter.Keys | ForEach-Object {
    if ( $UserFilter.$_[$UserFilter_IsActive] ) { $TotalCriteria++ }
  }

  if ( $TotalCriteria -eq 0 ) {
    return $QueryString
  }


  if ( $UserFilter.ErrorFound[$UserFilter_IsActive] ) {
    if ( $UserFilter.ErrorFound[$UserFilter_IsNot] ) {
      $QueryElements[0] = " ErrorFound <> $($UserFilter.ErrorFound[$UserFilter_Value]) "
    } else {
      $QueryElements[0] = " ErrorFound = $($UserFilter.ErrorFound[$UserFilter_Value]) "
    }
  }

  if ( $UserFilter.PropertyName[$UserFilter_IsActive] ) {
    if ( $UserFilter.PropertyName[$UserFilter_IsNot] ) {
      $QueryElements[1] = " NodePropertyName NOT LIKE '$($UserFilter.PropertyName[$UserFilter_Value])' "
    } else {
      $QueryElements[1] = " NodePropertyName LIKE '$($UserFilter.PropertyName[$UserFilter_Value])' "
    }
  }

  if ( $UserFilter.AttributeName[$UserFilter_IsActive] ) {
    if ( $UserFilter.AttributeName[$UserFilter_IsNot] ) {
      $QueryElements[2] = " NodeAttributeName NOT LIKE '$($UserFilter.AttributeName[$UserFilter_Value])' "
    } else {
      $QueryElements[2] = " NodeAttributeName LIKE '$($UserFilter.AttributeName[$UserFilter_Value])' "
    }
  }

  if ( $UserFilter.Value[$UserFilter_IsActive] ) {
    if ( $UserFilter.Value[$UserFilter_IsNot] ) {
      $QueryElements[3] = " NodeValue NOT LIKE '$($UserFilter.Value[$UserFilter_Value])' "
    } else {
      $QueryElements[3] = " NodeValue LIKE '$($UserFilter.Value[$UserFilter_Value])' "
    }
  }

  if ( $UserFilter.ValueMemo[$UserFilter_IsActive] ) {
    if ( $UserFilter.ValueMemo[$UserFilter_IsNot] ) {
      $QueryElements[4] = " NodeValue_Memo NOT LIKE '$($UserFilter.ValueMemo[$UserFilter_Value])' "
    } else {
      $QueryElements[4] = " NodeValue_Memo LIKE '$($UserFilter.ValueMemo[$UserFilter_Value])' "
    }
  }

  if ( $UserFilter.QueryOutput[$UserFilter_IsActive] ) {
    if ( $UserFilter.QueryOutput[$UserFilter_IsNot] ) {
      $QueryElements[5] = " NodeQueryOutput NOT LIKE '$($UserFilter.QueryOutput[$UserFilter_Value])' "
    } else {
      $QueryElements[5] = " NodeQueryOutput LIKE '$($UserFilter.QueryOutput[$UserFilter_Value])' "
    }
  }

  if ( $UserFilter.NodeName[$UserFilter_IsActive] ) {
    if ( $UserFilter.NodeName[$UserFilter_IsNot] ) {
      $QueryElements[6] = " NodeName NOT LIKE '$($UserFilter.NodeName[$UserFilter_Value])' "
    } else {
      $QueryElements[6] = " NodeName LIKE '$($UserFilter.NodeName[$UserFilter_Value])' "
    }
  }

  if ( $UserFilter.NodeIP[$UserFilter_IsActive] ) {
    if ( $UserFilter.NodeIP[$UserFilter_IsNot] ) {
      $QueryElements[7] = " NodeIP NOT LIKE '$($UserFilter.NodeIP[$UserFilter_Value])' "
    } else {
      $QueryElements[7] = " NodeIP LIKE '$($UserFilter.NodeIP[$UserFilter_Value])' "
    }
  }

  if ( $UserFilter.AgentNode[$UserFilter_IsActive] ) {
    if ( $UserFilter.AgentNode[$UserFilter_IsNot] ) {
      $QueryElements[8] = " AgentNodeName NOT LIKE '$($UserFilter.AgentNode[$UserFilter_Value])' "
    } else {
      $QueryElements[8] = " AgentNodeName LIKE '$($UserFilter.AgentNode[$UserFilter_Value])' "
    }
  }

  if ( $UserFilter.AgentUser[$UserFilter_IsActive] ) {
    if ( $UserFilter.AgentUser[$UserFilter_IsNot] ) {
      $QueryElements[9] = " AgentUserName NOT LIKE '$($UserFilter.AgentUser[$UserFilter_Value])' "
    } else {
      $QueryElements[9] = " AgentUserName LIKE '$($UserFilter.AgentUser[$UserFilter_Value])' "
    }
  }


  for ( $i=0; $i -lt $QueryElements.Length ; $i++ ) {
    if ( $QueryElements[$i] -ne "" ) {
      $PopulatedElements.$($ElementIndex) = $QueryElements[$i]
      $ElementIndex++
    }
  }

  if ( $PopulatedElements.Count -gt 1 ) {
    for ( $i=0; $i -lt $PopulatedElements.Count ; $i++ ) {
      if ( $i -eq 0 ) {
        $QueryString += "( " + $($PopulatedElements.$($i)) + " ) "
      } else {
        $QueryString += " AND ( " + $($PopulatedElements.$($i)) + " )"
      }
    }
  } else {
    $QueryString     =  $PopulatedElements[0]
  }

  return $QueryString
}

##############################################################################

function Try {
  # Original Try Function from Adam Weigert
  # http://weblogs.asp.net/adweigert/archive/2007/10/10/powershell-try-catch-finally-comes-to-life.aspx


  param (
    [ScriptBlock] $Command = $(throw "The parameter -Command is required."),
    [ScriptBlock] $Catch   = { throw $_ },
    [ScriptBlock] $Finally = {}
  )

  & {
      $local:ErrorActionPreference = "SilentlyContinue"

      trap {
        trap {
            & {
                trap { throw $_ }
                &$Finally
            }

            throw $_
        }

        $_ | & { &$Catch }
      }

      &$Command
  }

  & {
      trap { throw $_ }
      &$Finally
  }
}

##############################################################################

function LoadExtendedSettings {
  trap {
    $NMAgentLoadExtendedSettingsErrorEvent = @"

===========================================================================================
$(get-date -format u) - LoadExtendedSettings Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())

"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "    + LoadExtendedSettings Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentLoadExtendedSettingsErrorEvent >> $ErrorLogFile

    continue
  }


  Write-Host -foregroundcolor $COLOR_NORMAL "  + Loading Session Extended Settings: "

  $ModulesLibraries | ForEach-Object {
    Write-Host -foregroundcolor $COLOR_NORMAL -noNewLine "    + Loading: $_ ... "

    if ( Test-Path $ModulesDir\$_\_settings\settings.ps1 ) {
      . $ModulesDir\$_\_settings\settings.ps1

      Write-Host -foregroundcolor $COLOR_BRIGHT "done"
    } else {
      Write-Host -foregroundcolor $COLOR_ERROR  "N/A"
    }
  }
}

##############################################################################

function LoadBFModulesTable {
  trap {
    $NMAgentLoadBFModulesTableErrorEvent = @"

===========================================================================================
$(get-date -format u) - LoadBFModulesTable Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())

"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "    + LoadBFModulesTable Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentLoadBFModulesTableErrorEvent >> $ErrorLogFile

    continue
  }


  Write-Host -foregroundcolor $COLOR_NORMAL -noNewLine "  + Loading Brute Force Modules Table... "

  if ( Test-Path $AuthDir\_settings\modules.ps1 ) {
    .  $AuthDir\_settings\modules.ps1

    Write-Host -foregroundcolor $COLOR_BRIGHT "done"
  } else {
    Write-Host -foregroundcolor $COLOR_ERROR  "N/A"
  }
}

##############################################################################

function LoadBFModules {
  trap {
    $NMAgentLoadBFModulesErrorEvent = @"

===========================================================================================
$(get-date -format u) - LoadBFModules Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())

"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "      + LoadBFModules Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentLoadBFModulesErrorEvent >> $ErrorLogFile

    continue
  }


  Write-Host -foregroundcolor $COLOR_NORMAL "  + Loading Brute Force available Modules: "

  Get-ChildItem $AuthDir\*.ps1 -exclude _* | ForEach-Object {
    Write-Host -foregroundcolor $COLOR_NORMAL -noNewLine "    + Loading: "
    Write-Host -foregroundcolor $COLOR_BRIGHT $_.Name

    . $_
  }
}

##############################################################################

function LoadCreadentials {
  trap {
    $NMAgentLoadCredentialsErrorEvent = @"

===========================================================================================
$(get-date -format u) - LoadCreadentials Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())

"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "    + LoadCreadentials Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentLoadCredentialsErrorEvent >> $ErrorLogFile

    continue
  }


  Write-Host -foregroundcolor $COLOR_NORMAL -noNewLine "  + Loading Credentials... "

  if ( Test-Path $AuthDir\_settings\credentials.ps1 ) {
    . $AuthDir\_settings\credentials.ps1

    Write-Host -foregroundcolor $COLOR_BRIGHT "done"
  } else {
    Write-Host -foregroundcolor $COLOR_ERROR  "N/A"
  }
}

##############################################################################

function LoadExtendedCredentials {
  trap {
    $NMAgentLoadExtendedCredentialsErrorEvent = @"

===========================================================================================
$(get-date -format u) - LoadExtendedCredentials Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())

"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "    + LoadExtendedCredentials Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentLoadExtendedCredentialsErrorEvent >> $ErrorLogFile

    continue
  }


  if ( $MergeCredentialsFiles ) {
    Write-Host -foregroundcolor $COLOR_NORMAL "  + Loading Profile Extended Credentials:"

    $ModulesLibraries | ForEach-Object {
      Write-Host -foregroundcolor $COLOR_NORMAL -noNewLine "    + Loading: $_ ... "

      if (Test-Path $ModulesDir\$_\_settings\credentials.ps1) {
        . $ModulesDir\$_\_settings\credentials.ps1

        [string[]] $LibraryCredentialsKeys  = ($LibraryCredentials.Keys | Sort-Object)

        for ( $i=0; $i -lt $LibraryModulesKeys.Count; $i++ ) {
          if ( !$script:NodeCredentials.ContainsKey( $LibraryCredentialsKeys[$i] ) ) {
            $script:NodeCredentials.Add($LibraryCredentialsKeys[$i], $LibraryCredentials.$($LibraryModulesKeys[$i]))
          }
        }

        Write-Host -foregroundcolor $COLOR_BRIGHT "done"
      } else {
        Write-Host -foregroundcolor $COLOR_ERROR  "N/A"
      }
    }
  }
}

##############################################################################

function LoadModulesTable {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentLoadModulesTableErrorEvent = @"

===========================================================================================
$(get-date -format u) - LoadModulesTable Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())

"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "      + LoadModulesTable Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentLoadModulesTableErrorEvent >> $ErrorLogFile

    continue
  }


  Write-Host -foregroundcolor $COLOR_NORMAL "  + Loading Profile Modules Table:"

  if ( $script:LibraryModules.Count -ne 0 ) {
    [string[]] $script:LibraryModulesKeys  = ( $script:LibraryModules.Keys | Sort-Object )

    $script:LibraryModulesKeys | ForEach-Object {
      Write-Host -foregroundcolor $COLOR_NORMAL -noNewLine "    + Loading: $_ ... "

      if ( !$script:NMAModules.ContainsKey( $_ ) ) {
        $script:NMAModules.Add( $_, $script:LibraryModules.$( $_ ) )
        Write-Host -foregroundcolor $COLOR_BRIGHT "done"
      } else {
        Write-Host -foregroundcolor $COLOR_ERROR  "skipped"
      }
    }
  } else {
    Write-Host -foregroundcolor $COLOR_ERROR -noNewLine "    + INFO: Profile Modules Table is empty."
  }
}

##############################################################################

function LoadProfileModules {
  trap {
    $NMAgentLoadProfileModulesErrorEvent = @"

===========================================================================================
$(get-date -format u) - LoadProfileModules Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())

"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "        + LoadProfileModules Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentLoadProfileModulesErrorEvent >> $ErrorLogFile

    continue
  }


  Write-Host -foregroundcolor $COLOR_NORMAL "  + Loading Profile Modules: "

  foreach ( $Library in $ModulesLibraries ) {
    Write-Host -foregroundcolor $COLOR_NORMAL -noNewLine "    + Library: "
    Write-Host -foregroundcolor $COLOR_BRIGHT $Library

    if ( Test-Path $ModulesDir\$Library\$EnabledModulesDirName ) {
      Get-ChildItem $ModulesDir\$Library\$EnabledModulesDirName\*.ps1 -exclude _* | ForEach-Object {
        Write-Host -foregroundcolor $COLOR_NORMAL -noNewLine "      + Loading: "
        Write-Host -foregroundcolor $COLOR_BRIGHT $_.Name

        . $_
      }
    } else {
      Write-Host -foregroundcolor $COLOR_ERROR  "      + Skipping Library: [$Library] does not exist"
    }
  }
}

##############################################################################

function LoadDataSets {
  $TBLNODES_SELECTION                = "SELECT * FROM TblNodes WHERE (NodeId = $NewNodeTemplateId) OR ($OpenSLIMDbBasicFilter AND $OpenSLIMDbUserFilter)"
  $TBLCOLLECTEDDATA_SELECTION        = "SELECT * FROM [$script:AgentUserSessionStore]"
  $TBLNODESHISTORY_SELECTION         = "SELECT TOP 1 * FROM TblNodesHistory"


  if ( ( $script:OpenSLIMDbUserName.Length -eq 0 ) -or ( $script:OpenSLIMDbUserName -eq $null ) ) {
    $OpenSLIMDbConnectionString      = "Data Source=$script:OpenSLIMDbServer;Initial Catalog=$script:OpenSLIMDbName;Integrated Security=SSPI;"
  } else {
    $OpenSLIMDbConnectionString      = "Data Source=$script:OpenSLIMDbServer;Initial Catalog=$script:OpenSLIMDbName;User Id=$script:OpenSLIMDbUserName;Password=$script:OpenSLIMDbPassword;"
  }

  $OpenSLIMDb                        = New-Object System.Data.SqlClient.SqlConnection
  $OpenSLIMDb.ConnectionString       = $OpenSLIMDbConnectionString
  $OpenSLIMDb.Open()


  switch ( $script:NMAgentDbType ) {
    $NMAgentDbType_MSAccess {
      if ( ( $script:NMAgentDbUserName.Length -eq 0 ) -or ( $script:NMAgentDbUserName -eq $null ) ) {
        $script:NMAgentDbConnectionString = "Provider = Microsoft.Jet.OLEDB.4.0; Data Source = $InstallDir\$script:NMAgentDbName.mdb;"
      } else {
        $script:NMAgentDbConnectionString = "Provider = Microsoft.Jet.OLEDB.4.0; Data Source = $InstallDir\$script:NMAgentDbName.mdb; Jet OLEDB:System Database= $InstallDir\$script:NMAgentDbName.mdw; Password=$script:NMAgentDbPassword; User ID=$script:NMAgentDbUserName"
      }

      $NMAgentDb                     = New-Object System.Data.OleDb.OleDbConnection
    }

    $NMAgentDbType_MSSQLServer {
      if ( ( $script:NMAgentDbUserName.Length -eq 0 ) -or ( $script:NMAgentDbUserName -eq $null ) ) {
        $script:NMAgentDbConnectionString = "Data Source=$script:NMAgentDbServer;Initial Catalog=$script:NMAgentDbName;Integrated Security=SSPI;"
      } else {
        $script:NMAgentDbConnectionString = "Data Source=$script:NMAgentDbServer;Initial Catalog=$script:NMAgentDbName;User Id=$script:NMAgentDbUserName;Password=$script:NMAgentDbPassword;"
      }

      $NMAgentDb                     = New-Object System.Data.SqlClient.SqlConnection
    }
  }


  $NMAgentDb.ConnectionString        = $NMAgentDbConnectionString
  $NMAgentDb.Open()


  $NodesSrc                          = New-Object System.Data.SqlClient.SqlCommand($TBLNODES_SELECTION, $OpenSLIMDb)
  $NodesDA                           = New-Object System.Data.SqlClient.SqlDataAdapter($NodesSrc)
  $NodesDS                           = New-Object System.Data.DataSet
  $NodesDT                           = New-Object System.Data.DataTable

  $NodesHistorySrc                   = New-Object System.Data.SqlClient.SqlCommand($TBLNODESHISTORY_SELECTION, $OpenSLIMDb)
  $NodesHistoryDA                    = New-Object System.Data.SqlClient.SqlDataAdapter($NodesHistorySrc)
  $NodesHistoryDS                    = New-Object System.Data.DataSet
  $NodesHistoryDT                    = New-Object System.Data.DataTable


  if ( ($cmd.ToLower() -eq $CMD_UPDATE ) -or ($cmd.ToLower() -eq $CMD_SHELL ) -or ($src.ToLower() -eq $TARGET_DB ) ) {
    [void] $NodesDA.Fill($NodesDS)
    $NodesDT                         = $NodesDS.Tables[0]
    $DbCmdBuilder                    = New-Object System.Data.SqlClient.SqlCommandBuilder $NodesDA
    $NodesDA.UpdateCommand           = $DbCmdBuilder.GetUpdateCommand()
    $NodesDA.InsertCommand           = $DbCmdBuilder.GetInsertCommand()
    $NodesDA.DeleteCommand           = $DbCmdBuilder.GetDeleteCommand()

    [void] $NodesHistoryDA.Fill($NodesHistoryDS)
    $NodesHistoryDT                  = $NodesHistoryDS.Tables[0]
    $DbCmdBuilder                    = New-Object System.Data.SqlClient.SqlCommandBuilder $NodesHistoryDA
    $NodesHistoryDA.UpdateCommand    = $DbCmdBuilder.GetUpdateCommand()
    $NodesHistoryDA.InsertCommand    = $DbCmdBuilder.GetInsertCommand()
    $NodesHistoryDA.DeleteCommand    = $DbCmdBuilder.GetDeleteCommand()
  }

  if ( ( $store -ne $null ) -and ( $store -ne "" ) -and ( $store.Length -ne 0 ) ) {
    $OFFLINESTORE_SELECTION          = $TBLCOLLECTEDDATA_SELECTION

    switch ( $script:NMAgentDbType ) {
      $NMAgentDbType_MSAccess {
        $OfflineStoreSrc             = New-Object System.Data.OleDb.OleDbCommand($OFFLINESTORE_SELECTION, $NMAgentDb)
        $OfflineStoreDA              = New-Object System.Data.OleDb.OleDbDataAdapter($OfflineStoreSrc)
        $DbCmdBuilder                = New-Object System.Data.OleDb.OleDbCommandBuilder $OfflineStoreDA
      }

      $NMAgentDbType_MSSQLServer {
        $OfflineStoreSrc             = New-Object System.Data.SqlClient.SqlCommand($OFFLINESTORE_SELECTION, $NMAgentDb)
        $OfflineStoreDA              = New-Object System.Data.SqlClient.SqlDataAdapter($OfflineStoreSrc)
        $DbCmdBuilder                = New-Object System.Data.SqlClient.SqlCommandBuilder $OfflineStoreDA
      }
    }

    $OfflineStoreDS                  = New-Object System.Data.DataSet
    $OfflineStoreDT                  = New-Object System.Data.DataTable
    [void] $OfflineStoreDA.Fill($OfflineStoreDS)
    $OfflineStoreDT                  = $OfflineStoreDS.Tables[0]

    $OfflineStoreDA.UpdateCommand    = $DbCmdBuilder.GetUpdateCommand()
    $OfflineStoreDA.InsertCommand    = $DbCmdBuilder.GetInsertCommand()
    $OfflineStoreDA.DeleteCommand    = $DbCmdBuilder.GetDeleteCommand()
  }

  switch ( $script:NMAgentDbType ) {
    $NMAgentDbType_MSAccess {
      $SStoreSrc                     = New-Object System.Data.OleDb.OleDbCommand($TBLCOLLECTEDDATA_SELECTION, $NMAgentDb)
      $SStoreDA                      = New-Object System.Data.OleDb.OleDbDataAdapter($SStoreSrc)
      $DbCmdBuilder                  = New-Object System.Data.OleDb.OleDbCommandBuilder $SStoreDA
    }

    $NMAgentDbType_MSSQLServer {
      $SStoreSrc                     = New-Object System.Data.SqlClient.SqlCommand($TBLCOLLECTEDDATA_SELECTION, $NMAgentDb)
      $SStoreDA                      = New-Object System.Data.SqlClient.SqlDataAdapter($SStoreSrc)
      $DbCmdBuilder                  = New-Object System.Data.SqlClient.SqlCommandBuilder $SStoreDA
    }
  }

  $SStoreDS                          = New-Object System.Data.DataSet
  $SStoreDT                          = New-Object System.Data.DataTable
  [void] $SStoreDA.Fill($SStoreDS)
  $SStoreDT                          = $SStoreDS.Tables[0]
  $SStoreDA.UpdateCommand            = $DbCmdBuilder.GetUpdateCommand()
  $SStoreDA.InsertCommand            = $DbCmdBuilder.GetInsertCommand()
  $SStoreDA.DeleteCommand            = $DbCmdBuilder.GetDeleteCommand()


  if (-not $?) {
    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  + FATAL ERROR: unable to successfully open/handle database."
    Write-Host
    break
  }
}

##############################################################################

function RunHooks( [int] $HookTarget, [int] $HookScope, [int] $HookTrigger ) {
  trap {
    $NMAgentRunHooksErrorEvent = @"

===========================================================================================
$(get-date -format u) - RunHooks Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())

"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "      + RunHooks Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentRunHooksErrorEvent >> $ErrorLogFile

    continue
  }


  switch ( $HookTarget ) {
    $HookTarget_IsSession {
      switch ( $HookScope ) {
        $HookScope_IsGlobal {
          switch ( $HookTrigger ) {
            $HookTrigger_IsBefore {
              Write-Host -foregroundcolor $COLOR_DARK "  + Pre-Session Global Hooks: "

              if ( Test-Path $GlobalHooksDir\$PreSession_HookDirName ) {
                Get-ChildItem $GlobalHooksDir\$PreSession_HookDirName\*.ps1 -exclude _* | ForEach-Object {
                  Write-Host -foregroundcolor $COLOR_DARK -noNewLine "    + Launching: "
                  Write-Host -foregroundcolor $COLOR_NORMAL $_.Name

                  . $_
                }
              } else {
                Write-Host -foregroundcolor $COLOR_ERROR "    + WARNING: can't find Pre-Session Hooks Folder"
              }
            }

            $HookTrigger_IsAfter {
              Write-Host -foregroundcolor $COLOR_DARK "  + Post-Session Global Hooks: "

              if ( Test-Path $GlobalHooksDir\$PostSession_HookDirName ) {
                Get-ChildItem $GlobalHooksDir\$PostSession_HookDirName\*.ps1 -exclude _* | ForEach-Object {
                  Write-Host -foregroundcolor $COLOR_DARK -noNewLine "    + Launching: "
                  Write-Host -foregroundcolor $COLOR_NORMAL $_.Name

                  . $_
                }
              } else {
                Write-Host -foregroundcolor $COLOR_ERROR "    + WARNING: can't find Post-Session Hooks Folder"
              }
            }
          }
        }

        $HookScope_IsLibrary {
          switch ( $HookTrigger ) {
            $HookTrigger_IsBefore {
              Write-Host -foregroundcolor $COLOR_DARK "  + Pre-Session Library Hooks: "

              $ModulesLibraries | ForEach-Object {
                Write-Host -foregroundcolor $COLOR_DARK "    + Library: $_ ... "

                if ( Test-Path $ModulesDir\$_\$HooksDirName\$PreSession_HookDirName ) {
                  Get-ChildItem $ModulesDir\$_\$HooksDirName\$PreSession_HookDirName\*.ps1 -exclude _* | ForEach-Object {
                    Write-Host -foregroundcolor $COLOR_DARK -noNewLine "      + Launching: "
                    Write-Host -foregroundcolor $COLOR_NORMAL $_.Name

                    . $_
                  }
                } else {
                  Write-Host -foregroundcolor $COLOR_ERROR "    + WARNING: can't find Pre-Session Hooks Folder"
                }
              }
            }

            $HookTrigger_IsAfter {
              Write-Host -foregroundcolor $COLOR_DARK "  + Post-Session Library Hooks: "

              $ModulesLibraries | ForEach-Object {
                Write-Host -foregroundcolor $COLOR_DARK "    + Library: $_ ... "

                if ( Test-Path $ModulesDir\$_\$HooksDirName\$PostSession_HookDirName ) {
                  Get-ChildItem $ModulesDir\$_\$HooksDirName\$PostSession_HookDirName\*.ps1 -exclude _* | ForEach-Object {
                    Write-Host -foregroundcolor $COLOR_DARK -noNewLine "      + Launching: "
                    Write-Host -foregroundcolor $COLOR_NORMAL $_.Name

                    . $_
                  }
                } else {
                  Write-Host -foregroundcolor $COLOR_ERROR "      + WARNING: can't find Post-Session Hooks Folder"
                }
              }
            }
          }
        }
      }
    }

    $HookTarget_IsNode {
      switch ( $HookScope ) {
        $HookScope_IsGlobal {
          switch ( $HookTrigger ) {
            $HookTrigger_IsBefore {
              Write-Host -foregroundcolor $COLOR_DARK "  + Pre-Node Global Hooks: "

              if ( Test-Path $GlobalHooksDir\$PreNode_HookDirName ) {
                Get-ChildItem $GlobalHooksDir\$PreNode_HookDirName\*.ps1 -exclude _* | ForEach-Object {
                  Write-Host -foregroundcolor $COLOR_DARK -noNewLine "    + Launching: "
                  Write-Host -foregroundcolor $COLOR_NORMAL $_.Name

                  . $_
                }
              } else {
                Write-Host -foregroundcolor $COLOR_ERROR "    + WARNING: can't find Pre-Node Hooks Folder"
              }
            }

            $HookTrigger_IsAfter {
              Write-Host -foregroundcolor $COLOR_DARK "  + Post-Node Global Hooks: "

              if ( Test-Path $GlobalHooksDir\$PostNode_HookDirName ) {
                Get-ChildItem $GlobalHooksDir\$PostNode_HookDirName\*.ps1 -exclude _* | ForEach-Object {
                  Write-Host -foregroundcolor $COLOR_DARK -noNewLine "    + Launching: "
                  Write-Host -foregroundcolor $COLOR_NORMAL $_.Name

                  . $_
                }
              } else {
                Write-Host -foregroundcolor $COLOR_ERROR "    + WARNING: can't find Post-Node Hooks Folder"
              }
            }
          }
        }

        $HookScope_IsLibrary {
          switch ( $HookTrigger ) {
            $HookTrigger_IsBefore {
              Write-Host -foregroundcolor $COLOR_DARK "  + Pre-Node Library Hooks: "

              $ModulesLibraries | ForEach-Object {
                Write-Host -foregroundcolor $COLOR_DARK "    + Library: $_ ... "

                if ( Test-Path $ModulesDir\$_\$HooksDirName\$PreNode_HookDirName ) {
                  Get-ChildItem $ModulesDir\$_\$HooksDirName\$PreNode_HookDirName\*.ps1 -exclude _* | ForEach-Object {
                    Write-Host -foregroundcolor $COLOR_DARK -noNewLine "      + Launching: "
                    Write-Host -foregroundcolor $COLOR_NORMAL $_.Name

                    . $_
                  }
                } else {
                  Write-Host -foregroundcolor $COLOR_ERROR "    + WARNING: can't find Pre-Node Hooks Folder"
                }
              }
            }

            $HookTrigger_IsAfter {
              Write-Host -foregroundcolor $COLOR_DARK "  + Post-Node Library Hooks: "

              $ModulesLibraries | ForEach-Object {
                Write-Host -foregroundcolor $COLOR_DARK "    + Library: $_ ... "

                if ( Test-Path $ModulesDir\$_\$HooksDirName\$PostNode_HookDirName ) {
                  Get-ChildItem $ModulesDir\$_\$HooksDirName\$PostNode_HookDirName\*.ps1 -exclude _* | ForEach-Object {
                    Write-Host -foregroundcolor $COLOR_DARK -noNewLine "      + Launching: "
                    Write-Host -foregroundcolor $COLOR_NORMAL $_.Name

                    . $_
                  }
                } else {
                  Write-Host -foregroundcolor $COLOR_ERROR "    + WARNING: can't find Post-Node Hooks Folder"
                }
              }
            }
          }
        }
      }
    }

    $HookTarget_IsModule {
      switch ( $HookScope ) {
        $HookScope_IsGlobal {
          switch ( $HookTrigger ) {
            $HookTrigger_IsBefore {
              Write-Host -foregroundcolor $COLOR_DARK "    + Pre-Module Global Hooks: "

              if ( Test-Path $GlobalHooksDir\$PreModule_HookDirName ) {
                Get-ChildItem $GlobalHooksDir\$PreModule_HookDirName\*.ps1 -exclude _* | ForEach-Object {
                  Write-Host -foregroundcolor $COLOR_DARK -noNewLine "      + Launching: "
                  Write-Host -foregroundcolor $COLOR_NORMAL $_.Name

                  . $_
                }
              } else {
                Write-Host -foregroundcolor $COLOR_ERROR "      + WARNING: can't find Pre-Module Hooks Folder"
              }
            }

            $HookTrigger_IsAfter {
              Write-Host -foregroundcolor $COLOR_DARK "    + Post-Module Global Hooks: "

              if ( Test-Path $GlobalHooksDir\$PostModule_HookDirName ) {
                Get-ChildItem $GlobalHooksDir\$PostModule_HookDirName\*.ps1 -exclude _* | ForEach-Object {
                  Write-Host -foregroundcolor $COLOR_DARK -noNewLine "      + Launching: "
                  Write-Host -foregroundcolor $COLOR_NORMAL $_.Name

                  . $_
                }
              } else {
                Write-Host -foregroundcolor $COLOR_ERROR "      + WARNING: can't find Post-Module Hooks Folder"
              }
            }
          }
        }

        $HookScope_IsLibrary {
          switch ( $HookTrigger ) {
            $HookTrigger_IsBefore {
              Write-Host -foregroundcolor $COLOR_DARK "    + Pre-Module Library Hooks: "

              $ModulesLibraries | ForEach-Object {
                Write-Host -foregroundcolor $COLOR_DARK "      + Library: $_ ... "

                if ( Test-Path $ModulesDir\$_\$HooksDirName\$PreModule_HookDirName ) {
                  Get-ChildItem $ModulesDir\$_\$HooksDirName\$PreModule_HookDirName\*.ps1 -exclude _* | ForEach-Object {
                    Write-Host -foregroundcolor $COLOR_DARK -noNewLine "        + Launching: "
                    Write-Host -foregroundcolor $COLOR_NORMAL $_.Name

                    . $_
                  }
                } else {
                  Write-Host -foregroundcolor $COLOR_ERROR "      + WARNING: can't find Pre-Module Hooks Folder"
                }
              }
            }

            $HookTrigger_IsAfter {
              Write-Host -foregroundcolor $COLOR_DARK "    + Post-Module Library Hooks: "

              $ModulesLibraries | ForEach-Object {
                Write-Host -foregroundcolor $COLOR_DARK "      + Library: $_ ... "

                if ( Test-Path $ModulesDir\$_\$HooksDirName\$PostModule_HookDirName ) {
                  Get-ChildItem $ModulesDir\$_\$HooksDirName\$PostModule_HookDirName\*.ps1 -exclude _* | ForEach-Object {
                    Write-Host -foregroundcolor $COLOR_DARK -noNewLine "        + Launching: "
                    Write-Host -foregroundcolor $COLOR_NORMAL $_.Name

                    . $_
                  }
                } else {
                  Write-Host -foregroundcolor $COLOR_ERROR "      + WARNING: can't find Post-Module Hooks Folder"
                }
              }
            }
          }
        }
      }
    }

    $HookTarget_IsMContext {
      switch ( $HookScope ) {
        $HookScope_IsGlobal {
          switch ( $HookTrigger ) {
            $HookTrigger_IsBefore {
              Write-Host -foregroundcolor $COLOR_DARK "    + Pre-ModuleContext Global Hooks: "

              if ( Test-Path $GlobalHooksDir\$PreMContext_HookDirName ) {
                Get-ChildItem $GlobalHooksDir\$PreMContext_HookDirName\*.ps1 -exclude _* | ForEach-Object {
                  Write-Host -foregroundcolor $COLOR_DARK -noNewLine "      + Launching: "
                  Write-Host -foregroundcolor $COLOR_NORMAL $_.Name

                  . $_
                }
              } else {
                Write-Host -foregroundcolor $COLOR_ERROR "      + WARNING: can't find Pre-ModuleContext Hooks Folder"
              }
            }

            $HookTrigger_IsAfter {
              Write-Host -foregroundcolor $COLOR_DARK "    + Post-ModuleContext Global Hooks: "

              if ( Test-Path $GlobalHooksDir\$PostMContext_HookDirName ) {
                Get-ChildItem $GlobalHooksDir\$PostMContext_HookDirName\*.ps1 -exclude _* | ForEach-Object {
                  Write-Host -foregroundcolor $COLOR_DARK -noNewLine "      + Launching: "
                  Write-Host -foregroundcolor $COLOR_NORMAL $_.Name

                  . $_
                }
              } else {
                Write-Host -foregroundcolor $COLOR_ERROR "      + WARNING: can't find Post-ModuleContext Hooks Folder"
              }
            }
          }
        }

        $HookScope_IsLibrary {
          switch ( $HookTrigger ) {
            $HookTrigger_IsBefore {
              Write-Host -foregroundcolor $COLOR_DARK "    + Pre-ModuleContext Library Hooks: "

              $ModulesLibraries | ForEach-Object {
                Write-Host -foregroundcolor $COLOR_DARK "      + Library: $_ ... "

                if ( Test-Path $ModulesDir\$_\$HooksDirName\$PreMContext_HookDirName ) {
                  Get-ChildItem $ModulesDir\$_\$HooksDirName\$PreMContext_HookDirName\*.ps1 -exclude _* | ForEach-Object {
                    Write-Host -foregroundcolor $COLOR_DARK -noNewLine "        + Launching: "
                    Write-Host -foregroundcolor $COLOR_NORMAL $_.Name

                    . $_
                  }
                } else {
                  Write-Host -foregroundcolor $COLOR_ERROR "      + WARNING: can't find Pre-ModuleContext Hooks Folder"
                }
              }
            }

            $HookTrigger_IsAfter {
              Write-Host -foregroundcolor $COLOR_DARK "    + Post-ModuleContext Library Hooks: "

              $ModulesLibraries | ForEach-Object {
                Write-Host -foregroundcolor $COLOR_DARK "      + Library: $_ ... "

                if ( Test-Path $ModulesDir\$_\$HooksDirName\$PostMContext_HookDirName ) {
                  Get-ChildItem $ModulesDir\$_\$HooksDirName\$PostMContext_HookDirName\*.ps1 -exclude _* | ForEach-Object {
                    Write-Host -foregroundcolor $COLOR_DARK -noNewLine "        + Launching: "
                    Write-Host -foregroundcolor $COLOR_NORMAL $_.Name

                    . $_
                  }
                } else {
                  Write-Host -foregroundcolor $COLOR_ERROR "      + WARNING: can't find Post-ModuleContext Hooks Folder"
                }
              }
            }
          }
        }
      }
    }
  }

  Write-Host
}
