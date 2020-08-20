function Get-NMAHelp() {
  Write-host
  Write-host -foregroundcolor $COLOR_BRIGHT   "  + Network Management Agent Shell Functions:"
  Write-host

  Get-ChildItem function:*-NMA*, function:*-OSLIM* | Sort-Object Name | Format-Table Name, Definition -auto

  Write-host
  Write-host -foregroundcolor $COLOR_BRIGHT   "  + Network Management Agent Function Alias:"
  Write-host

  Get-ChildItem alias:nma-*, alias:slim-* | Sort-Object Name | Format-Table Name, Definition -auto
}

##############################################################################

function New-NMAProfile([string] $NewProfile = "") {
  if ( ($NewProfile -eq $null) -or ($NewProfile.length -eq 0) ) { $NewProfile = Read-Host "  + New Profile" }

  if ( ($NewProfile -ne $null) -and ($NewProfile.length -ne 0) ) {
    if (Test-Path $SettingsDir\settings-$NewProfile.ps1) {
      $script:CurrentProfile = $NewProfile

      . $SettingsDir\settings-$NewProfile.ps1

      . LoadExtendedSettings

      if ( $MultiCredentialMode -or $BruteForceLoginMode ) {
        . LoadExtendedCredentials
      }

      . LoadModulesTable
      . LoadProfileModules


      [string[]] $script:NMAModulesKeys       = ($NMAModules.Keys      | Sort-Object)
      [string[]] $script:BFModulesKeys        = ($BFModules.Keys       | Sort-Object)
      [string[]] $script:NodeCredentialsKeys  = ($NodeCredentials.Keys | Sort-Object)


      Write-host
      Write-host -foregroundcolor $COLOR_BRIGHT "  + New Profile successfully Loaded. New profile is: " $NewProfile
      Write-host
    } else {
      Write-host
      Write-host -foregroundcolor $COLOR_ERROR "  + Can't Load Profile: selected Profile doesn't exist."
      Write-host
    }
  } else {
    Write-host
    Write-host -foregroundcolor $COLOR_ERROR   "  + Can't Load Profile: invalid Profile name."
    Write-host
  }
}

##############################################################################

function Get-NMAProfiles() {
  Get-ChildItem $SettingsDir\settings-*.ps1, $SettingsDir\credentials-*.ps1 | Format-Table Name -hideTableHeaders
}

##############################################################################

function New-NMAModules() {
  $ToggleValue = $STATUS_NO

  Write-Host
  Write-Host -foregroundcolor $COLOR_BRIGHT '  -------------------------------------------------------------------------------------------'
  Write-Host -foregroundcolor $COLOR_BRIGHT '  NMAgent Profile Modules Selection:'
  Write-Host

  $script:NMAModulesKeys | ForEach-Object {
    $ToggleValue = $STATUS_NO

    Write-Host -foregroundcolor $COLOR_NORMAL  -noNewLine "  + Module: "
    Write-Host -foregroundcolor $COLOR_BRIGHT  -noNewLine $_
    Write-Host -foregroundcolor $COLOR_NORMAL  -noNewLine " Is Active: "
    Write-Host -foregroundcolor $COLOR_BRIGHT  -noNewLine $script:NMAModules.$_[$NMAModules_IsEnabled]
    $ToggleValue = Read-Host " :: Toggle Value? [Y/N]"

    if ($ToggleValue -eq $STATUS_YES) {
      if ($script:NMAModules.$_[$NMAModules_IsEnabled]) {
        $script:NMAModules.$_[$NMAModules_IsEnabled] = $false
      } else {
        $script:NMAModules.$_[$NMAModules_IsEnabled] = $true
      }
    }
  }

  if ( $DisableFormatOutput ) {
    Write-Host
    Write-Host -foregroundcolor $COLOR_BRIGHT '  -------------------------------------------------------------------------------------------'
    Write-Host
  }
}

##############################################################################

function New-NMABfModules() {
  $ToggleValue = $STATUS_NO

  Write-Host
  Write-Host -foregroundcolor $COLOR_BRIGHT '  -------------------------------------------------------------------------------------------'
  Write-Host -foregroundcolor $COLOR_BRIGHT '  NMAgent Profile Brute-Force Modules Selection:'
  Write-Host

  $script:BFModulesKeys | ForEach-Object {
    $ToggleValue = $STATUS_NO

    Write-Host -foregroundcolor $COLOR_NORMAL  -noNewLine "  + Module: "
    Write-Host -foregroundcolor $COLOR_BRIGHT  -noNewLine $_
    Write-Host -foregroundcolor $COLOR_NORMAL  -noNewLine " Is Active: "
    Write-Host -foregroundcolor $COLOR_BRIGHT  -noNewLine $script:BFModules.$_[$BFModules_IsEnabled]
    $ToggleValue = Read-Host " :: Toggle Value? [Y/N]"

    if ($ToggleValue -eq $STATUS_YES) {
      if ($script:BFModules.$_[$BFModules_IsEnabled]) {
        $script:BFModules.$_[$BFModules_IsEnabled] = $false
      } else {
        $script:BFModules.$_[$BFModules_IsEnabled] = $true
      }
    }
  }

  if ( $DisableFormatOutput ) {
    Write-Host
    Write-Host -foregroundcolor $COLOR_BRIGHT '  -------------------------------------------------------------------------------------------'
    Write-Host
  }
}

##############################################################################

function New-NMAExtendedSettings() {
  $ToggleValue = $STATUS_NO

  Write-Host
  Write-Host -foregroundcolor $COLOR_BRIGHT '  -------------------------------------------------------------------------------------------'
  Write-Host -foregroundcolor $COLOR_BRIGHT '  NMAgent Session Extended Settings:'
  Write-Host

  if ( $(Get-ChildItem variable:SX_*).Length -ne $null ) {
    Get-ChildItem variable:SX_* | ForEach-Object {
      $ToggleValue = $STATUS_NO

      Write-Host -foregroundcolor $COLOR_NORMAL  -noNewLine "  + Parameter: "
      Write-Host -foregroundcolor $COLOR_BRIGHT  -noNewLine $_.Name
      Write-Host -foregroundcolor $COLOR_NORMAL  -noNewLine " Value: "

      if ( $_.Value -is [array] ) {
        for ($i=0; $i -lt $_.Value.Count; $i++) { $SerializedValues += "$($_.Value[$i]), "}
        $SerializedValues = $SerializedValues.SubString(0, $($SerializedValues.Length - 2))

        Write-host -foregroundcolor $COLOR_BRIGHT  -noNewLine $SerializedValues
      } else {
        Write-host -foregroundcolor $COLOR_BRIGHT  -noNewLine $_.Value
      }

      $ToggleValue = Read-Host " :: Change/Toggle Value? [Y/N]"

      if ($ToggleValue -eq $STATUS_YES) {
        if ( $_.Value -is [boolean] ) {
          if ( $_.Value -eq $true ) {
            $_.Value = $false
          } else {
            $_.Value = $true
          }
        } else {
          $_.Value = Read-Host "    + New Value:"
        }
      }
    }
  } else {
    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR '  + INFO: unable to find Extended Settings on this Session Profile'
    Write-Host
  }

  if ( $DisableFormatOutput ) {
    Write-Host
    Write-Host -foregroundcolor $COLOR_BRIGHT '  -------------------------------------------------------------------------------------------'
    Write-Host
  }
}

##############################################################################

function New-NMASession() {
  $ToggleValue                      = $STATUS_NO

  $script:SessionId                 = Get-Date
  $script:SessionId                 = "$($script:SessionId.Year)$($script:SessionId.Month)$($script:SessionId.Day)-$($script:SessionId.Hour)$($script:SessionId.Minute)-$($script:SessionId.Second)-$($script:SessionId.Millisecond)"

  $script:ErrorLogFile              = $LogsDir + "\NMAgent-ErrorLog-"     + $($script:SessionId -replace "-", "") + ".log"
  $script:SkippedNodesFile          = $LogsDir + "\NMAgent-SkippedNodes-" + $($script:SessionId -replace "-", "") + ".log"
  $script:FailedNodesFile           = $LogsDir + "\NMAgent-FailedNodes-"  + $($script:SessionId -replace "-", "") + ".log"
  $script:FailedUsersFile           = $LogsDir + "\NMAgent-FailedUsers-"  + $($script:SessionId -replace "-", "") + ".log"
  $script:SuccessfulUsersFile       = $LogsDir + "\NMAgent-SuccessfulUsers-"  + $($script:SessionId -replace "-", "") + ".log"


  Write-Host
  Write-Host -foregroundcolor $COLOR_BRIGHT '  -------------------------------------------------------------------------------------------'
  Write-Host -foregroundcolor $COLOR_BRIGHT '  NMAgent Shell Session Paramenters:'
  Write-Host


  $ToggleValue = $STATUS_NO
  Write-host -foregroundcolor $COLOR_NORMAL  -noNewLine "  + Action Command. Current Value: "
  Write-host -foregroundcolor $COLOR_BRIGHT  -noNewLine $script:cmd
  $ToggleValue = Read-Host " :: Change Value? [Y/N]"

  if ( $ToggleValue.ToUpper() -eq $STATUS_YES ) {
    $script:cmd = Read-Host "    + New Command <exec|list|query|analyze|compare|export|update|purge|shell|archive|reload>"
  }

  if ( $script:cmd -eq $CMD_EXEC ) {
    $ToggleValue = $STATUS_NO
    Write-host -foregroundcolor $COLOR_NORMAL  -noNewLine "  + Get Target Nodes from OpenSLIM database. Current Value: "
    Write-host -foregroundcolor $COLOR_BRIGHT  -noNewLine $script:db
    $ToggleValue = Read-Host " :: Toggle Value? [Y/N]"

    if ( $ToggleValue.ToUpper() -eq $STATUS_YES ) {
      if ( $script:db ) { $script:db = $false } else { $script:db = $true }
    }

    if ( !$script:db ) {
      $ToggleValue = $STATUS_NO
      Write-host -foregroundcolor $COLOR_NORMAL  -noNewLine "  + Get Target Node(s) from File. Current Value: "
      Write-host -foregroundcolor $COLOR_BRIGHT  -noNewLine $script:file
      $ToggleValue = Read-Host " :: Toggle Value? [Y/N]"

      if ( $ToggleValue.ToUpper() -eq $STATUS_YES ) {
        if ( $script:file ) { $script:file = $false } else { $script:file = $true }
      }
    }

    if ( !$script:db -and !$script:file ) {
      $ToggleValue = $STATUS_NO
      Write-host -foregroundcolor $COLOR_NORMAL  -noNewLine "  + Get Target Node(s) from CLI. Current Value: "
      Write-host -foregroundcolor $COLOR_BRIGHT  -noNewLine $script:node
      $ToggleValue = Read-Host " :: Toggle Value? [Y/N]"

      if ( $ToggleValue.ToUpper() -eq $STATUS_YES ) {
        if ( $script:node ) { $script:node = $false } else { $script:node = $true }
      }
    }

    if ( !$script:db -and !$script:file -and !$script:node ) {
      $ToggleValue = $STATUS_NO
      Write-host -foregroundcolor $COLOR_NORMAL  -noNewLine "  + Discover Target Nodes from Network. Current Value: "
      Write-host -foregroundcolor $COLOR_BRIGHT  -noNewLine $script:network
      $ToggleValue = Read-Host " :: Toggle Value? [Y/N]"

      if ( $ToggleValue.ToUpper() -eq $STATUS_YES ) {
        if ( $script:network ) { $script:network = $false } else { $script:network = $true }
      }
    }
  }

  if ( !$script:db -and !$script:file -and !$script:node -and !$script:network ) {
    $ToggleValue = $STATUS_NO
    Write-host -foregroundcolor $COLOR_NORMAL  -noNewLine "  + Get Target Object(s) from a stored Session. Current Value: "
    Write-host -foregroundcolor $COLOR_BRIGHT  -noNewLine $script:session
    $ToggleValue = Read-Host " :: Toggle Value? [Y/N]"

    if ( $ToggleValue.ToUpper() -eq $STATUS_YES ) {
      if ( $script:session ) { $script:session = $false } else { $script:session = $true }
    }
  }

  if ( $script:file -or $script:node -or $script:network -or $script:session ) {
    $ToggleValue = $STATUS_NO
    Write-host -foregroundcolor $COLOR_NORMAL  -noNewLine "  + Target Object. Current Value: "
    Write-host -foregroundcolor $COLOR_BRIGHT  -noNewLine $script:TargetObject
    $ToggleValue = Read-Host " :: Change Value? [Y/N]"

    if ( $ToggleValue.ToUpper() -eq $STATUS_YES ) {
      $script:TargetObject = Read-Host "    + New Target Object [<input-file>|<host>|<host-list>|<network-range>|all|first|last|<session-id>]"
    }
  }


  if ( $script:session -or $script:db -or $script:file -or $script:node -or $script:network ) {
    if ( $script:session ) {
      $ToggleValue = $STATUS_NO
      Write-host -foregroundcolor $COLOR_NORMAL  -noNewLine "  + Object Filter. Current Value: "
      Write-host -foregroundcolor $COLOR_BRIGHT  -noNewLine $script:filter
      $ToggleValue = Read-Host " :: Change Value? [Y/N]"

      if ( $ToggleValue.ToUpper() -eq $STATUS_YES ) {
        $script:filter = Read-Host "    + New Filter <[[!]<ErrorFound>][;[!]<Property>][;[!]<Attribute>][;[!]<Value>]>"
      }

      $ToggleValue = $STATUS_NO
      Write-host -foregroundcolor $COLOR_NORMAL  -noNewLine "  + Display Raw Output. Current Value: "
      Write-host -foregroundcolor $COLOR_BRIGHT  -noNewLine $script:raw
      $ToggleValue = Read-Host " :: Toggle Value? [Y/N]"

      if ( $ToggleValue.ToUpper() -eq $STATUS_YES ) {
        if ( $script:raw ) { $script:raw = $false } else { $script:raw = $true }
      }
    }

    $ToggleValue = $STATUS_NO
    Write-host -foregroundcolor $COLOR_NORMAL  -noNewLine "  + Save Results. Current Value: "
    Write-host -foregroundcolor $COLOR_BRIGHT  -noNewLine $script:save
    $ToggleValue = Read-Host " :: Toggle Value? [Y/N]"

    if ( $ToggleValue.ToUpper() -eq $STATUS_YES ) {
      if ( $script:save ) { $script:save = $false } else { $script:save = $true }
    }

    $ToggleValue = $STATUS_NO
    Write-host -foregroundcolor $COLOR_NORMAL  -noNewLine "  + Enable Simulation Mode. Current Value: "
    Write-host -foregroundcolor $COLOR_BRIGHT  -noNewLine $script:test
    $ToggleValue = Read-Host " :: Toggle Value? [Y/N]"

    if ( $ToggleValue.ToUpper() -eq $STATUS_YES ) {
      if ( $script:test ) { $script:test = $false } else { $script:test = $true }
    }

    $ToggleValue = $STATUS_NO
    Write-host -foregroundcolor $COLOR_NORMAL  -noNewLine "  + OpenSLIM User Filter. Current Value: "
    Write-host -foregroundcolor $COLOR_BRIGHT  -noNewLine $script:OpenSLIMDbUserFilter
    $ToggleValue = Read-Host " :: Change Value? [Y/N]"

    if ( $ToggleValue.ToUpper() -eq $STATUS_YES ) {
      $script:OpenSLIMDbUserFilter = Read-Host "    + New Filter:"
    }

    $ToggleValue = $STATUS_NO
    Write-host -foregroundcolor $COLOR_NORMAL  -noNewLine "  + Statistics Display Frequency. Current Value: "
    Write-host -foregroundcolor $COLOR_BRIGHT  -noNewLine $script:StatsDisplayFrequency
    $ToggleValue = Read-Host " :: Change Value? [Y/N]"

    if ( $ToggleValue.ToUpper() -eq $STATUS_YES ) {
      $script:StatsDisplayFrequency = Read-Host "    + New Display Frequency:"
    }

    $ToggleValue = $STATUS_NO
    Write-host -foregroundcolor $COLOR_NORMAL  -noNewLine "  + Enable Multi-Credential Mode. Current Value: "
    Write-host -foregroundcolor $COLOR_BRIGHT  -noNewLine $script:MultiCredentialMode
    $ToggleValue = Read-Host " :: Toggle Value? [Y/N]"

    if ( $ToggleValue.ToUpper() -eq $STATUS_YES ) {
      if ( $script:MultiCredentialMode ) { $script:MultiCredentialMode = $false } else { $script:MultiCredentialMode = $true }
    }

    $ToggleValue = $STATUS_NO
    Write-host -foregroundcolor $COLOR_NORMAL  -noNewLine "  + Use Encrypted Credentials Store. Current Value: "
    Write-host -foregroundcolor $COLOR_BRIGHT  -noNewLine $script:CredentialsDbIsEncrypted
    $ToggleValue = Read-Host " :: Toggle Value? [Y/N]"

    if ( $ToggleValue.ToUpper() -eq $STATUS_YES ) {
      if ( $script:CredentialsDbIsEncrypted ) { $script:CredentialsDbIsEncrypted = $false } else { $script:CredentialsDbIsEncrypted = $true }
    }

    $ToggleValue = $STATUS_NO
    Write-host -foregroundcolor $COLOR_NORMAL  -noNewLine "  + Enable Brute-Force Login. Current Value: "
    Write-host -foregroundcolor $COLOR_BRIGHT  -noNewLine $script:BruteForceLoginMode
    $ToggleValue = Read-Host " :: Toggle Value? [Y/N]"

    if ( $ToggleValue.ToUpper() -eq $STATUS_YES ) {
      if ( $script:BruteForceLoginMode ) { $script:BruteForceLoginMode = $false } else { $script:BruteForceLoginMode = $true }
    }

    $ToggleValue = $STATUS_NO
    Write-host -foregroundcolor $COLOR_NORMAL  -noNewLine "  + Save Brute-Force Login Results. Current Value: "
    Write-host -foregroundcolor $COLOR_BRIGHT  -noNewLine $script:SaveBFLoginResults
    $ToggleValue = Read-Host " :: Toggle Value? [Y/N]"

    if ( $ToggleValue.ToUpper() -eq $STATUS_YES ) {
      if ( $script:SaveBFLoginResults ) { $script:SaveBFLoginResults = $false } else { $script:SaveBFLoginResults = $true }
    }

    $ToggleValue = $STATUS_NO
    Write-host -foregroundcolor $COLOR_NORMAL  -noNewLine "  + Enable per-Host Brute-Force Login. Current Value: "
    Write-host -foregroundcolor $COLOR_BRIGHT  -noNewLine $script:PerHostBFLogin
    $ToggleValue = Read-Host " :: Toggle Value? [Y/N]"

    if ( $ToggleValue.ToUpper() -eq $STATUS_YES ) {
      if ( $script:PerHostBFLogin ) { $script:PerHostBFLogin = $false } else { $script:PerHostBFLogin = $true }
    }

    $ToggleValue = $STATUS_NO
    Write-host -foregroundcolor $COLOR_NORMAL  -noNewLine "  + Enable per-Module Brute-Force Login. Current Value: "
    Write-host -foregroundcolor $COLOR_BRIGHT  -noNewLine $script:PerModuleBFLogin
    $ToggleValue = Read-Host " :: Toggle Value? [Y/N]"

    if ( $ToggleValue.ToUpper() -eq $STATUS_YES ) {
      if ( $script:PerModuleBFLogin ) { $script:PerModuleBFLogin = $false } else { $script:PerModuleBFLogin = $true }
    }

    $ToggleValue = $STATUS_NO
    Write-host -foregroundcolor $COLOR_NORMAL  -noNewLine "  + Enable Brute-Force Login Extensions. Current Value: "
    Write-host -foregroundcolor $COLOR_BRIGHT  -noNewLine $script:EnableBFLoginExtensions
    $ToggleValue = Read-Host " :: Toggle Value? [Y/N]"

    if ( $ToggleValue.ToUpper() -eq $STATUS_YES ) {
      if ( $script:EnableBFLoginExtensions ) { $script:EnableBFLoginExtensions = $false } else { $script:EnableBFLoginExtensions = $true }
    }

    $ToggleValue = $STATUS_NO
    Write-host -foregroundcolor $COLOR_NORMAL  -noNewLine "  + Run-time/Progress Statistics Display Frequency. Current Value: "
    Write-host -foregroundcolor $COLOR_BRIGHT  -noNewLine $script:StatsDisplayFrequency
    $ToggleValue = Read-Host " :: Change Value? [Y/N]"

    if ( $ToggleValue.ToUpper() -eq $STATUS_YES ) {
      $script:StatsDisplayFrequency = Read-Host "    + New Value"
    }

    if ( $script:file ) {
      $ToggleValue = $STATUS_NO
      Write-host -foregroundcolor $COLOR_NORMAL  -noNewLine "  + Merge Input Files. Current Value: "
      Write-host -foregroundcolor $COLOR_BRIGHT  -noNewLine $script:MergeInputFiles
      $ToggleValue = Read-Host " :: Toggle Value? [Y/N]"

      if ( $ToggleValue.ToUpper() -eq $STATUS_YES ) {
        if ( $script:MergeInputFiles ) { $script:MergeInputFiles = $false } else { $script:MergeInputFiles = $true }
      }
    }

    $ToggleValue = $STATUS_NO
    Write-host -foregroundcolor $COLOR_NORMAL  -noNewLine "  + Merge Credentials Files. Current Value: "
    Write-host -foregroundcolor $COLOR_BRIGHT  -noNewLine $script:MergeCredentialsFiles
    $ToggleValue = Read-Host " :: Toggle Value? [Y/N]"

    if ( $ToggleValue.ToUpper() -eq $STATUS_YES ) {
      if ( $script:MergeCredentialsFiles ) { $script:MergeCredentialsFiles = $false } else { $script:MergeCredentialsFiles = $true }
    }

    $ToggleValue = $STATUS_NO
    for ($i=0; $i -lt $script:ModulesLibraries.Count; $i++) { $SerializedModulesLibraries += "$($script:ModulesLibraries[$i]), "}
    $SerializedModulesLibraries = $SerializedModulesLibraries.SubString(0, $($SerializedModulesLibraries.Length - 2))

    Write-host -foregroundcolor $COLOR_NORMAL  -noNewLine "  + List of Modules Libraries. Current Value: "
    Write-host -foregroundcolor $COLOR_BRIGHT  -noNewLine $SerializedModulesLibraries
    $ToggleValue = Read-Host " :: Change Value? [Y/N]"

    if ( $ToggleValue.ToUpper() -eq $STATUS_YES ) {
      [string]   $NewModulesLibraries     = Read-Host "    + New Value"
      [string[]] $script:ModulesLibraries = $NewModulesLibraries.Split(",")

      if ( ( $cmd.ToLower() -eq $CMD_EXEC ) -or ( $cmd.ToLower() -eq $CMD_SHELL ) ) {
        . LoadModulesTable
        . LoadProfileModules
        . LoadExtendedSettings
        . LoadExtendedCredentials

        [string[]] $script:NMAModulesKeys = $( $script:NMAModules.Keys | Sort-Object )
      }
    }
  }

  if ( $DisableFormatOutput ) {
    Write-Host
    Write-Host -foregroundcolor $COLOR_BRIGHT '  -------------------------------------------------------------------------------------------'
    Write-Host
  }


  . CheckScriptSyntax


  if ( $script:BruteForceLoginMode ) {
    $script:MultiCredentialMode       = $false

    if ( $script:PerHostBFLogin ) {
      $script:PerModuleBFLogin        = $false
    } else {
      $script:PerModuleBFLogin        = $true
      $script:EnableBFLoginExtensions = $true
    }
  } else {
    $script:PerHostBFLogin            = $false
    $script:PerModuleBFLogin          = $false
    $script:EnableBFLoginExtensions   = $false
  }


  if ( $script:cmd.ToLower() -eq $CMD_EXEC) {
    if ( (!$script:MultiCredentialMode) -and (!$script:BruteForceLoginMode) ) {
      $script:NetworkCredentials      = Get-Credential $script:NetworkUserId
    }
  }
}

##############################################################################

function New-NMAOfflineStore([string] $StoreName) {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentNewNMAOfflineStoreErrorEvent = @"

===========================================================================================
$(get-date -format u) - New-NMAOfflineStore Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())


"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  + New-NMAOfflineStore Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentNewNMAOfflineStoreErrorEvent >> $ErrorLogFile

    continue
  }


  $DB_QUERY                     = @"
CREATE TABLE [$($StoreName)] (
  [RecordId]                AUTOINCREMENT PRIMARY KEY NOT NULL,
  [RecordDate]              DATETIME DEFAULT Now() NOT NULL,
  [SessionId]               VARCHAR(50) NULL,
  [AgentUserId]             INT NULL,
  [AgentUserName]           VARCHAR(50) NULL,
  [AgentNodeName]           VARCHAR(50) NULL,
  [NodeName]                VARCHAR(50) NULL,
  [NodeIP]                  VARCHAR(50) NULL,
  [ErrorFound]              BIT NULL,
  [ErrorText]               MEMO NULL,
  [NodePropertyName]        VARCHAR(100) NULL,
  [NodePropertyIsSupported] BIT NULL,
  [NodeAttributeName]       VARCHAR(100) NULL,
  [NodeExtendedAttributes]  VARCHAR(255) NULL,
  [NodeValue]               VARCHAR(255) NULL,
  [NodeValue_Memo]          MEMO NULL,
  [NodeQueryOutput]         MEMO NULL
)
"@


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

function Test-NMAOfflineStore([string] $StoreName) {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentTestNMAOfflineStoreErrorEvent = @"

===========================================================================================
$(get-date -format u) - Test-NMAOfflineStore Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())


"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  + Test-NMAOfflineStore Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentTestNMAOfflineStoreErrorEvent >> $ErrorLogFile

    continue
  }


  $OfflineStoreExists = $false

  Get-NMAOfflineStores | ForEach-Object {
    if ( $_.Name -eq $StoreName ) {
      $OfflineStoreExists = $true
    }
  }

  $OfflineStoreExists
}

##############################################################################

function Test-NMAOfflineSession([string] $StoreName, [string] $SessionSelector = "all") {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentTestNMAOfflineSessionErrorEvent = @"

===========================================================================================
$(get-date -format u) - Test-NMAOfflineSession Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())


"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  + Test-NMAOfflineSession Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentTestNMAOfflineSessionErrorEvent >> $ErrorLogFile

    continue
  }


  $OfflineSessionExists = $false

  switch -case ( $SessionSelector ) {
    { ( $_ -eq $TARGET_SESSION_ALL ) -or ( $_ -eq $TARGET_SESSION_FIRST ) -or ( $_ -eq $TARGET_SESSION_LAST ) } {
      if ( $( Get-NMAOfflineSessionItems $StoreName $SessionSelector | Select-Object SessionId -unique | Measure-Object ).Count -ge 1 ) {
        $OfflineSessionExists = $true
      }
    }

    { ( $_ -eq $TARGET_SESSION_SECOND ) -or ( $_ -eq $TARGET_SESSION_PENULTIMATE ) } {
      if ( $( Get-NMAOfflineSessionItems $StoreName $SessionSelector | Select-Object SessionId -unique | Measure-Object ).Count -ge 2 ) {
        $OfflineSessionExists = $true
      }
    }

    default {
      Get-NMAOfflineSessionItems $StoreName $SessionSelector | Select-Object SessionId -unique | ForEach-Object {
        if ( $_.SessionId -eq $SessionSelector ) {
          $OfflineSessionExists = $true
        }
      }
    }
  }

  $OfflineSessionExists
}

##############################################################################

function Test-NMASession([string] $SessionSelector = "all") {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentTestNMASessionErrorEvent = @"

===========================================================================================
$(get-date -format u) - Test-NMASession Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())


"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  + Test-NMASession Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentTestNMASessionErrorEvent >> $ErrorLogFile

    continue
  }


  $SessionExists = $false

  switch -case ( $SessionSelector ) {
    { ( $_ -eq $TARGET_SESSION_ALL ) -or ( $_ -eq $TARGET_SESSION_FIRST ) -or ( $_ -eq $TARGET_SESSION_LAST ) } {
      if ( $( Get-NMASession $SessionSelector | Select-Object SessionId | Measure-Object ).Count -ge 1 ) {
        $SessionExists = $true
      }
    }

    { ( $_ -eq $TARGET_SESSION_SECOND ) -or ( $_ -eq $TARGET_SESSION_PENULTIMATE ) } {
      if ( $( Get-NMASession $SessionSelector | Select-Object SessionId | Measure-Object ).Count -ge 2 ) {
        $SessionExists = $true
      }
    }

    default {
      Get-NMASession $SessionSelector | Select-Object SessionId | ForEach-Object {
        if ( $_.SessionId -eq $SessionSelector ) {
          $SessionExists = $true
        }
      }
    }
  }

  $SessionExists
}

##############################################################################

function Sync-NMAOfflineStore([string] $SessionSelection = $SStoreDA.SelectCommand.CommandText) {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentSyncNMAOfflineStoreErrorEvent = @"

===========================================================================================
$(get-date -format u) - Sync-NMAOfflineStore Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())


"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  + Sync-NMAOfflineStore Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentSyncNMAOfflineStoreErrorEvent >> $ErrorLogFile

    continue
  }


  $OFFLINESTORE_SELECTION                 = $SessionSelection

  switch ( $script:NMAgentDbType ) {
    $NMAgentDbType_MSAccess {
      $script:OfflineStoreSrc             = New-Object System.Data.OleDb.OleDbCommand($OFFLINESTORE_SELECTION, $NMAgentDb)
      $script:OfflineStoreDA              = New-Object System.Data.OleDb.OleDbDataAdapter($OfflineStoreSrc)
      $DbCmdBuilder                       = New-Object System.Data.OleDb.OleDbCommandBuilder $script:OfflineStoreDA
    }

    $NMAgentDbType_MSSQLServer {
      $script:OfflineStoreSrc             = New-Object System.Data.SqlClient.SqlCommand($OFFLINESTORE_SELECTION, $NMAgentDb)
      $script:OfflineStoreDA              = New-Object System.Data.SqlClient.SqlDataAdapter($OfflineStoreSrc)
      $DbCmdBuilder                       = New-Object System.Data.SqlClient.SqlCommandBuilder $script:OfflineStoreDA
    }
  }

  $script:OfflineStoreDS                  = New-Object System.Data.DataSet
  $script:OfflineStoreDT                  = New-Object System.Data.DataTable

  [void] $script:OfflineStoreDA.Fill($script:OfflineStoreDS)
  $script:OfflineStoreDT                  = $script:OfflineStoreDS.Tables[0]

  $script:OfflineStoreDA.UpdateCommand    = $DbCmdBuilder.GetUpdateCommand()
  $script:OfflineStoreDA.InsertCommand    = $DbCmdBuilder.GetInsertCommand()
  $script:OfflineStoreDA.DeleteCommand    = $DbCmdBuilder.GetDeleteCommand()
}

##############################################################################

function Select-NMAOfflineStore([string] $StoreName) {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentSelectNMAOfflineStoreErrorEvent = @"

===========================================================================================
$(get-date -format u) - Select-NMAOfflineStore Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())


"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  + Select-NMAOfflineStore Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentSelectNMAOfflineStoreErrorEvent >> $ErrorLogFile

    continue
  }


  $OFFLINESTORE_SELECTION                 = "SELECT * FROM [$StoreName]"

  switch ( $script:NMAgentDbType ) {
    $NMAgentDbType_MSAccess {
      $script:OfflineStoreSrc             = New-Object System.Data.OleDb.OleDbCommand($OFFLINESTORE_SELECTION, $NMAgentDb)
      $script:OfflineStoreDA              = New-Object System.Data.OleDb.OleDbDataAdapter($OfflineStoreSrc)
      $DbCmdBuilder                       = New-Object System.Data.OleDb.OleDbCommandBuilder $script:OfflineStoreDA
    }

    $NMAgentDbType_MSSQLServer {
      $script:OfflineStoreSrc             = New-Object System.Data.SqlClient.SqlCommand($OFFLINESTORE_SELECTION, $NMAgentDb)
      $script:OfflineStoreDA              = New-Object System.Data.SqlClient.SqlDataAdapter($OfflineStoreSrc)
      $DbCmdBuilder                       = New-Object System.Data.SqlClient.SqlCommandBuilder $script:OfflineStoreDA
    }
  }

  $script:OfflineStoreDS                  = New-Object System.Data.DataSet
  $script:OfflineStoreDT                  = New-Object System.Data.DataTable

  [void] $script:OfflineStoreDA.Fill($script:OfflineStoreDS)
  $script:OfflineStoreDT                  = $script:OfflineStoreDS.Tables[0]

  $script:OfflineStoreDA.UpdateCommand    = $DbCmdBuilder.GetUpdateCommand()
  $script:OfflineStoreDA.InsertCommand    = $DbCmdBuilder.GetInsertCommand()
  $script:OfflineStoreDA.DeleteCommand    = $DbCmdBuilder.GetDeleteCommand()
}

##############################################################################

function Get-OSLIMEntities() {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentGetOSLIMEntitiesErrorEvent = @"

===========================================================================================
$(get-date -format u) - Get-OSLIMEntities Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())


"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  + Get-OSLIMEntities Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentGetOSLIMEntitiesErrorEvent >> $ErrorLogFile

    continue
  }


  $ENTITIES_QUERY                       = "SELECT tbl.name AS [Name] FROM sys.tables AS tbl ORDER BY [Name] ASC"

  $db                                   = New-Object System.Data.SqlClient.SqlConnection
  $db.ConnectionString                  = $OpenSLIMDbConnectionString
  $db.Open()

  $EntitiesSrc                          = New-Object System.Data.SqlClient.SqlCommand($ENTITIES_QUERY, $db)
  $EntitiesDA                           = New-Object System.Data.SqlClient.SqlDataAdapter($EntitiesSrc)
  $EntitiesDS                           = New-Object System.Data.DataSet
  $EntitiesDT                           = New-Object System.Data.DataTable

  [void] $EntitiesDA.Fill($EntitiesDS)
  $EntitiesDT                           = $EntitiesDS.Tables[0]

  $EntitiesDT

  $db.Close()
}

##############################################################################

function Get-OSLIMEntityItems([string] $EntityName = "") {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentGetOSLIMEntityItemsErrorEvent = @"

===========================================================================================
$(get-date -format u) - Get-OSLIMEntityItems Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())


"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  + Get-OSLIMEntityItems Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentGetOSLIMEntityItemsErrorEvent >> $ErrorLogFile

    continue
  }


  $ENTITYITEMS_QUERY                       = "SELECT * FROM $EntityName"

  $db                                      = New-Object System.Data.SqlClient.SqlConnection
  $db.ConnectionString                     = $OpenSLIMDbConnectionString
  $db.Open()

  $EntityItemsSrc                          = New-Object System.Data.SqlClient.SqlCommand($ENTITYITEMS_QUERY, $db)
  $EntityItemsDA                           = New-Object System.Data.SqlClient.SqlDataAdapter($EntityItemsSrc)
  $EntityItemsDS                           = New-Object System.Data.DataSet
  $EntityItemsDT                           = New-Object System.Data.DataTable

  [void] $EntityItemsDA.Fill($EntityItemsDS)
  $EntityItemsDT                           = $EntityItemsDS.Tables[0]

  $EntityItemsDT

  $db.Close()
}

##############################################################################

function Sync-OSLIMNodes([string] $SessionSelection = $TBLNODES_SELECTION) {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentSyncOSLIMNodesErrorEvent = @"

===========================================================================================
$(get-date -format u) - Sync-OSLIMNodes Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())


"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  + Sync-OSLIMNodes Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentSyncOSLIMNodesErrorEvent >> $ErrorLogFile

    continue
  }


  $script:NodesSrc                          = New-Object System.Data.SqlClient.SqlCommand($SessionSelection, $OpenSLIMDb)
  $script:NodesDA                           = New-Object System.Data.SqlClient.SqlDataAdapter($script:NodesSrc)
  $script:NodesDS                           = New-Object System.Data.DataSet
  $script:NodesDT                           = New-Object System.Data.DataTable

  [void] $script:NodesDA.Fill($script:NodesDS)
  $script:NodesDT                           = $script:NodesDS.Tables[0]
  $script:DbCmdBuilder                      = New-Object System.Data.SqlClient.SqlCommandBuilder $script:NodesDA
  $script:NodesDA.UpdateCommand             = $script:DbCmdBuilder.GetUpdateCommand()
  $script:NodesDA.InsertCommand             = $script:DbCmdBuilder.GetInsertCommand()
  $script:NodesDA.DeleteCommand             = $script:DbCmdBuilder.GetDeleteCommand()
}

##############################################################################

function Sync-NMASessionStore([string] $SessionSelection = $TBLCOLLECTEDDATA_SELECTION) {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentSyncNMASessionStoreErrorEvent = @"

===========================================================================================
$(get-date -format u) - Sync-NMASessionStore Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())


"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  + Sync-NMASessionStore Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentSyncNMASessionStoreErrorEvent >> $ErrorLogFile

    continue
  }


  switch ( $script:NMAgentDbType ) {
    $NMAgentDbType_MSAccess {
      $script:SStoreSrc             = New-Object System.Data.OleDb.OleDbCommand($SessionSelection, $NMAgentDb)
      $script:SStoreDA              = New-Object System.Data.OleDb.OleDbDataAdapter($SStoreSrc)
      $DbCmdBuilder                 = New-Object System.Data.OleDb.OleDbCommandBuilder $script:SStoreDA
    }

    $NMAgentDbType_MSSQLServer {
      $script:SStoreSrc             = New-Object System.Data.SqlClient.SqlCommand($SessionSelection, $NMAgentDb)
      $script:SStoreDA              = New-Object System.Data.SqlClient.SqlDataAdapter($SStoreSrc)
      $DbCmdBuilder                 = New-Object System.Data.SqlClient.SqlCommandBuilder $script:SStoreDA
    }
  }

  $script:SStoreDS                  = New-Object System.Data.DataSet
  $script:SStoreDT                  = New-Object System.Data.DataTable

  [void] $script:SStoreDA.Fill($script:SStoreDS)
  $script:SStoreDT                  = $script:SStoreDS.Tables[0]

  $script:SStoreDA.UpdateCommand    = $DbCmdBuilder.GetUpdateCommand()
  $script:SStoreDA.InsertCommand    = $DbCmdBuilder.GetInsertCommand()
  $script:SStoreDA.DeleteCommand    = $DbCmdBuilder.GetDeleteCommand()
}

##############################################################################

function Reset-NMASessionStore([string] $ExtendedFilter = "") {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentResetNMASessionStoreEvent = @"

===========================================================================================
$(get-date -format u) - Reset-NMASessionStore Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())

"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  + Reset-NMASessionStore Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentResetNMASessionStoreEvent >> $ErrorLogFile

    break
  }


  [string] $FilterString      = BuildFilterString


  if ( $ExtendedFilter -eq "" ) {
    $SessionSelector = $TargetObject.ToLower()
  } else {
    $SessionSelector = $ExtendedFilter
  }


  switch -case ( $SessionSelector ) {
    $TARGET_SESSION_ALL {
      if ( $filter -ne "" ) {
        Sync-NMASessionStore "SELECT * FROM [$script:AgentUserSessionStore] WHERE $FilterString"
      } else {
        Sync-NMASessionStore "SELECT * FROM [$script:AgentUserSessionStore]"
      }
    }

    $TARGET_SESSION_FIRST {
      if ( $filter -eq "" ) {
        Sync-NMASessionStore "SELECT * FROM [$script:AgentUserSessionStore] WHERE SessionId = '$($($SStoreDT | Select-Object -first 1).SessionId)'"
      } else {
        Sync-NMASessionStore "SELECT * FROM [$script:AgentUserSessionStore] WHERE SessionId = '$($($SStoreDT | Select-Object -first 1).SessionId)' AND $FilterString"
      }
    }

    $TARGET_SESSION_SECOND {
      if ( $filter -eq "" ) {
        Sync-NMASessionStore "SELECT * FROM [$script:AgentUserSessionStore] WHERE SessionId = '$($($SStoreDT | Select-Object SessionId -unique | Select-Object -first 2 | Select-Object -last 1).SessionId)'"
      } else {
        Sync-NMASessionStore "SELECT * FROM [$script:AgentUserSessionStore] WHERE SessionId = '$($($SStoreDT | Select-Object SessionId -unique | Select-Object -first 2 | Select-Object -last 1).SessionId)' AND $FilterString"
      }
    }

    $TARGET_SESSION_LAST {
      if ( $filter -eq "" ) {
        Sync-NMASessionStore "SELECT * FROM [$script:AgentUserSessionStore] WHERE SessionId = '$($($SStoreDT | Select-Object -last 1).SessionId)'"
      } else {
        Sync-NMASessionStore "SELECT * FROM [$script:AgentUserSessionStore] WHERE SessionId = '$($($SStoreDT | Select-Object -last 1).SessionId)' AND $FilterString"
      }
    }

    $TARGET_SESSION_PENULTIMATE {
      if ( $filter -eq "" ) {
        Sync-NMASessionStore "SELECT * FROM [$script:AgentUserSessionStore] WHERE SessionId = '$($($SStoreDT | Select-Object SessionId -unique | Select-Object -last 2 | Select-Object -first 1).SessionId)'"
      } else {
        Sync-NMASessionStore "SELECT * FROM [$script:AgentUserSessionStore] WHERE SessionId = '$($($SStoreDT | Select-Object SessionId -unique | Select-Object -last 2 | Select-Object -first 1).SessionId)' AND $FilterString"
      }
    }

    default {
      if ( $filter -eq "" ) {
        Sync-NMASessionStore "SELECT * FROM [$script:AgentUserSessionStore] WHERE SessionId LIKE `'$($SessionSelector)`'"
      } else {
        Sync-NMASessionStore "SELECT * FROM [$script:AgentUserSessionStore] WHERE SessionId LIKE `'$($SessionSelector)`' AND $FilterString"
      }
    }
  }
}

##############################################################################

function Reset-NMAOfflineStore([string] $StoreName, [string] $SessionSelector = "") {
  $ErrorActionPreference = "silentlycontinue"

  trap {
    $NMAgentResetNMAOfflineStoreEvent = @"

===========================================================================================
$(get-date -format u) - Reset-NMAOfflineStore Error Event
-------------------------------------------------------------------------------------------
+ Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

$_

+ Category Information:

$($($_.CategoryInfo | Out-String).Trim())

+ Invocation Information:

$($($_.InvocationInfo | Out-String).Trim())

"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  + Reset-NMAOfflineStore Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
    Write-Host

    $NMAgentResetNMAOfflineStoreEvent >> $ErrorLogFile

    break
  }


  Select-NMAOfflineStore $StoreName

  [string] $FilterString      = BuildFilterString


  switch -case ( $SessionSelector ) {
    $TARGET_SESSION_ALL {
      if ( $filter -ne "" ) {
        Sync-NMAOfflineStore "SELECT * FROM [$StoreName] WHERE $FilterString"
      } else {
        Sync-NMAOfflineStore "SELECT * FROM [$StoreName]"
      }
    }

    $TARGET_SESSION_FIRST {
      if ( $filter -eq "" ) {
        Sync-NMAOfflineStore "SELECT * FROM [$StoreName] WHERE SessionId = '$($($OfflineStoreDT | Select-Object -first 1).SessionId)'"
      } else {
        Sync-NMAOfflineStore "SELECT * FROM [$StoreName] WHERE SessionId = '$($($OfflineStoreDT | Select-Object -first 1).SessionId)' AND $FilterString"
      }
    }

    $TARGET_SESSION_SECOND {
      if ( $filter -eq "" ) {
        Sync-NMAOfflineStore "SELECT * FROM [$StoreName] WHERE SessionId = '$($($OfflineStoreDT | Select-Object SessionId -unique | Select-Object -first 2 | Select-Object -last 1).SessionId)'"
      } else {
        Sync-NMAOfflineStore "SELECT * FROM [$StoreName] WHERE SessionId = '$($($OfflineStoreDT | Select-Object SessionId -unique | Select-Object -first 2 | Select-Object -last 1).SessionId)' AND $FilterString"
      }
    }

    $TARGET_SESSION_LAST {
      if ( $filter -eq "" ) {
        Sync-NMAOfflineStore "SELECT * FROM [$StoreName] WHERE SessionId = '$($($OfflineStoreDT | Select-Object -last 1).SessionId)'"
      } else {
        Sync-NMAOfflineStore "SELECT * FROM [$StoreName] WHERE SessionId = '$($($OfflineStoreDT | Select-Object -last 1).SessionId)' AND $FilterString"
      }
    }

    $TARGET_SESSION_PENULTIMATE {
      if ( $filter -eq "" ) {
        Sync-NMAOfflineStore "SELECT * FROM [$StoreName] WHERE SessionId = '$($($OfflineStoreDT | Select-Object SessionId -unique | Select-Object -last 2 | Select-Object -first 1).SessionId)'"
      } else {
        Sync-NMAOfflineStore "SELECT * FROM [$StoreName] WHERE SessionId = '$($($OfflineStoreDT | Select-Object SessionId -unique | Select-Object -last 2 | Select-Object -first 1).SessionId)' AND $FilterString"
      }
    }

    default {
      if ( $filter -eq "" ) {
        Sync-NMAOfflineStore "SELECT * FROM [$StoreName] WHERE SessionId LIKE `'$($SessionSelector)`'"
      } else {
        Sync-NMAOfflineStore "SELECT * FROM [$StoreName] WHERE SessionId LIKE `'$($SessionSelector)`' AND $FilterString"
      }
    }
  }
}

##############################################################################

Set-Alias nma-h         Get-NMAHelp
Set-Alias nma-profile   New-NMAProfile
Set-Alias nma-profiles  Get-NMAProfiles

Set-Alias nma-mods      New-NMAModules
Set-Alias nma-bfmods    New-NMABfModules
Set-Alias nma-ssn       New-NMASession

Set-Alias nma-entities  Get-OSLIMEntities
Set-Alias nma-entity    Get-OSLIMEntityItems
Set-Alias nma-ds        Sync-OSLIMNodes
Set-Alias nma-sstore    Sync-NMASessionStore
Set-Alias nma-rstore    Reset-NMASessionStore

Set-Alias nma-qssn      Get-NMASessionItems
Set-Alias nma-xssn      Export-NMASession
Set-Alias nma-ussn      Update-NMASession
Set-Alias nma-gssn      Get-NMASession
Set-Alias nma-rssn      Remove-NMASession

Set-Alias nma-gonet     Start-NMAScanNetwork
Set-Alias nma-gohost    Start-NMAScanHost
Set-Alias nma-gofile    Start-NMAScanFromFile
Set-Alias nma-godb      Start-NMAScanFromDb
Set-Alias nma-gossn     Start-NMAScanFromSession
Set-Alias nma-go        Start-NMASession

##############################################################################