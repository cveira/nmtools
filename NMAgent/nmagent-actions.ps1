function Start-NMARunTimeAdvisor {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentStartNMARunTimeAdvisorErrorEvent = @"

===========================================================================================
$(get-date -format u) - Start-NMARunTimeAdvisor Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())

"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  + Start-NMARunTimeAdvisor Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentStartNMARunTimeAdvisorErrorEvent >> $ErrorLogFile

    break
  }


  $PLEXModules        = 0
  $DynXModules        = 0
  $PLEXActiveModules  = 0
  $DynXActiveModules  = 0
  $UsingPipeLineInput = $false


  Write-Host
  Write-Host -foregroundcolor $COLOR_BRIGHT '  -------------------------------------------------------------------------------------------'
  Write-Host -foregroundcolor $COLOR_BRIGHT '  NMAgent Run-Time Settings Advisor:'
  Write-Host

  Write-Host -foregroundcolor $COLOR_NORMAL  -noNewLine "  + Analyzing Session Module Settings... "

  if ( $(Get-ChildItem function:PLEX_*).Length -ne $null ) {
    $PLEXModules = $( Get-ChildItem function:PLEX_* | Measure-Object ).Count
  }

  if ( $(Get-ChildItem function:DynX_*).Length -ne $null ) {
    $DynXModules = $( Get-ChildItem function:PLEX_* | Measure-Object ).Count
  }


  if ( $PipeLineInput -ne $null ) { $UsingPipeLineInput = $true }


  $script:NMAModulesKeys | ForEach-Object {
    $CurrentModuleKey  = $_
    $CurrentModuleType = $script:NMAModules.$_[$NMAModules_ModuleName].Split("_")[0]

    switch ( $CurrentModuleType ) {
      "PLEX" {
        $PLEXModules += 1
        if ( $script:NMAModules.$CurrentModuleKey[$NMAModules_IsEnabled] ) { $PLEXActiveModules += 1 }
      }

      "DynX" {
        $DynXModules += 1
        if ( $script:NMAModules.$CurrentModuleKey[$NMAModules_IsEnabled] ) { $DynXActiveModules += 1 }
      }
    }
  }

  Write-Host -foregroundcolor $COLOR_BRIGHT   "done"
  Write-Host

  Write-Host -foregroundcolor $COLOR_NORMAL   "  + Loaded Modules:"
  Write-Host -foregroundcolor $COLOR_NORMAL   -noNewLine "    + Total PLEX Modules:       "
  Write-Host -foregroundcolor $COLOR_BRIGHT   $PLEXModules
  Write-Host -foregroundcolor $COLOR_NORMAL   -noNewLine "    + Total DynX Modules:       "
  Write-Host -foregroundcolor $COLOR_BRIGHT   $DynXModules
  Write-Host

  Write-Host -foregroundcolor $COLOR_NORMAL   "  + Active Modules:"
  Write-Host -foregroundcolor $COLOR_NORMAL   -noNewLine "    + Active PLEX Modules:      "
  Write-Host -foregroundcolor $COLOR_BRIGHT   $PLEXActiveModules
  Write-Host -foregroundcolor $COLOR_NORMAL   -noNewLine "    + Active DynX Modules:      "
  Write-Host -foregroundcolor $COLOR_BRIGHT   $DynXActiveModules
  Write-Host

  Write-Host -foregroundcolor $COLOR_NORMAL   -noNewLine "  + Pipe-Line Input Paramenter: "

  if ( $UsingPipeLineInput ) {
    Write-Host -foregroundcolor $COLOR_BRIGHT "YES"
  } else {
    Write-Host -foregroundcolor $COLOR_BRIGHT "NO"
  }

  Write-Host
  Write-Host -foregroundcolor $COLOR_NORMAL   -noNewLine "  + Potential Run-Time Risks:   "

  if ( $UsingPipeLineInput                                                    -and
       ( ( $PLEXModules       -gt 1 ) -or ( $DynXModules       -gt 1 )        -and
         ( $PLEXActiveModules -gt 1 ) -or ( $DynXActiveModules -gt 1 ) ) ) {
    Write-Host -foregroundcolor $COLOR_ERROR  "YES"
    Write-Host -foregroundcolor $COLOR_ERROR  "    + WARNING: Multiple active Pipe-Line Enabled Modules MUST MATCH a single Pipe-Line paramenter."
    Write-Host -foregroundcolor $COLOR_ERROR  "    + WARNING: Multiple active Pipe-Line Enabled Modules MUST WORK with the same Pipe-Line paramenter."
  } else {
    if ( !$UsingPipeLineInput                                                   -and
         ( ( $PLEXModules       -gt 0 ) -or ( $DynXModules       -gt 0 )        -and
           ( $PLEXActiveModules -gt 0 ) -or ( $DynXActiveModules -gt 0 ) ) ) {
      Write-Host -foregroundcolor $COLOR_ERROR  "YES"
      Write-Host -foregroundcolor $COLOR_ERROR  "    + ERROR: Found active Pipe-Line Enabled Modules AND NO Pipe-Line paramenter supplied."
    } else {
      Write-Host -foregroundcolor $COLOR_RESULT "NO"
    }
  }
}

##############################################################################

function Compare-NMASession( [string] $TargetObject = "last" ) {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentCompareNMASessionEvent = @"

===========================================================================================
$(get-date -format u) - Compare-NMASession Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())

"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  + Compare-NMASession Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentCompareNMASessionEvent >> $ErrorLogFile

    break
  }


  switch -case ( $TargetObject ) {
    $TARGET_SESSION_FIRST {
      Reset-NMASessionStore
      $FirstDT  = $SStoreDT | Select-Object NodeName, NodePropertyName, NodeAttributeName, NodeValue

      Reset-NMASessionStore 'all'
      Reset-NMASessionStore 'second'
      $SecondDT = $SStoreDT | Select-Object NodeName, NodePropertyName, NodeAttributeName, NodeValue
    }

    $TARGET_SESSION_LAST {
      Reset-NMASessionStore
      $FirstDT  = $SStoreDT | Select-Object NodeName, NodePropertyName, NodeAttributeName, NodeValue

      Reset-NMASessionStore 'all'
      Reset-NMASessionStore 'penultimate'
      $SecondDT = $SStoreDT | Select-Object NodeName, NodePropertyName, NodeAttributeName, NodeValue
    }

    default {
      Reset-NMASessionStore $($TargetObject.Split($MULTI_SESSION_DELIMITER)[0])
      $FirstDT  = $SStoreDT | Select-Object NodeName, NodePropertyName, NodeAttributeName, NodeValue

      Reset-NMASessionStore 'all'
      Reset-NMASessionStore $($TargetObject.Split($MULTI_SESSION_DELIMITER)[1])
      $SecondDT = $SStoreDT | Select-Object NodeName, NodePropertyName, NodeAttributeName, NodeValue
    }
  }


  CompareData $FirstDT $SecondDT
}

##############################################################################

function Analyze-NMASession( [string] $TargetObject = "all" ) {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentAnalyzeNMASessionEvent = @"

===========================================================================================
$(get-date -format u) - Analyze-NMASession Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())

"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  + Analyze-NMASession Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentAnalyzeNMASessionEvent >> $ErrorLogFile

    break
  }


  Reset-NMASessionStore
  AnalyzeData
}

##############################################################################

function Get-NMASessionItems([string] $TargetObject = "all", [string] $filter = "", [string] $SelectedView = $VIEW_SIMPLE ) {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentQueryNMASessionEvent = @"

===========================================================================================
$(get-date -format u) - Get-NMASessionItems Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())

"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  + Get-NMASessionItems Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentQueryNMASessionEvent >> $ErrorLogFile

    break
  }


  Reset-NMASessionStore


  switch -case ( $SelectedView.ToLower() ) {
    $VIEW_SIMPLE {
      if ( $DisableFormatOutput ) {
        $SStoreDT | Select-Object RecordDate, NodeName, NodePropertyName, NodeAttributeName, NodeValue, NodeExtendedAttributes | Group-Object SessionId
      } else {
        $SStoreDT | Format-Table RecordDate, NodeName, NodePropertyName, NodeAttributeName, NodeValue, NodeExtendedAttributes -autosize -groupby SessionId
      }
    }

    $VIEW_ERRORS {
      if ( $DisableFormatOutput ) {
        $SStoreDT | Select-Object RecordDate, NodeName, NodePropertyName, NodeAttributeName, ErrorFound, ErrorText | Group-Object SessionId
      } else {
        $SStoreDT | Format-Table RecordDate, NodeName, NodePropertyName, NodeAttributeName, ErrorFound, ErrorText -autosize -groupby SessionId
      }
    }

    $VIEW_MEMO   {
      if ( $DisableFormatOutput ) {
        $SStoreDT | Select-Object RecordDate, NodeName, NodePropertyName, NodeAttributeName, NodeExtendedAttributes, NodeValue_Memo | Group-Object SessionId
      } else {
        $SStoreDT | Format-List RecordDate, NodeName, NodePropertyName, NodeAttributeName, NodeExtendedAttributes, NodeValue_Memo -groupby SessionId
      }
    }

    $VIEW_RAW    {
      if ( $DisableFormatOutput ) {
        $SStoreDT | Select-Object RecordDate, NodeName, NodePropertyName, NodeAttributeName, NodeExtendedAttributes, NodeQueryOutput | Group-Object SessionId
      } else {
        $SStoreDT | Format-List RecordDate, NodeName, NodePropertyName, NodeAttributeName, NodeExtendedAttributes, NodeQueryOutput -groupby SessionId
      }
    }

    $VIEW_AGENTS {
      if ( $DisableFormatOutput ) {
        $SStoreDT | Select-Object RecordDate, AgentNodeName, NodeName, NodePropertyName, NodeAttributeName, NodeValue | Group-Object SessionId
      } else {
        $SStoreDT | Format-Table RecordDate, AgentNodeName, NodeName, NodePropertyName, NodeAttributeName, NodeValue -autosize -groupby SessionId
      }
    }

    $VIEW_USERS  {
      if ( $DisableFormatOutput ) {
        $SStoreDT | Select-Object RecordDate, AgentUserName, NodeName, NodePropertyName, NodeAttributeName, NodeValue | Group-Object SessionId
      } else {
        $SStoreDT | Format-Table RecordDate, AgentUserName, NodeName, NodePropertyName, NodeAttributeName, NodeValue -autosize -groupby SessionId
      }
    }
  }
}

##############################################################################

function Export-NMASession([string] $TargetObject = "all", [string] $filter = "") {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentExportNMASessionEvent = @"

===========================================================================================
$(get-date -format u) -  Export-NMASession Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())

"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  +  Export-NMASession Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentExportNMASessionEvent >> $ErrorLogFile

    break
  }


  switch -case ($TargetObject.ToLower()) {
    $TARGET_SESSION_ALL {
      [string] $ExportFile = "$InstallDir\$ExportDirName\NMAgent-" + $($SessionId -replace "-", "") + "-" + $TARGET_SESSION_ALL
    }

    $TARGET_SESSION_FIRST {
      [string] $ExportFile = "$InstallDir\$ExportDirName\NMAgent-" + $($SessionId -replace "-", "") + "-" + $TARGET_SESSION_FIRST
    }

    $TARGET_SESSION_LAST {
      [string] $ExportFile = "$InstallDir\$ExportDirName\NMAgent-" + $($SessionId -replace "-", "") + "-" + $TARGET_SESSION_LAST
    }

    default {
      [string] $ExportFile = "$InstallDir\$ExportDirName\NMAgent-" + $($SessionId -replace "-", "") + "-" + $($TargetObject.ToLower() -replace "(\%|\*|\?|-)", "")
    }
  }


  if ( ( $store -ne $null ) -and ( $store -ne "" ) -and ( $store.Length -ne 0 ) ) {
    if ( Test-NMAOfflineStore $store ) {
      Write-Host
      Write-Host -foregroundcolor $COLOR_NORMAL  "  + Selected Archived Contents: " -noNewLine
      Write-Host -foregroundcolor $COLOR_BRIGHT  "Session [$( $TargetObject.ToLower() )] @ Off-Line Store [$store]"
      Write-Host

      Write-Host -foregroundcolor $COLOR_NORMAL  "  + Destination Export File:      " -noNewLine

      switch -case ( $view.ToLower() ) {
        $VIEW_SIMPLE {
          Write-Host -foregroundcolor $COLOR_BRIGHT  $( $ExportFile + ".csv" )
          Write-Host -foregroundcolor $COLOR_DARK    "    + Export Operation...         " -noNewLine

          Get-NMAOfflineSessionItems $store $TargetObject.ToLower() | Select-Object SessionId, RecordDate, NodeName, NodePropertyName, NodeAttributeName, NodeValue, NodeExtendedAttributes | Export-CSV $( $ExportFile + ".csv" )
        }

        $VIEW_ERRORS {
          Write-Host -foregroundcolor $COLOR_BRIGHT  $( $ExportFile + ".csv" )
          Write-Host -foregroundcolor $COLOR_DARK    "    + Export Operation...         " -noNewLine

          Get-NMAOfflineSessionItems $store $TargetObject.ToLower() | Select-Object SessionId, RecordDate, NodeName, NodePropertyName, NodeAttributeName, ErrorFound, ErrorText | Export-CSV $( $ExportFile + ".csv" )
        }

        $VIEW_MEMO   {
          Write-Host -foregroundcolor $COLOR_BRIGHT  $( $ExportFile + ".txt" )
          Write-Host -foregroundcolor $COLOR_DARK    "    + Export Operation...         " -noNewLine

          Get-NMAOfflineSessionItems $store $TargetObject.ToLower() | Format-List RecordDate, NodeName, NodePropertyName, NodeAttributeName, NodeExtendedAttributes, NodeValue_Memo -groupby SessionId | Out-File $( $ExportFile + ".txt" ) -Append -NoClobber
        }

        $VIEW_RAW    {
          Write-Host -foregroundcolor $COLOR_BRIGHT  $( $ExportFile + ".txt" )
          Write-Host -foregroundcolor $COLOR_DARK    "    + Export Operation...         " -noNewLine

          Get-NMAOfflineSessionItems $store $TargetObject.ToLower() | Format-List RecordDate, NodeName, NodePropertyName, NodeAttributeName, NodeExtendedAttributes, NodeQueryOutput -groupby SessionId | Out-File $( $ExportFile + ".txt" ) -Append -NoClobber
        }

        $VIEW_AGENTS {
          Write-Host -foregroundcolor $COLOR_BRIGHT  $( $ExportFile + ".csv" )
          Write-Host -foregroundcolor $COLOR_DARK    "    + Export Operation...         " -noNewLine

          Get-NMAOfflineSessionItems $store $TargetObject.ToLower() | Select-Object SessionId, RecordDate, AgentNodeName, NodeName, NodePropertyName, NodeAttributeName, NodeValue | Export-CSV $( $ExportFile + ".csv" )
        }

        $VIEW_USERS  {
          Write-Host -foregroundcolor $COLOR_BRIGHT  $( $ExportFile + ".csv" )
          Write-Host -foregroundcolor $COLOR_DARK    "    + Export Operation...         " -noNewLine

          Get-NMAOfflineSessionItems $store $TargetObject.ToLower() | Select-Object SessionId, RecordDate, AgentUserName, NodeName, NodePropertyName, NodeAttributeName, NodeValue | Export-CSV $( $ExportFile + ".csv" )
        }
      }
    }
  } else {
    Write-Host
    Write-Host -foregroundcolor $COLOR_NORMAL  "  + Destination Export File:      " -noNewLine

    Reset-NMASessionStore

    switch -case ( $view.ToLower() ) {
      $VIEW_SIMPLE {
        Write-Host -foregroundcolor $COLOR_BRIGHT  $( $ExportFile + ".csv" )
        Write-Host -foregroundcolor $COLOR_DARK    "    + Export Operation...         " -noNewLine

        $SStoreDT | Select-Object SessionId, RecordDate, NodeName, NodePropertyName, NodeAttributeName, NodeValue, NodeExtendedAttributes | Export-CSV $( $ExportFile + ".csv" )
      }

      $VIEW_ERRORS {
        Write-Host -foregroundcolor $COLOR_BRIGHT  $( $ExportFile + ".csv" )
        Write-Host -foregroundcolor $COLOR_DARK    "    + Export Operation...         " -noNewLine

        $SStoreDT | Select-Object SessionId, RecordDate, NodeName, NodePropertyName, NodeAttributeName, ErrorFound, ErrorText | Export-CSV $( $ExportFile + ".csv" )
      }

      $VIEW_MEMO   {
        Write-Host -foregroundcolor $COLOR_BRIGHT  $( $ExportFile + ".txt" )
        Write-Host -foregroundcolor $COLOR_DARK    "    + Export Operation...         " -noNewLine

        $SStoreDT | Format-List RecordDate, NodeName, NodePropertyName, NodeAttributeName, NodeExtendedAttributes, NodeValue_Memo -groupby SessionId | Out-File $( $ExportFile + ".txt" ) -Append -NoClobber
      }

      $VIEW_RAW    {
        Write-Host -foregroundcolor $COLOR_BRIGHT  $( $ExportFile + ".txt" )
        Write-Host -foregroundcolor $COLOR_DARK    "    + Export Operation...         " -noNewLine

        $SStoreDT | Format-List RecordDate, NodeName, NodePropertyName, NodeAttributeName, NodeExtendedAttributes, NodeQueryOutput -groupby SessionId | Out-File $( $ExportFile + ".txt" ) -Append -NoClobber
      }

      $VIEW_AGENTS {
        Write-Host -foregroundcolor $COLOR_BRIGHT  $( $ExportFile + ".csv" )
        Write-Host -foregroundcolor $COLOR_DARK    "    + Export Operation...         " -noNewLine

        $SStoreDT | Select-Object SessionId, RecordDate, AgentNodeName, NodeName, NodePropertyName, NodeAttributeName, NodeValue | Export-CSV $( $ExportFile + ".csv" )
      }

      $VIEW_USERS  {
        Write-Host -foregroundcolor $COLOR_BRIGHT  $( $ExportFile + ".csv" )
        Write-Host -foregroundcolor $COLOR_DARK    "    + Export Operation...         " -noNewLine

        $SStoreDT | Select-Object SessionId, RecordDate, AgentUserName, NodeName, NodePropertyName, NodeAttributeName, NodeValue | Export-CSV $( $ExportFile + ".csv" )
      }
    }
  }


  Write-Host -foregroundcolor $COLOR_RESULT  "done"
  Write-Host
}

##############################################################################

function Update-NMASession([string] $TargetObject = "all", [string] $filter = "") {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentUPdateNMASessionEvent = @"

===========================================================================================
$(get-date -format u) -  Update-NMASession Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())

"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  +  Update-NMASession Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentUPdateNMASessionEvent >> $ErrorLogFile

    # break
    continue
  }


  Reset-NMASessionStore


  $SelectedItems = $SStoreDT

  if ( $SelectedItems -ne $null ) {
    [object[]] $ItemsCollection = $SelectedItems

    UpdateCMDB($ItemsCollection)
  } else {
    Write-Host -foregroundcolor $COLOR_ERROR "  + CMDB Update Aborted: the specified Session could not be found"
    break
  }
}

##############################################################################

function Get-NMASession([string] $TargetObject = "all") {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentGetNMASessionEvent = @"

===========================================================================================
$(get-date -format u) -  Get-NMASession Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())

"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  +  Get-NMASession Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentGetNMASessionEvent >> $ErrorLogFile

    break
  }


  switch -case ($TargetObject.ToLower()) {
    $TARGET_SESSION_ALL {
      $SStoreDT | Select-Object SessionId -unique
    }

    $TARGET_SESSION_FIRST {
      $($SStoreDT | Select-Object -first 1).SessionId
    }

    $TARGET_SESSION_LAST {
      $($SStoreDT | Select-Object -last 1).SessionId
    }

    default {
      Reset-NMASessionStore
      $SStoreDT | Select-Object SessionId -unique
    }
  }
}

##############################################################################

function Remove-NMASession([string] $TargetObject = "all", [string] $filter = "") {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentRemoveNMASessionEvent = @"

===========================================================================================
$(get-date -format u) -  Remove-NMASession Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())

"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  +  Remove-NMASession Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentRemoveNMASessionEvent >> $ErrorLogFile

    break
  }


  Reset-NMASessionStore


  $SelectedItems = $SStoreDT

  if ( $SelectedItems -ne $null ) {
    [object[]] $ItemsCollection = $SelectedItems

    PurgeSStore($ItemsCollection)
  } else {
    Write-Host -foregroundcolor $COLOR_ERROR "  + Session Clean up Aborted: the specified Session could not be found"
    break
  }
}

##############################################################################

function Start-NMAScanNetwork([string] $TargetObject = "") {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentStartNMAScanNetworkEvent = @"

===========================================================================================
$(get-date -format u) -  Start-NMAScanNetwork Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())

"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  +  Start-NMAScanNetwork Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentStartNMAScanNetworkEvent >> $ErrorLogFile

    break
  }


  if ($TargetObject.ToLower() -eq "") {
    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  # Error Processing Network: No Input Network was supplied."
    Write-Host

    break
  }


  Write-Host
  Write-Host -foregroundcolor $COLOR_BRIGHT "  # Processing Network:      " $TargetObject.ToLower()
  Write-Host

  $IsIPRangeFormat = $false

  if ( $TargetObject.ToLower() -match $REGEX_NWRANGE ) {
    $IsIPRangeFormat = $true

    $StartIP                 = $($TargetObject.ToLower().Split("-"))[0]
    [int] $StartNodeIPOctect = $StartIP.Split(".")[3]
    [int] $EndNodeIPOctect   = $($TargetObject.ToLower().Split("-"))[1]
    $NetworkIP               = $StartIP.Split(".")[0] + "." + $StartIP.Split(".")[1] + "." + $StartIP.Split(".")[2]

    $NodeList                = $StartNodeIPOctect..$EndNodeIPOctect | ForEach-Object { $NetworkIP + $_ }
  } else {
    $NodeList                = Get-IPRange $TargetObject.ToLower() -AsString
  }

  if ($NodeList.Length -eq 0) {
      Write-Host
      Write-Host -foregroundcolor $COLOR_ERROR  "  # Processing Node:        No Nodes to process."
      Write-Host
  } else {
    [datetime] $NodeStartTime   = Get-Date
    [datetime] $NodeEndTime     = $NodeStartTime
    [timespan] $NodeElapsedTime = New-TimeSpan $NodeStartTime
    [timespan] $NodeAverageTime = $NodeElapsedTime

    for ($i=0;$i -lt $NodeList.Length;$i++) {
      $SkipTarget    = $false

      $TargetObject  = $NodeList[$i].Trim().ToLower()

      $NodeStartTime = Get-Date

      if ( ($i % $StatsDisplayFrequency) -eq 0 ) {
        Write-Host
        Write-Host -foregroundcolor $COLOR_DARK "  -------------------------------------------------------------------------------------------"
        Write-Host -foregroundcolor $COLOR_DARK "  + Processed Nodes:            $i"
        Write-Host -foregroundcolor $COLOR_DARK "  + Pending Nodes:              $($NodeList.Length - $i)"
        Write-Host -foregroundcolor $COLOR_DARK "  + Last Node Elapsed Time:     $( $NodeElapsedTime.ToString() )"
        Write-Host -foregroundcolor $COLOR_DARK "  + Average Time per Node:      $( $NodeAverageTime.ToString() )"
        Write-Host -foregroundcolor $COLOR_DARK "  + Estimated Time to Complete: $( $(GetTimeToComplete $NodeAverageTime $($NodeList.Length - $i)).ToString() )"
        Write-Host -foregroundcolor $COLOR_DARK "  -------------------------------------------------------------------------------------------"
        Write-Host
      }

      Write-Host
      Write-Host -foregroundcolor $COLOR_BRIGHT -noNewLine "  # Processing Node:       " $TargetObject.ToLower()
      Write-Host -foregroundcolor $COLOR_DARK   -noNewLine "  [Global Progress:" $( '{0:p}' -f $($($i+1)/$NodeList.Length) )
      Write-Host -foregroundcolor $COLOR_DARK              " `($($i+1)`/$($NodeList.Length)`)]"
      Write-Host

      $NodeStatus = $(Get-WmiObject -Class Win32_PingStatus -Filter "Address='$TargetObject'" | Select-Object -Property Address, ProtocolAddress, ResponseTime, StatusCode)

      if ( $NodeStatus.StatusCode -eq $STATUS_NODE_ISALIVE ) {
        if ( $TargetObject -match $REGEX_IP ) {
          $TargetIP   = $TargetObject

          [string] $TargetName = $([System.Net.Dns]::GetHostByAddress('$TargetObject')).HostName
          if ( ($TargetName -eq $null) -or ($TargetName.Length -eq 0) ) { [string] $TargetName = $UNKNOWN_HOSTNAME }
        } else {
          [string] $TargetName = $TargetObject
          $TargetIP            = $NodeStatus.ProtocolAddress
        }
      } else {
        $SkipTarget = $true

        Write-Host -foregroundcolor $COLOR_ERROR "  + Skipping Node:          Unable to confirm if Node is alive"
        Write-Host
      }

      if (-not $SkipTarget) {
        ScanNode $TargetName $TargetIP
      } else {
        $TargetObject >> $SkippedNodesFile
      }

      $NodeEndTime     = Get-Date
      $NodeElapsedTime = New-TimeSpan $NodeStartTime
      $NodeAverageTime = GetNodeAverageTime $NodeAverageTime $NodeElapsedTime
    }
  }
}

##############################################################################

function Start-NMAScanHost([string] $TargetObject = "") {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentStartNMAScanHostEvent = @"

===========================================================================================
$(get-date -format u) -  Start-NMAScanHost Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())

"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  +  Start-NMAScanHost Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentStartNMAScanHostEvent >> $ErrorLogFile

    break
  }


  if ($TargetObject.ToLower() -eq "") {
    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  # Error Processing Host:    No Input Host Name was supplied."
    Write-Host

    break
  }

  [string[]] $NodeList = $TargetObject.ToLower().Split(",")

  if ($NodeList.Length -eq 0) {
      Write-Host
      Write-Host -foregroundcolor $COLOR_ERROR  "  # Processing Node:        No Nodes to process."
      Write-Host
  } else {
    [datetime] $NodeStartTime   = Get-Date
    [datetime] $NodeEndTime     = $NodeStartTime
    [timespan] $NodeElapsedTime = New-TimeSpan $NodeStartTime
    [timespan] $NodeAverageTime = $NodeElapsedTime

    for ($i=0;$i -lt $NodeList.Length;$i++) {
      $SkipTarget = $false

      $TargetObject  = $NodeList[$i].Trim().ToLower()

      $NodeStartTime = Get-Date

      if ( ($i % $StatsDisplayFrequency) -eq 0 ) {
        Write-Host
        Write-Host -foregroundcolor $COLOR_DARK "  -------------------------------------------------------------------------------------------"
        Write-Host -foregroundcolor $COLOR_DARK "  + Processed Nodes:            $i"
        Write-Host -foregroundcolor $COLOR_DARK "  + Pending Nodes:              $($NodeList.Length - $i)"
        Write-Host -foregroundcolor $COLOR_DARK "  + Last Node Elapsed Time:     $( $NodeElapsedTime.ToString() )"
        Write-Host -foregroundcolor $COLOR_DARK "  + Average Time per Node:      $( $NodeAverageTime.ToString() )"
        Write-Host -foregroundcolor $COLOR_DARK "  + Estimated Time to Complete: $( $(GetTimeToComplete $NodeAverageTime $($NodeList.Length - $i)).ToString() )"
        Write-Host -foregroundcolor $COLOR_DARK "  -------------------------------------------------------------------------------------------"
        Write-Host
      }

      Write-Host
      Write-Host -foregroundcolor $COLOR_BRIGHT -noNewLine "  # Processing Node:       " $TargetObject
      Write-Host -foregroundcolor $COLOR_DARK   -noNewLine "  [Global Progress:" $( '{0:p}' -f $($($i+1)/$NodeList.Length) )
      Write-Host -foregroundcolor $COLOR_DARK              " `($($i+1)`/$($NodeList.Length)`)]"
      Write-Host

      $NodeStatus = Get-WmiObject -Class Win32_PingStatus -Filter "Address='$TargetObject'" | Select-Object -Property Address, ProtocolAddress, ResponseTime, StatusCode

      if ( $NodeStatus.StatusCode -eq $STATUS_NODE_ISALIVE ) {
        if ( $TargetObject -match $REGEX_IP ) {
          $TargetIP   = $TargetObject

          [string] $TargetName = $([System.Net.Dns]::GetHostByAddress('$TargetObject')).HostName
          if ( ($TargetName -eq $null) -or ($TargetName.Length -eq 0) ) { [string] $TargetName = $UNKNOWN_HOSTNAME }
        } else {
          [string] $TargetName = $TargetObject.ToLower()
          $TargetIP            = $NodeStatus.ProtocolAddress
        }
      } else {
        $SkipTarget = $true

        Write-Host -foregroundcolor $COLOR_ERROR "  + Skipping Node:          Unable to confirm if Node is alive"
        Write-Host
      }

      if (-not $SkipTarget) {
        ScanNode $TargetName $TargetIP
      } else {
        $TargetObject.ToLower() >> $SkippedNodesFile
      }


      $NodeEndTime     = Get-Date
      $NodeElapsedTime = New-TimeSpan $NodeStartTime
      $NodeAverageTime = GetNodeAverageTime $NodeAverageTime $NodeElapsedTime
    }
  }
}

##############################################################################

function Start-NMAScanFromFile([string] $TargetObject = "") {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentStartNMAScanFromFileEvent = @"

===========================================================================================
$(get-date -format u) -  Start-NMAScanFromFile Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())

"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  +  Start-NMAScanFromFile Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentStartNMAScanFromFileEvent >> $ErrorLogFile

    break
  }


  [string[]] $NodeList       = @()
  [string[]] $ValidInputFile = @()

  if ( $TargetObject.ToLower() -ne "" ) {
    if ( "$($TargetObject.ToLower())".Contains(":") ) {
      $ValidInputFile += "$($TargetObject.ToLower())"
    } else {
      $ValidInputFile += "$DefaultInputFilePath\$($TargetObject.ToLower())"
    }

    foreach ( $Library in $ModulesLibraries ) { $ValidInputFile +=  "$ModulesDir\$Library\_settings\$($TargetObject.ToLower())" }
    $ValidInputFile   += $DefaultInputFile

    $FoundInputFile = $false
    $ValidInputFile | ForEach-Object {
      if ( !$FoundInputFile ) {
        if ( Test-Path $_ ) {
          $FoundInputFile  = $true
          $InputFile       = $_
        }
      }
    }

    if ( $FoundInputFile ) {
      [string[]] $NodeList = Get-Content $(Get-Item $InputFile).FullName -encoding string
    } else {
      Write-Host
      Write-Host -foregroundcolor $COLOR_ERROR  "  # INFO: No Input File was supplied."
      Write-Host
    }
  } else {
    if ( Test-Path $DefaultInputFile ) {
      $InputFile           = $DefaultInputFile
      [string[]] $NodeList = Get-Content $(Get-Item $InputFile).FullName -encoding string
    } else {
      Write-Host
      Write-Host -foregroundcolor $COLOR_ERROR  "  # INFO: No Input File was supplied."
      Write-Host
    }
  }


  if ( $MergeInputFiles ) {
    Write-Host -foregroundcolor $COLOR_NORMAL "  + Merging Input Files from Libraries:"

    foreach ( $Library in $ModulesLibraries ) {
      Write-Host -foregroundcolor $COLOR_NORMAL -noNewLine "    + Library: "
      Write-Host -foregroundcolor $COLOR_BRIGHT $Library

      if ( Test-Path $ModulesDir\$Library ) {
        Get-ChildItem $ModulesDir\$Library\_settings\*.txt -exclude _* | ForEach-Object {
          Write-Host -foregroundcolor $COLOR_NORMAL -noNewLine "      + Loading:" $_.Name "... "

          if ( Test-Path $_ ) {
            [string[]] $NodeList += Get-Content $(Get-Item $_).FullName -encoding string
            Write-Host -foregroundcolor $COLOR_BRIGHT "done"
          } else {
            Write-Host -foregroundcolor $COLOR_ERROR  "N/A"
          }
        }
      } else {
        Write-Host -foregroundcolor $COLOR_ERROR "      + Skipping Library: [$Library] does not exist"
      }
    }
  }

  if ($NodeList.Length -eq 0) {
      Write-Host
      Write-Host -foregroundcolor $COLOR_ERROR  "  # ERROR: No Nodes to process."
      Write-Host
  } else {
    [datetime] $NodeStartTime   = Get-Date
    [datetime] $NodeEndTime     = $NodeStartTime
    [timespan] $NodeElapsedTime = New-TimeSpan $NodeStartTime
    [timespan] $NodeAverageTime = $NodeElapsedTime

    [string[]] $NodeList        = $NodeList | Select-Object -unique


    for ($i=0;$i -lt $NodeList.Length;$i++) {
      $SkipTarget    = $false

      $TargetObject  = $NodeList[$i].Trim().ToLower()

      $NodeStartTime = Get-Date

      if ( ($i % $StatsDisplayFrequency) -eq 0 ) {
        Write-Host
        Write-Host -foregroundcolor $COLOR_DARK "  -------------------------------------------------------------------------------------------"
        Write-Host -foregroundcolor $COLOR_DARK "  + Processed Nodes:            $i"
        Write-Host -foregroundcolor $COLOR_DARK "  + Pending Nodes:              $($NodeList.Length - $i)"
        Write-Host -foregroundcolor $COLOR_DARK "  + Last Node Elapsed Time:     $( $NodeElapsedTime.ToString() )"
        Write-Host -foregroundcolor $COLOR_DARK "  + Average Time per Node:      $( $NodeAverageTime.ToString() )"
        Write-Host -foregroundcolor $COLOR_DARK "  + Estimated Time to Complete: $( $(GetTimeToComplete $NodeAverageTime $($NodeList.Length - $i)).ToString() )"
        Write-Host -foregroundcolor $COLOR_DARK "  -------------------------------------------------------------------------------------------"
        Write-Host
      }

      Write-Host
      Write-Host -foregroundcolor $COLOR_BRIGHT -noNewLine "  # Processing Node:       " $TargetObject
      Write-Host -foregroundcolor $COLOR_DARK   -noNewLine "  [Global Progress:" $( '{0:p}' -f $($($i+1)/$NodeList.Length) )
      Write-Host -foregroundcolor $COLOR_DARK              " `($($i+1)`/$($NodeList.Length)`)]"
      Write-Host

      $NodeStatus   = Get-WmiObject -Class Win32_PingStatus -Filter "Address='$TargetObject'" | Select-Object -Property Address, ProtocolAddress, ResponseTime, StatusCode

      if ( $NodeStatus.StatusCode -eq $STATUS_NODE_ISALIVE ) {
        if ( $TargetObject -match $REGEX_IP ) {
          $TargetIP   = $TargetObject

          [string] $TargetName = $([System.Net.Dns]::GetHostByAddress('$TargetObject')).HostName
          if ( ($TargetName -eq $null) -or ($TargetName.Length -eq 0) ) { [string] $TargetName = $UNKNOWN_HOSTNAME }
        } else {
          [string] $TargetName = $TargetObject
          $TargetIP            = $NodeStatus.ProtocolAddress
        }
      } else {
        $SkipTarget = $true

        Write-Host -foregroundcolor $COLOR_ERROR "  + Skipping Node:          Unable to confirm if Node is alive"
        Write-Host
      }

      if (-not $SkipTarget) {
        ScanNode $TargetName $TargetIP
      } else {
        $TargetObject >> $SkippedNodesFile
      }

      $NodeEndTime     = Get-Date
      $NodeElapsedTime = New-TimeSpan $NodeStartTime
      $NodeAverageTime = GetNodeAverageTime $NodeAverageTime $NodeElapsedTime
    }
  }
}

##############################################################################

function Start-NMAScanFromDb() {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentStartNMAScanFromDbEvent = @"

===========================================================================================
$(get-date -format u) -  Start-NMAScanFromDb Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())

"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  +  Start-NMAScanFromDb Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentStartNMAScanFromDbEvent >> $ErrorLogFile

    break
  }


  if ( $NodesDT -ne $null ) {
    $i                          = 0
    $TotalNodes                 = $($NodesDT | Measure-Object).Count

    [datetime] $NodeStartTime   = Get-Date
    [datetime] $NodeEndTime     = $NodeStartTime
    [timespan] $NodeElapsedTime = New-TimeSpan $NodeStartTime
    [timespan] $NodeAverageTime = $NodeElapsedTime


    $NodesDT | ForEach-Object {
      $SkipTarget    = $false

      $TargetObject  = $_.NodeName.Trim().ToLower()
      $TargetIP      = $_.AdminIP.Trim()

      $NodeStartTime = Get-Date

      if ( ($i % $StatsDisplayFrequency) -eq 0 ) {
        Write-Host
        Write-Host -foregroundcolor $COLOR_DARK "  -------------------------------------------------------------------------------------------"
        Write-Host -foregroundcolor $COLOR_DARK "  + Processed Nodes:            $i"
        Write-Host -foregroundcolor $COLOR_DARK "  + Pending Nodes:              $($TotalNodes - $i)"
        Write-Host -foregroundcolor $COLOR_DARK "  + Last Node Elapsed Time:     $( $NodeElapsedTime.ToString() )"
        Write-Host -foregroundcolor $COLOR_DARK "  + Average Time per Node:      $( $NodeAverageTime.ToString() )"
        Write-Host -foregroundcolor $COLOR_DARK "  + Estimated Time to Complete: $( $(GetTimeToComplete $NodeAverageTime $($TotalNodes - $i)).ToString() )"
        Write-Host -foregroundcolor $COLOR_DARK "  -------------------------------------------------------------------------------------------"
        Write-Host
      }

      Write-Host
      Write-Host -foregroundcolor $COLOR_BRIGHT -noNewLine "  # Processing Node:       " $TargetObject
      Write-Host -foregroundcolor $COLOR_DARK   -noNewLine "  [Global Progress:" $( '{0:p}' -f $($($i+1)/$TotalNodes) )
      Write-Host -foregroundcolor $COLOR_DARK              " `($($i+1)`/$TotalNodes`)]"
      Write-Host

      $NodeStatus   = Get-WmiObject -Class Win32_PingStatus -Filter "Address='$TargetObject'" | Select-Object -Property Address, ProtocolAddress, ResponseTime, StatusCode

      if ( $NodeStatus.StatusCode -eq $STATUS_NODE_ISALIVE ) {
        if ( $TargetObject -match $REGEX_IP ) {
          Write-Host -foregroundcolor $COLOR_ERROR "  + NodeName is an IP:      Trying to get DNS Name"
          Write-Host

          if ( $TargetObject -ne "0.0.0.0" ) {
            $TargetIP   = $TargetObject
          } else {
            $SkipTarget = $true

            Write-Host -foregroundcolor $COLOR_ERROR "  + Skipping Node:          Can't connect to 0.0.0.0"
            Write-Host
          }

          [string] $TargetName = $([System.Net.Dns]::GetHostByAddress('$TargetObject')).HostName
          if ( ($TargetName -eq $null) -or ($TargetName.Length -eq 0) ) { [string] $TargetName = $UNKNOWN_HOSTNAME }
        } else {
          [string] $TargetName = $TargetObject

          if ( $NodeStatus.ProtocolAddress -ne $TargetIP ) {
            if ( $TargetIP -ne "0.0.0.0" ) {
              Write-Host -foregroundcolor $COLOR_ERROR "  + NodeName resolved IP:   $($NodeStatus.ProtocolAddress)"
              Write-Host -foregroundcolor $COLOR_ERROR "  + NodeName AdminIP:       $TargetIP"
              Write-Host -foregroundcolor $COLOR_ERROR "  + Selected IP:            $TargetIP"
              Write-Host
            } else {
              Write-Host -foregroundcolor $COLOR_ERROR "  + NodeName resolved IP:   $($NodeStatus.ProtocolAddress)"
              Write-Host -foregroundcolor $COLOR_ERROR "  + NodeName AdminIP:       $TargetIP"
              Write-Host -foregroundcolor $COLOR_ERROR "  + Selected IP:            $($NodeStatus.ProtocolAddress)"
              Write-Host

              $TargetIP = $NodeStatus.ProtocolAddress
            }
          }
        }
      } else {
        $SkipTarget = $true

        Write-Host -foregroundcolor $COLOR_ERROR "  + Skipping Node:          Unable to confirm if Node is alive"
        Write-Host
      }

      if (-not $SkipTarget) {
        ScanNode $TargetName $TargetIP
      } else {
        $TargetObject >> $SkippedNodesFile
      }

      $NodeEndTime     = Get-Date
      $NodeElapsedTime = New-TimeSpan $NodeStartTime
      $NodeAverageTime = GetNodeAverageTime $NodeAverageTime $NodeElapsedTime
      $i++
    }
  } else {
    Write-Host -foregroundcolor $COLOR_ERROR "  + Skipping Session:       Selected Data Set is empty"
    Write-Host
  }
}

##############################################################################

function Start-NMAScanFromSession() {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentStartNMAScanFromSessionEvent = @"

===========================================================================================
$(get-date -format u) -  Start-NMAScanFromSession Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())

"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  +  Start-NMAScanFromSession Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentStartNMAScanFromSessionEvent >> $ErrorLogFile

    break
  }


  Reset-NMASessionStore
  $SessionDT                  = $SStoreDT | Select-Object NodeName, NodeIP -unique

  if ( $SessionDT -ne $null ) {
    Reset-NMASessionStore 'all'

    $i                          = 0
    $TotalNodes                 = $($SessionDT | Measure-Object).Count

    [datetime] $NodeStartTime   = Get-Date
    [datetime] $NodeEndTime     = $NodeStartTime
    [timespan] $NodeElapsedTime = New-TimeSpan $NodeStartTime
    [timespan] $NodeAverageTime = $NodeElapsedTime


    $SessionDT | ForEach-Object {
      $SkipTarget    = $false

      $TargetObject  = $_.NodeName.Trim().ToLower()
      $TargetIP      = $_.NodeIP.Trim()

      $NodeStartTime = Get-Date

      if ( ($i % $StatsDisplayFrequency) -eq 0 ) {
        Write-Host
        Write-Host -foregroundcolor $COLOR_DARK "  -------------------------------------------------------------------------------------------"
        Write-Host -foregroundcolor $COLOR_DARK "  + Processed Nodes:            $i"
        Write-Host -foregroundcolor $COLOR_DARK "  + Pending Nodes:              $($TotalNodes - $i)"
        Write-Host -foregroundcolor $COLOR_DARK "  + Last Node Elapsed Time:     $( $NodeElapsedTime.ToString() )"
        Write-Host -foregroundcolor $COLOR_DARK "  + Average Time per Node:      $( $NodeAverageTime.ToString() )"
        Write-Host -foregroundcolor $COLOR_DARK "  + Estimated Time to Complete: $( $(GetTimeToComplete $NodeAverageTime $($TotalNodes - $i)).ToString() )"
        Write-Host -foregroundcolor $COLOR_DARK "  -------------------------------------------------------------------------------------------"
        Write-Host
      }

      Write-Host
      Write-Host -foregroundcolor $COLOR_BRIGHT -noNewLine "  # Processing Node:       " $TargetObject
      Write-Host -foregroundcolor $COLOR_DARK   -noNewLine "  [Global Progress:" $( '{0:p}' -f $($($i+1)/$TotalNodes) )
      Write-Host -foregroundcolor $COLOR_DARK              " `($($i+1)`/$TotalNodes`)]"
      Write-Host

      $NodeStatus   = Get-WmiObject -Class Win32_PingStatus -Filter "Address='$TargetObject'" | Select-Object -Property Address, ProtocolAddress, ResponseTime, StatusCode

      if ( $NodeStatus.StatusCode -eq $STATUS_NODE_ISALIVE ) {
        if ( $TargetObject -match $REGEX_IP ) {
          Write-Host -foregroundcolor $COLOR_ERROR "  + NodeName is an IP:      Trying to get DNS Name"
          Write-Host

          $TargetIP            = $TargetObject
          [string] $TargetName = $([System.Net.Dns]::GetHostByAddress('$TargetObject')).HostName
          if ( ($TargetName -eq $null) -or ($TargetName.Length -eq 0) ) { [string] $TargetName = $UNKNOWN_HOSTNAME }
        } else {
          [string] $TargetName = $TargetObject

          if ( $NodeStatus.ProtocolAddress -ne $TargetIP ) {
            Write-Host -foregroundcolor $COLOR_ERROR "  + NodeName resolved IP:   $NodeStatus.ProtocolAddress"
            Write-Host -foregroundcolor $COLOR_ERROR "  + NodeName AdminIP:       $TargetIP"
            Write-Host -foregroundcolor $COLOR_ERROR "  + Selected IP:            $TargetIP"
            Write-Host
          }
        }
      } else {
        $SkipTarget = $true

        Write-Host -foregroundcolor $COLOR_ERROR "  + Skipping Node:          Unable to confirm if Node is alive"
        Write-Host
      }

      if (-not $SkipTarget) {
        ScanNode $TargetName $TargetIP
      } else {
        $TargetName >> $SkippedNodesFile
      }

      $NodeEndTime     = Get-Date
      $NodeElapsedTime = New-TimeSpan $NodeStartTime
      $NodeAverageTime = GetNodeAverageTime $NodeAverageTime $NodeElapsedTime
      $i++
    }
  } else {
    Write-Host -foregroundcolor $COLOR_ERROR "  + Skipping Session:       Selected Data Set is empty"
    Write-Host
  }
}

##############################################################################

function Get-NMAOfflineSessionItems([string] $StoreName, [string] $SessionSelector = "all") {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentGetNMAOfflineSessionErrorEvent = @"

===========================================================================================
$(get-date -format u) - Get-NMAOfflineSessionItems Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())


"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  + Get-NMAOfflineSessionItems Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentGetNMAOfflineSessionErrorEvent >> $ErrorLogFile

    continue
  }


  Reset-NMAOfflineStore $StoreName $SessionSelector

  $OfflineStoreDT
}

##############################################################################

function Remove-NMAOfflineSession([string] $StoreName, [string] $SessionSelector = "") {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentRemoveNMAOfflineSessionErrorEvent = @"

===========================================================================================
$(get-date -format u) - Remove-NMAOfflineSession Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())


"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  + Remove-NMAOfflineSession Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentRemoveNMAOfflineSessionErrorEvent >> $ErrorLogFile

    continue
  }


  if ( Test-NMAOfflineStore $StoreName ) {
    if ( Test-NMAOfflineSession $StoreName $SessionSelector ) {
      $DB_QUERY = $OfflineStoreDA.SelectCommand.CommandText -replace "SELECT \*", "DELETE"

      switch ( $script:NMAgentDbType ) {
        $NMAgentDbType_MSAccess    { $db = New-Object System.Data.OleDb.OleDbConnection   }
        $NMAgentDbType_MSSQLServer { $db = New-Object System.Data.SqlClient.SqlConnection }
      }


      $db.ConnectionString          = $NMAgentDbConnectionString
      $dbCommand                    = $db.CreateCommand()
      $dbCommand.CommandText        = $DB_QUERY

      $db.Open()
      [int] $result                 = $dbCommand.ExecuteNonQuery()

      $db.Close()

      # Workaround to avoid a weird effect (apparently) with the OLEDB Provider. If we don't do it, it doesn't Sync the DS accordingly.
      if ( $script:NMAgentDbType -eq $NMAgentDbType_MSAccess ) { Start-Sleep 5 }

      Sync-NMAOfflineStore $OfflineStoreDA.SelectCommand.CommandText
    } else {
      Write-Host
      Write-Host -foregroundcolor $COLOR_ERROR "  # Session Removal Aborted: the specified Session could not be found"
      Write-Host
    }
  } else {
    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR "  # Session Removal Aborted: the specified Store could not be found"
    Write-Host
  }
}

##############################################################################

function Restore-NMASession([string] $StoreName, [string] $SessionSelector = "") {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentRestoreNMASessionErrorEvent = @"

===========================================================================================
$(get-date -format u) - Restore-NMASession Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())


"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  + Restore-NMASession Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentRestoreNMASessionErrorEvent >> $ErrorLogFile

    continue
  }


  if ( Test-NMAOfflineStore $StoreName ) {
    if ( Test-NMAOfflineSession $StoreName $SessionSelector ) {
      $DB_QUERY = $OfflineStoreDA.SelectCommand.CommandText -replace "SELECT", "INSERT INTO [$script:AgentUserSessionStore] SELECT"

      switch ( $script:NMAgentDbType ) {
        $NMAgentDbType_MSAccess    {
          $db = New-Object System.Data.OleDb.OleDbConnection
        }

        $NMAgentDbType_MSSQLServer {
          $DB_QUERY = $DB_QUERY -replace "SELECT", "(RecordId, RecordDate, SessionId, AgentUserId, AgentUserName, AgentNodeName, NodeName, NodeIP, ErrorFound, ErrorText, NodePropertyName, NodePropertyIsSupported, NodeAttributeName, NodeExtendedAttributes, NodeValue, NodeValue_Memo, NodeQueryOutput) SELECT"
          $DB_QUERY = "SET IDENTITY_INSERT [$script:AgentUserSessionStore] ON; " + $DB_QUERY + "; SET IDENTITY_INSERT [$script:AgentUserSessionStore] OFF;"

          $db = New-Object System.Data.SqlClient.SqlConnection
        }
      }

      $db.ConnectionString          = $NMAgentDbConnectionString
      $dbCommand                    = $db.CreateCommand()
      $dbCommand.CommandText        = $DB_QUERY

      $db.Open()
      [int] $result                 = $dbCommand.ExecuteNonQuery()

      $db.Close()

      Sync-NMASessionStore $SStoreDA.SelectCommand.CommandText
    } else {
      Write-Host
      Write-Host -foregroundcolor $COLOR_ERROR "  # Session Restore Aborted: the specified Session could not be found"
      Write-Host
    }
  } else {
    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR "  # Session Restore Aborted: the specified Store could not be found"
    Write-Host
  }
}

##############################################################################

function Backup-NMASession([string] $StoreName) {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentBackupNMASessionErrorEvent = @"

===========================================================================================
$(get-date -format u) - Backup-NMASession Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())


"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  + Backup-NMASession Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentBackupNMASessionErrorEvent >> $ErrorLogFile

    continue
  }


  $ConfigureSStore              = $false
  $SStoreAlreadyExist           = $false

  if ( Test-NMAOfflineStore $StoreName ) {
    $DB_QUERY                   = $SStoreDA.SelectCommand.CommandText -replace "SELECT", "INSERT INTO [$StoreName] SELECT"
    $SStoreAlreadyExist         = $true
  } else {
    $DB_QUERY                   = $SStoreDA.SelectCommand.CommandText -replace "FROM", "INTO [$StoreName] FROM"
    $ConfigureSStore            = $true
  }

  switch ( $script:NMAgentDbType ) {
    $NMAgentDbType_MSAccess    { $db = New-Object System.Data.OleDb.OleDbConnection   }
    $NMAgentDbType_MSSQLServer { $db = New-Object System.Data.SqlClient.SqlConnection }
  }


  $db.ConnectionString          = $NMAgentDbConnectionString
  $db.Open()


  if ( ( $script:NMAgentDbType -eq $NMAgentDbType_MSSQLServer ) -and ( $SStoreAlreadyExist ) ) {
    $DB_QUERY                   = $DB_QUERY -replace "SELECT", "(RecordId, RecordDate, SessionId, AgentUserId, AgentUserName, AgentNodeName, NodeName, NodeIP, ErrorFound, ErrorText, NodePropertyName, NodePropertyIsSupported, NodeAttributeName, NodeExtendedAttributes, NodeValue, NodeValue_Memo, NodeQueryOutput) SELECT"
    $DB_QUERY                   = "SET IDENTITY_INSERT [$StoreName] ON; " + $DB_QUERY + "; SET IDENTITY_INSERT [$StoreName] OFF;"
  }


  $dbCommand                    = $db.CreateCommand()
  $dbCommand.CommandText        = $DB_QUERY
  [int] $result                 = $dbCommand.ExecuteNonQuery()


  if ( $ConfigureSStore ) {
    $dbCommand                  = $db.CreateCommand()
    $dbCommand.CommandText      = "ALTER TABLE [$StoreName] ADD CONSTRAINT PK_$($StoreName)_RecordId PRIMARY KEY (RecordId);"
    [int] $result               = $dbCommand.ExecuteNonQuery()

    $dbCommand                  = $db.CreateCommand()

    switch ( $script:NMAgentDbType ) {
      $NMAgentDbType_MSAccess    { $dbCommand.CommandText = "ALTER TABLE [$StoreName] ALTER COLUMN RecordDate DATETIME DEFAULT NOW() NOT NULL;"   }
      $NMAgentDbType_MSSQLServer { $dbCommand.CommandText = "ALTER TABLE [$StoreName] ADD CONSTRAINT [DF_$($StoreName)_RecordDate] DEFAULT GETDATE() FOR RecordDate;" }
    }

    [int] $result               = $dbCommand.ExecuteNonQuery()
  }


  $db.Close()
}

##############################################################################

function Remove-NMAOfflineStore([string] $StoreName) {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentRemoveNMAOfflineStoreErrorEvent = @"

===========================================================================================
$(get-date -format u) - Remove-NMAOfflineStores Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())


"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  + Remove-NMAOfflineStores Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentRemoveNMAOfflineStoreErrorEvent >> $ErrorLogFile

    continue
  }


  $DB_QUERY                     = "DROP TABLE [$StoreName];"


  switch ( $script:NMAgentDbType ) {
    $NMAgentDbType_MSAccess    { $db = New-Object System.Data.OleDb.OleDbConnection   }
    $NMAgentDbType_MSSQLServer { $db = New-Object System.Data.SqlClient.SqlConnection }
  }

  $db.ConnectionString          = $NMAgentDbConnectionString
  $dbCommand                    = $db.CreateCommand()
  $dbCommand.CommandText        = $DB_QUERY

  $db.Open()
  [int] $result                 = $dbCommand.ExecuteNonQuery()

  $db.Close()
}

##############################################################################

function Get-NMAOfflineStores() {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentGetNMAOfflineStoresErrorEvent = @"

===========================================================================================
$(get-date -format u) - Get-NMAOfflineStores Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())


"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  + Get-NMAOfflineStores Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentGetNMAOfflineStoresErrorEvent >> $ErrorLogFile

    continue
  }



  # $MSAccessTables = "SELECT MsysObjects.Name FROM MsysObjects WHERE MsysObjects.Type = 1 And ( (Left(MsysObjects.Name, 1)) <> '~' And (Left(MsysObjects.Name, 1)) <> '_' ) And (Left(MsysObjects.Name, 4)) <> 'Msys' ORDER  BY MsysObjects.Name;"
  $MSAccessTables = "_GetTables"


  switch ( $script:NMAgentDbType ) {
    $NMAgentDbType_MSAccess {
      $STORES_QUERY                   = "SELECT * FROM [$MSAccessTables]"
      $db                             = New-Object System.Data.OleDb.OleDbConnection
      $db.ConnectionString            = $script:NMAgentDbConnectionString
      $db.Open()

      $StoresSrc                      = New-Object System.Data.OleDb.OleDbCommand($STORES_QUERY, $db)
      $StoresDA                       = New-Object System.Data.OleDb.OleDbDataAdapter($StoresSrc)
    }

    $NMAgentDbType_MSSQLServer {
      $STORES_QUERY                   = "SELECT tbl.name AS [Name] FROM sys.tables AS tbl ORDER BY [Name] ASC"
      $db                             = New-Object System.Data.SqlClient.SqlConnection
      $db.ConnectionString            = $script:NMAgentDbConnectionString
      $db.Open()

      $StoresSrc                      = New-Object System.Data.SqlClient.SqlCommand($STORES_QUERY, $db)
      $StoresDA                       = New-Object System.Data.SqlClient.SqlDataAdapter($StoresSrc)
    }
  }

  $StoresDS                           = New-Object System.Data.DataSet
  $StoresDT                           = New-Object System.Data.DataTable

  [void] $StoresDA.Fill($StoresDS)
  $StoresDT                           = $StoresDS.Tables[0]

  $StoresDT

  $db.Close()
}
