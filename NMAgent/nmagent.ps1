##############################################################################
# Name:    NMTools for OpenSLIM.
# Module:  NMAgent - Network Management Agent
# Version: 4.54b0
# Date:    2010/12/11
# Author:  Carlos Veira Lorenzo - cveira [at] thinkinbig [dot] org
##############################################################################
# NMTools for OpenSLIM.
# Copyright (C) 2006-2009 Carlos Veira Lorenzo.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
##############################################################################
# Reference Sites:
#   http://www.thinkinbig.org/
#   http://www.xlnetworks.net/
##############################################################################
# General use syntax:
#   nmagent [-cmd]    {run|list|query|analyze|export|update|purge|shell|archive|reload}
#
#           [*-db]
#           [-file    [<input-file>]]
#           [-node    {<host-name>|<ip-address>|<host-list>}]
#           [-network [<network/class>|<network-range>]]
#           [-session [all|first|*last|<session-id>|<session-id>;<session-id>]]
#
#           [-profile <profile-name>]
#           [-store   {none|<store-name>}]
#           [-filter  "[[!]<1:ErrorFound>][;[!]<2:Property>][;[!]<3:Attribute>][;[!]<4:Value>]
#                      [;[!]<5:ValueMemo>][;[!]<6:QueryOutput>][;[!]<7:NodeName>][;[!]<8:NodeIP>]
#                      [;[!]<9:AgentNode>][;[!]<10:AgentUser>]"
#           [-view    [*simple|errors|memo|raw|agents|users]]
#           [-save|-test]
#           [-setup]
#           [-rta]
#           [-help]
#
# Use cases:
#   nmagent -help
#
#   nmagent run     [*-db]                                            [-profile <name>] [-setup] [-rta] [-save|-test]
#   nmagent run     [-file    [<input-file>]]                         [-profile <name>] [-setup] [-rta] [-save|-test]
#   nmagent run     [-node    {<host-name>|<ip-address>|<host-list>}] [-profile <name>] [-setup] [-rta] [-save|-test]
#   nmagent run     [-network [<network/class>|<network-range>]]      [-profile <name>] [-setup] [-rta] [-save|-test]
#   nmagent run     [-session [all|first|*last|<session-id>]]         [-profile <name>] [-setup] [-rta] [-save|-test] [-filter <pattern>]
#
#   nmagent list    [-session [all|first|*last]]                                  [-store {none|<store-name>}]
#   nmagent query   [-session [all|first|*last|<session-id>]] [-filter <pattern>] [-store <store-name>] [-view [*simple|errors|memo|raw]]
#   nmagent purge   [-session [all|first|*last|<session-id>]] [-filter <pattern>] [-store <store-name>]
#   nmagent purge   [-store <store-name>]
#
#   nmagent archive [-session [all|first|*last|<session-id>]] [-filter <pattern>] [-store <store-name>]
#   nmagent reload  [-session [all|first|*last|<session-id>]] [-filter <pattern>] [-store <store-name>]
#
#   nmagent export  [-session [all|first|*last|<session-id>]] [-filter <pattern>]
#   nmagent analyze [-session [all|first|*last|<session-id>]] [-filter <pattern>]
#   nmagent update  [-session [all|first|*last|<session-id>]] [-filter <pattern>]
#
#   nmagent compare [-session [first|*last|<session-id>;<session-id>]] [-filter <pattern>]
#
#   nmagent shell   [-profile <name>]
##############################################################################
# Set-ExecutionPolicy remotesigned
# $PSSettings = "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds"
# Set-ItemProperty $PSSettings ConsolePrompting True
# Set-PSDebug <-Off|-Trace {1,2}> -Step -Strict
# $host.EnterNestedPrompt()
# $StackTrace
# Get-PSCallStack
##############################################################################
# Get-WmiObject -query "select * from __namespace" -namespace root | Select-Object name
# Get-WmiObject -ComputerName <$server> -credential <$creds> -namespace "root\default" -list
# Get-WmiObject -ComputerName <$server> -credential <$creds> -query "select * from Win32_XXXXX"
# Get-WmiObject -ComputerName <$server> -credential <$creds> -class Win32_XXXXX -filter ""
##############################################################################

param (
  [string] $cmd     = "list"   ,

  [switch] $db                 ,
  [switch] $file               ,
  [switch] $node               ,
  [switch] $network            ,
  [switch] $session            ,

  [string] $TargetObject       ,

  [string] $profile = "main"   ,
  [string] $filter  = ""       ,
  [string] $view    = 'simple' ,
  [switch] $save               ,
  [switch] $test               ,
  [switch] $setup              ,
  [switch] $rta                ,
  [string] $store              ,
  [switch] $help
)

##############################################################################

process {
  $src                        = ""

  $COLOR_BRIGHT               = 'Yellow'
  $COLOR_DARK                 = 'DarkGray'
  $COLOR_RESULT               = 'Green' # 'DarkCyan'
  $COLOR_NORMAL               = 'White'
  $COLOR_ERROR                = 'Red'
  $COLOR_ENPHASIZE            = 'Magenta'

  $PROFILE_DEFAULT            = 'main'
  $PROFILE_MAIN               = 'main'

  $CMD_EXEC                   = 'run'
  $CMD_LIST                   = 'list'
  $CMD_QUERY                  = 'query'
  $CMD_ANALYZE                = 'analyze'
  $CMD_COMPARE                = 'compare'
  $CMD_EXPORT                 = 'export'
  $CMD_UPDATE                 = 'update'
  $CMD_PURGE                  = 'purge'
  $CMD_SHELL                  = 'shell'
  $CMD_ARCHIVE                = 'archive'
  $CMD_RELOAD                 = 'reload'

  $TARGET_DB                  = 'db'
  $TARGET_FILE                = 'file'
  $TARGET_HOST                = 'node'
  $TARGET_NETWORK             = 'network'
  $TARGET_SESSION             = 'session'
  $TARGET_SESSION_ALL         = 'all'
  $TARGET_SESSION_FIRST       = 'first'
  $TARGET_SESSION_LAST        = 'last'

  $TARGET_SESSION_SECOND      = "second"
  $TARGET_SESSION_PENULTIMATE = "penultimate"

  $VIEW_SIMPLE                = 'simple'
  $VIEW_ERRORS                = 'errors'
  $VIEW_MEMO                  = 'memo'
  $VIEW_RAW                   = 'raw'
  $VIEW_AGENTS                = 'agents'
  $VIEW_USERS                 = 'users'

  $REGEX_HOSTNAME             = '(^\d{1,2}\.\d{1,3}\.\d{1,3}\.\d{1,3}$)|(^[\w+(-|.)]+$)'
  $REGEX_HOSTLIST             = "(((\b\d{1,2}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b)|(\b[\w(-|\.)]+\b))|,?)+"
  $REGEX_IP                   = '^\d{1,2}\.\d{1,3}\.\d{1,3}\.\d{1,3}$'                                   # 0 or 000..255: ^([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])$
  $REGEX_NWCLASS              = '^\d{1,2}\.\d{1,3}\.\d{1,3}\.\d{1,3}/\d{1,2}$'
  $REGEX_NWRANGE              = '^\d{1,2}\.\d{1,3}\.\d{1,3}\.\d{1,3}-\d{1,3}$'
  $REGEX_SESSION              = '(^\d{6,8}-\d{2,4}-\d{1,2}-\d{2,4}$)|(^[\d+(-|%)]+$)|((^[\d+(-|%)]+);([\d+(-|%)]+)$)'

  $MULTI_SESSION_DELIMITER    = ";"
  $STATUS_YES                 = 'Y'
  $STATUS_NO                  = 'N'

  $PLEX_INPUT_DELIMITER       = ","
  $DAX_PROPERTY_DELIMITER     = ","
  $DAX_VALUE_DELIMITER        = ":"
  $DAX_PROPERTY_NAME          = 0
  $DAX_PROPERTY_VALUE         = 1


  $PipeLineInput              = $_

  $SessionId                  = Get-Date
  $SessionId                  = "$($SessionId.Year)$($SessionId.Month)$($SessionId.Day)-$($SessionId.Hour)$($SessionId.Minute)-$($SessionId.Second)-$($SessionId.Millisecond)"
  $LogSessionId               = "$( $SessionId -replace '-', '' )"

  $SsnStartTime
  $SsnEndTime
  $SsnElapsedTime

  $ModStartTime
  $ModEndTime
  $ModElapsedTime

  $UNKNOWN_HOSTNAME           = "Unknown"
  $UNKNOWN_ITEM               = "Unknown"
  $STATUS_NODE_ISALIVE        = 0
  $DisableFormatOutput        = $false

  $SetConnectToHostByIP       = $false
  $TargetNode                 = ""

  $ViewIsSimple               = $false
  $ViewIsErrors               = $false
  $ViewIsMemo                 = $false
  $ViewIsRaw                  = $false

  $NMAgentDbType_MSAccess     = "ms-access"
  $NMAgentDbType_MSSQLServer  = "ms-sql-server"

  $AgentNodeName              = "$( hostname )"


  # NodeCredentials ::= {'BFModules_ServiceTag', 'NodeUser', 'NodePassword'}

  $NodeCredentials_ServiceTag   = 0
  $NodeCredentials_NodeUser     = 1
  $NodeCredentials_NodePassword = 2


  # BFModules ::= {BFModules_IsEnabled, 'BFModules_ServiceTag', 'BFModules_ModuleName'}

  $BFModules_IsEnabled          = 0
  $BFModules_ServiceTag         = 1
  $BFModules_ModuleName         = 2


  # NMAModules ::= {IsEnabled, IsSupported, DataTypeIsString, 'ModuleName'}

  $NMAModules_IsEnabled         = 0
  $NMAModules_IsSupported       = 1
  $NMAModules_DataTypeIsString  = 2
  $NMAModules_ServiceTag        = 3
  $NMAModules_ModuleName        = 4
  $NMAModules_IsDaX             = 5
  $NMAModules_DependsOn         = 6


  # [-filter "[[!]<ErrorFound>][;[!]<Property>][;[!]<Attribute>][;[!]<Value>]"
  # UserFilter ::= {IsActive, IsNot, Value}

  $UserFilter_IsActive          = 0
  $UserFilter_IsNot             = 1
  $UserFilter_Value             = 2

  $FILTER_DELIMITER             = ";"
  $FILTER_ISNOT_TOKEN           = "!"
  $FILTER_DEFAULT_VALUE         = ""

  $UserFilter = @{
    ErrorFound    = $false, $false, $FILTER_DEFAULT_VALUE;
    PropertyName  = $false, $false, $FILTER_DEFAULT_VALUE;
    AttributeName = $false, $false, $FILTER_DEFAULT_VALUE;
    Value         = $false, $false, $FILTER_DEFAULT_VALUE;
    ValueMemo     = $false, $false, $FILTER_DEFAULT_VALUE;
    QueryOutput   = $false, $false, $FILTER_DEFAULT_VALUE;
    NodeName      = $false, $false, $FILTER_DEFAULT_VALUE;
    NodeIP        = $false, $false, $FILTER_DEFAULT_VALUE;
    AgentNode     = $false, $false, $FILTER_DEFAULT_VALUE;
    AgentUser     = $false, $false, $FILTER_DEFAULT_VALUE
  }


  ##############################################################################

  $InstallDir                 = $( Get-ChildItem $MyInvocation.InvocationName | Select-Object Directory |
                                   Format-Table -AutoSize -HideTableHeaders | Out-String ).Trim()

  if ( $InstallDir.Split(":").Length -gt 2 ) {
    $InstallDir               = $( Get-Location | Select-Object Path |
                                   Format-Table -AutoSize -HideTableHeaders | Out-String ).Trim()
  }

  $AuthDir                       = $InstallDir + "\auth"
  $SettingsDir                   = $InstallDir + "\settings"
  $ModulesDir                    = $InstallDir + "\modules"
  $GlobalHooksDir                = $InstallDir + "\modules\_hooks"
  $LogsDir                       = $InstallDir + "\logs"
  $BinDir                        = $InstallDir + "\bin"

  $ExportDirName                 = "export"
  $SettingsDirName               = "_settings"
  $HooksDirName                  = "_hooks"
  $EnabledModulesDirName         = "_enabled"
  $PreSession_HookDirName        = "PreSession"
  $PostSession_HookDirName       = "PostSession"
  $PreNode_HookDirName           = "PreNode"
  $PostNode_HookDirName          = "PostNode"
  $PreModule_HookDirName         = "PreModule"
  $PostModule_HookDirName        = "PostModule"
  $PreMContext_HookDirName       = "PreMContext"
  $PostMContext_HookDirName      = "PostMContext"

  $HookTarget_IsSession          = 0
  $HookTarget_IsNode             = 1
  $HookTarget_IsModule           = 2
  $HookTarget_IsMContext         = 3
  $HookScope_IsGlobal            = 0
  $HookScope_IsLibrary           = 1
  $HookTrigger_IsBefore          = 0
  $HookTrigger_IsAfter           = 1


  [string] $DefaultInputFile     = $SettingsDir + "\hosts.txt"
  [string] $DefaultInputFilePath = $(Get-Location).Path

  ##############################################################################

  function GetScriptSyntax() {
    $ScriptSyntax = @"
  NMTools for OpenSLIM v4.54b0, Copyright (C) 2009 Carlos Veira Lorenzo.
  NMTools and OpenSLIM come with ABSOLUTELY NO WARRANTY. This is free
  software under GPL 2.0 license terms and conditions.

  NMAgent - Network Management Agent [http://thinkinbig.org]
  -------------------------------------------------------------------------------------------
  nmagent [-cmd]    {run|list|query|analyze|compare|export|update|purge|shell|archive|reload}

          [*-db]
          [-file    [<input-file>]]
          [-node    {<host-name>|<ip-address>|<host-list>}]
          [-network [<network/class>|<network-range>]]
          [-session [all|first|*last|<session-id>|<session-id>;<session-id>]]

          [-profile <profile-name>]
          [-store   {none|<store-name>}]
          [-filter  "[[!]<1:ErrorFound>][;[!]<2:Property>][;[!]<3:Attribute>][;[!]<4:Value>]
                     [;[!]<5:ValueMemo>][;[!]<6:QueryOutput>][;[!]<7:NodeName>][;[!]<8:NodeIP>]
                     [;[!]<9:AgentNode>][;[!]<10:AgentUser>]"
          [-view    [*simple|errors|memo|raw|agents|users]]
          [-save|-test]
          [-setup]
          [-rta]
          [-help]
  -------------------------------------------------------------------------------------------
  Use cases:
    nmagent -help

    nmagent run     [*-db]                                            [-profile <name>] [-setup] [-rta] [-save|-test]
    nmagent run     [-file    [<input-file>]]                         [-profile <name>] [-setup] [-rta] [-save|-test]
    nmagent run     [-node    {<host-name>|<ip-address>|<host-list>}] [-profile <name>] [-setup] [-rta] [-save|-test]
    nmagent run     [-network [<network/class>|<network-range>]]      [-profile <name>] [-setup] [-rta] [-save|-test]
    nmagent run     [-session [all|first|*last|<session-id>]]         [-profile <name>] [-setup] [-rta] [-save|-test]
                    [-filter  <pattern>]

    nmagent list    [-session [all|first|*last]]                                  [-store {none|<store-name>}]
    nmagent query   [-session [all|first|*last|<session-id>]] [-filter <pattern>] [-store <store-name>]
                    [-view    [*simple|errors|memo|raw|agents|users]]

    nmagent purge   [-session [all|first|*last|<session-id>]] [-filter <pattern>] [-store <store-name>]
    nmagent purge   [-store   <store-name>]

    nmagent archive [-session [all|first|*last|<session-id>]] [-filter <pattern>] [-store <store-name>]
    nmagent reload  [-session [all|first|*last|<session-id>]] [-filter <pattern>] [-store <store-name>]

    nmagent export  [-session [all|first|*last|<session-id>]] [-filter <pattern>]
    nmagent analyze [-session [all|first|*last|<session-id>]] [-filter <pattern>]
    nmagent update  [-session [all|first|*last|<session-id>]] [-filter <pattern>]

    nmagent compare [-session [first|*last|<session-id>;<session-id>]] [-filter <pattern>]

    nmagent shell   [-profile <name>]
"@

    Write-Host
    Write-Host -foregroundcolor $COLOR_BRIGHT $ScriptSyntax
    Write-Host

    exit 1
  }

  ##############################################################################

  function CheckScriptSyntax() {
    function LoadFilter() {
      if ( $filter -ne "" ) {
        $FilterElements = $filter.Split($FILTER_DELIMITER)


        if ( $FilterElements[0] -ne "" ) {
          $UserFilter.ErrorFound[$UserFilter_IsActive]    = $true

          if ( $FilterElements[0].StartsWith($FILTER_ISNOT_TOKEN) ) {
            $UserFilter.ErrorFound[$UserFilter_IsNot]     = $true
            $UserFilter.ErrorFound[$UserFilter_Value]     = $FilterElements[0].Substring(1)
          } else {
            $UserFilter.ErrorFound[$UserFilter_IsNot]     = $false
            $UserFilter.ErrorFound[$UserFilter_Value]     = $FilterElements[0]
          }
        } else {
          $UserFilter.ErrorFound[$UserFilter_IsActive]    = $false
          $UserFilter.ErrorFound[$UserFilter_IsNot]       = $false
          $UserFilter.ErrorFound[$UserFilter_Value]       = $FILTER_DEFAULT_VALUE
        }


        if ( $FilterElements.Length -gt 1 ) {
          if ( $FilterElements[1] -ne "" ) {
            $UserFilter.PropertyName[$UserFilter_IsActive]  = $true

            if ( $FilterElements[1].StartsWith($FILTER_ISNOT_TOKEN) ) {
              $UserFilter.PropertyName[$UserFilter_IsNot]   = $true
              $UserFilter.PropertyName[$UserFilter_Value]   = $FilterElements[1].Substring(1)
            } else {
              $UserFilter.PropertyName[$UserFilter_IsNot]   = $false
              $UserFilter.PropertyName[$UserFilter_Value]   = $FilterElements[1]
            }
          } else {
            $UserFilter.PropertyName[$UserFilter_IsActive]  = $false
            $UserFilter.PropertyName[$UserFilter_IsNot]     = $false
            $UserFilter.PropertyName[$UserFilter_Value]     = $FILTER_DEFAULT_VALUE
          }
        }


        if ( $FilterElements.Length -gt 2 ) {
          if ( $FilterElements[2] -ne "" ) {
            $UserFilter.AttributeName[$UserFilter_IsActive] = $true

            if ( $FilterElements[2].StartsWith($FILTER_ISNOT_TOKEN) ) {
              $UserFilter.AttributeName[$UserFilter_IsNot]  = $true
              $UserFilter.AttributeName[$UserFilter_Value]  = $FilterElements[2].Substring(1)
            } else {
              $UserFilter.AttributeName[$UserFilter_IsNot]  = $false
              $UserFilter.AttributeName[$UserFilter_Value]  = $FilterElements[2]
            }
          } else {
            $UserFilter.AttributeName[$UserFilter_IsActive] = $false
            $UserFilter.AttributeName[$UserFilter_IsNot]    = $false
            $UserFilter.AttributeName[$UserFilter_Value]    = $FILTER_DEFAULT_VALUE
          }
        }


        if ( $FilterElements.Length -gt 3 ) {
          if ( $FilterElements[3] -ne "" ) {
            $UserFilter.Value[$UserFilter_IsActive]         = $true

            if ( $FilterElements[3].StartsWith($FILTER_ISNOT_TOKEN) ) {
              $UserFilter.Value[$UserFilter_IsNot]          = $true
              $UserFilter.Value[$UserFilter_Value]          = $FilterElements[3].Substring(1)
            } else {
              $UserFilter.Value[$UserFilter_IsNot]          = $false
              $UserFilter.Value[$UserFilter_Value]          = $FilterElements[3]
            }
          } else {
            $UserFilter.Value[$UserFilter_IsActive]         = $false
            $UserFilter.Value[$UserFilter_IsNot]            = $false
            $UserFilter.Value[$UserFilter_Value]            = $FILTER_DEFAULT_VALUE
          }
        }


        if ( $FilterElements.Length -gt 4 ) {
          if ( $FilterElements[4] -ne "" ) {
            $UserFilter.ValueMemo[$UserFilter_IsActive]     = $true

            if ( $FilterElements[4].StartsWith($FILTER_ISNOT_TOKEN) ) {
              $UserFilter.ValueMemo[$UserFilter_IsNot]      = $true
              $UserFilter.ValueMemo[$UserFilter_Value]      = $FilterElements[4].Substring(1)
            } else {
              $UserFilter.ValueMemo[$UserFilter_IsNot]      = $false
              $UserFilter.ValueMemo[$UserFilter_Value]      = $FilterElements[4]
            }
          } else {
            $UserFilter.ValueMemo[$UserFilter_IsActive]     = $false
            $UserFilter.ValueMemo[$UserFilter_IsNot]        = $false
            $UserFilter.ValueMemo[$UserFilter_Value]        = $FILTER_DEFAULT_VALUE
          }
        }


        if ( $FilterElements.Length -gt 5 ) {
          if ( $FilterElements[5] -ne "" ) {
            $UserFilter.QueryOutput[$UserFilter_IsActive]   = $true

            if ( $FilterElements[5].StartsWith($FILTER_ISNOT_TOKEN) ) {
              $UserFilter.QueryOutput[$UserFilter_IsNot]    = $true
              $UserFilter.QueryOutput[$UserFilter_Value]    = $FilterElements[5].Substring(1)
            } else {
              $UserFilter.QueryOutput[$UserFilter_IsNot]    = $false
              $UserFilter.QueryOutput[$UserFilter_Value]    = $FilterElements[5]
            }
          } else {
            $UserFilter.QueryOutput[$UserFilter_IsActive]   = $false
            $UserFilter.QueryOutput[$UserFilter_IsNot]      = $false
            $UserFilter.QueryOutput[$UserFilter_Value]      = $FILTER_DEFAULT_VALUE
          }
        }


        if ( $FilterElements.Length -gt 6 ) {
          if ( $FilterElements[6] -ne "" ) {
            $UserFilter.NodeName[$UserFilter_IsActive]      = $true

            if ( $FilterElements[6].StartsWith($FILTER_ISNOT_TOKEN) ) {
              $UserFilter.NodeName[$UserFilter_IsNot]       = $true
              $UserFilter.NodeName[$UserFilter_Value]       = $FilterElements[6].Substring(1)
            } else {
              $UserFilter.NodeName[$UserFilter_IsNot]       = $false
              $UserFilter.NodeName[$UserFilter_Value]       = $FilterElements[6]
            }
          } else {
            $UserFilter.NodeName[$UserFilter_IsActive]      = $false
            $UserFilter.NodeName[$UserFilter_IsNot]         = $false
            $UserFilter.NodeName[$UserFilter_Value]         = $FILTER_DEFAULT_VALUE
          }
        }


        if ( $FilterElements.Length -gt 7 ) {
          if ( $FilterElements[7] -ne "" ) {
            $UserFilter.NodeIP[$UserFilter_IsActive]        = $true

            if ( $FilterElements[7].StartsWith($FILTER_ISNOT_TOKEN) ) {
              $UserFilter.NodeIP[$UserFilter_IsNot]         = $true
              $UserFilter.NodeIP[$UserFilter_Value]         = $FilterElements[7].Substring(1)
            } else {
              $UserFilter.NodeIP[$UserFilter_IsNot]         = $false
              $UserFilter.NodeIP[$UserFilter_Value]         = $FilterElements[7]
            }
          } else {
            $UserFilter.NodeIP[$UserFilter_IsActive]        = $false
            $UserFilter.NodeIP[$UserFilter_IsNot]           = $false
            $UserFilter.NodeIP[$UserFilter_Value]           = $FILTER_DEFAULT_VALUE
          }
        }


        if ( $FilterElements.Length -gt 8 ) {
          if ( $FilterElements[8] -ne "" ) {
            $UserFilter.AgentNode[$UserFilter_IsActive]     = $true

            if ( $FilterElements[8].StartsWith($FILTER_ISNOT_TOKEN) ) {
              $UserFilter.AgentNode[$UserFilter_IsNot]      = $true
              $UserFilter.AgentNode[$UserFilter_Value]      = $FilterElements[8].Substring(1)
            } else {
              $UserFilter.AgentNode[$UserFilter_IsNot]      = $false
              $UserFilter.AgentNode[$UserFilter_Value]      = $FilterElements[8]
            }
          } else {
            $UserFilter.AgentNode[$UserFilter_IsActive]     = $false
            $UserFilter.AgentNode[$UserFilter_IsNot]        = $false
            $UserFilter.AgentNode[$UserFilter_Value]        = $FILTER_DEFAULT_VALUE
          }
        }


        if ( $FilterElements.Length -gt 9 ) {
          if ( $FilterElements[9] -ne "" ) {
            $UserFilter.AgentUser[$UserFilter_IsActive]     = $true

            if ( $FilterElements[9].StartsWith($FILTER_ISNOT_TOKEN) ) {
              $UserFilter.AgentUser[$UserFilter_IsNot]      = $true
              $UserFilter.AgentUser[$UserFilter_Value]      = $FilterElements[9].Substring(1)
            } else {
              $UserFilter.AgentUser[$UserFilter_IsNot]      = $false
              $UserFilter.AgentUser[$UserFilter_Value]      = $FilterElements[9]
            }
          } else {
            $UserFilter.AgentUser[$UserFilter_IsActive]     = $false
            $UserFilter.AgentUser[$UserFilter_IsNot]        = $false
            $UserFilter.AgentUser[$UserFilter_Value]        = $FILTER_DEFAULT_VALUE
          }
        }
      } else {
        $UserFilter = @{
          ErrorFound    = $false, $false, $FILTER_DEFAULT_VALUE;
          PropertyName  = $false, $false, $FILTER_DEFAULT_VALUE;
          AttributeName = $false, $false, $FILTER_DEFAULT_VALUE;
          Value         = $false, $false, $FILTER_DEFAULT_VALUE;
          ValueMemo     = $false, $false, $FILTER_DEFAULT_VALUE;
          QueryOutput   = $false, $false, $FILTER_DEFAULT_VALUE;
          NodeName      = $false, $false, $FILTER_DEFAULT_VALUE;
          NodeIP        = $false, $false, $FILTER_DEFAULT_VALUE;
          AgentNode     = $false, $false, $FILTER_DEFAULT_VALUE;
          AgentUser     = $false, $false, $FILTER_DEFAULT_VALUE
        }
      }
    }


    if ($help) { GetScriptSyntax }

    if ( !( ( $cmd.ToLower() -eq $CMD_EXEC    ) -or ( $cmd.ToLower() -eq $CMD_QUERY   ) -or
            ( $cmd.ToLower() -eq $CMD_UPDATE  ) -or ( $cmd.ToLower() -eq $CMD_LIST    ) -or
            ( $cmd.ToLower() -eq $CMD_PURGE   ) -or ( $cmd.ToLower() -eq $CMD_EXPORT  ) -or
            ( $cmd.ToLower() -eq $CMD_COMPARE ) -or ( $cmd.ToLower() -eq $CMD_ANALYZE ) -or
            ( $cmd.ToLower() -eq $CMD_ARCHIVE ) -or ( $cmd.ToLower() -eq $CMD_RELOAD  ) -or
            ( $cmd.ToLower() -eq $CMD_SHELL   ) ) ) { GetScriptSyntax }

    if ( ( $cmd.ToLower() -eq $CMD_SHELL ) -and ( $db -or $file -or $node -or $network -or $session ) ) { GetScriptSyntax }

    $ParamCount = 0
    if ( $db               ) { $src = $TARGET_DB      ; $ParamCount++ }
    if ( $file             ) { $src = $TARGET_FILE    ; $ParamCount++ }
    if ( $node             ) { $src = $TARGET_HOST    ; $ParamCount++ }
    if ( $network          ) { $src = $TARGET_NETWORK ; $ParamCount++ }
    if ( $session          ) { $src = $TARGET_SESSION ; $ParamCount++ }
    if ( $ParamCount -gt 1 ) { GetScriptSyntax }

    if ( ( $cmd.ToLower() -eq $CMD_EXEC  ) -and ( $ParamCount -eq 0 ) ) { $src = $TARGET_DB }

    if ( !( ( $view.ToLower() -eq $VIEW_SIMPLE ) -or ( $view.ToLower() -eq $VIEW_ERRORS ) -or
            ( $view.ToLower() -eq $VIEW_MEMO   ) -or ( $view.ToLower() -eq $VIEW_RAW    ) -or
            ( $view.ToLower() -eq $VIEW_AGENTS ) -or ( $view.ToLower() -eq $VIEW_USERS  ) ) ) { GetScriptSyntax }


    switch -case ( $cmd.ToLower() ) {
      $CMD_EXEC {
        switch -case ( $src ) {
          $TARGET_FILE {
            if ( $TargetObject.ToLower() -ne "" ) {
              $InputFile   = $TargetObject.ToLower()
            } else {
              if ( Test-Path $DefaultInputFile ) {
                $InputFile = $DefaultInputFile
              } else {
                GetScriptSyntax
              }
            }
          }

          $TARGET_HOST {
            if ( !( ( $TargetObject.ToLower() -match $REGEX_HOSTNAME )       -or
                    ( $TargetObject.ToLower() -match $REGEX_HOSTLIST )       -or
                    ( $TargetObject.ToLower() -match $REGEX_IP       ) ) )   { GetScriptSyntax }
          }

          $TARGET_NETWORK {
            if ( !( ( $TargetObject.ToLower() -match $REGEX_NWRANGE )        -or
                    ( $TargetObject.ToLower() -match $REGEX_NWCLASS ) ) )    { GetScriptSyntax }
          }

          $TARGET_SESSION {
            if ( !( ( $TargetObject.ToLower() -eq    $TARGET_SESSION_ALL   )     -or
                    ( $TargetObject.ToLower() -eq    $TARGET_SESSION_FIRST )     -or
                    ( $TargetObject.ToLower() -eq    $TARGET_SESSION_LAST  )     -or
                    ( $TargetObject.ToLower() -match $REGEX_SESSION        ) ) ) { GetScriptSyntax }
          }
        }
      }

      $CMD_QUERY {
        if ( !$session ) { $src = $TARGET_SESSION ; $TargetObject = $TARGET_SESSION_LAST }

        switch -case ( $src ) {
          $TARGET_SESSION {
            if ( !( ( $TargetObject.ToLower() -eq    $TARGET_SESSION_ALL   )     -or
                    ( $TargetObject.ToLower() -eq    $TARGET_SESSION_FIRST )     -or
                    ( $TargetObject.ToLower() -eq    $TARGET_SESSION_LAST  )     -or
                    ( $TargetObject.ToLower() -match $REGEX_SESSION        ) ) ) { GetScriptSyntax }
          }
        }
      }

      $CMD_ARCHIVE {
        if ( !$store ) { $store = $SessionId }
        if ( !$session ) { $src = $TARGET_SESSION ; $TargetObject = $TARGET_SESSION_LAST }

        switch -case ( $src ) {
          $TARGET_SESSION {
            if ( !( ( $TargetObject.ToLower() -eq    $TARGET_SESSION_ALL   )     -or
                    ( $TargetObject.ToLower() -eq    $TARGET_SESSION_FIRST )     -or
                    ( $TargetObject.ToLower() -eq    $TARGET_SESSION_LAST  )     -or
                    ( $TargetObject.ToLower() -match $REGEX_SESSION        ) ) ) { GetScriptSyntax }
          }
        }
      }

      $CMD_RELOAD {
        if ( !$store ) { $store = $SessionId }
        if ( !$session ) { $src = $TARGET_SESSION ; $TargetObject = $TARGET_SESSION_LAST }

        switch -case ( $src ) {
          $TARGET_SESSION {
            if ( !( ( $TargetObject.ToLower() -eq    $TARGET_SESSION_ALL   )     -or
                    ( $TargetObject.ToLower() -eq    $TARGET_SESSION_FIRST )     -or
                    ( $TargetObject.ToLower() -eq    $TARGET_SESSION_LAST  )     -or
                    ( $TargetObject.ToLower() -match $REGEX_SESSION        ) ) ) { GetScriptSyntax }
          }
        }
      }

      $CMD_COMPARE {
        if ( !$session ) { $src = $TARGET_SESSION ; $TargetObject = $TARGET_SESSION_LAST }

        switch -case ( $src ) {
          $TARGET_SESSION {
            if ( !( ( $TargetObject.ToLower() -eq    $TARGET_SESSION_FIRST )     -or
                    ( $TargetObject.ToLower() -eq    $TARGET_SESSION_LAST  )     -or
                    ( $TargetObject.ToLower() -match $REGEX_SESSION        ) ) ) { GetScriptSyntax }
          }
        }
      }

      $CMD_ANALYZE {
        if ( !$session ) { $src = $TARGET_SESSION ; $TargetObject = $TARGET_SESSION_LAST }

        switch -case ( $src ) {
          $TARGET_SESSION {
            if ( !( ( $TargetObject.ToLower() -eq    $TARGET_SESSION_ALL   )     -or
                    ( $TargetObject.ToLower() -eq    $TARGET_SESSION_FIRST )     -or
                    ( $TargetObject.ToLower() -eq    $TARGET_SESSION_LAST  )     -or
                    ( $TargetObject.ToLower() -match $REGEX_SESSION        ) ) ) { GetScriptSyntax }
          }
        }
      }

      $CMD_EXPORT {
        if ( !$session ) { $src = $TARGET_SESSION ; $TargetObject = $TARGET_SESSION_LAST }

        switch -case ( $src ) {
          $TARGET_SESSION {
            if ( !( ( $TargetObject.ToLower() -eq    $TARGET_SESSION_ALL   )     -or
                    ( $TargetObject.ToLower() -eq    $TARGET_SESSION_FIRST )     -or
                    ( $TargetObject.ToLower() -eq    $TARGET_SESSION_LAST  )     -or
                    ( $TargetObject.ToLower() -match $REGEX_SESSION        ) ) ) { GetScriptSyntax }
          }
        }
      }

      $CMD_UPDATE {
        if ( !$session ) { $src = $TARGET_SESSION ; $TargetObject = $TARGET_SESSION_LAST }

        switch -case ( $src ) {
          $TARGET_SESSION {
            if ( !( ( $TargetObject.ToLower() -eq    $TARGET_SESSION_ALL   )     -or
                    ( $TargetObject.ToLower() -eq    $TARGET_SESSION_FIRST )     -or
                    ( $TargetObject.ToLower() -eq    $TARGET_SESSION_LAST  )     -or
                    ( $TargetObject.ToLower() -match $REGEX_SESSION        ) ) ) { GetScriptSyntax }
          }
        }
      }

      $CMD_LIST {
        if ( !$session ) { $src = $TARGET_SESSION ; $TargetObject = $TARGET_SESSION_LAST }

        switch -case ( $src ) {
          $TARGET_SESSION {
            if ( !( ( $TargetObject.ToLower() -eq    $TARGET_SESSION_ALL   )     -or
                    ( $TargetObject.ToLower() -eq    $TARGET_SESSION_FIRST )     -or
                    ( $TargetObject.ToLower() -eq    $TARGET_SESSION_LAST  )     -or
                    ( $TargetObject.ToLower() -match $REGEX_SESSION        ) ) ) { GetScriptSyntax }
          }
        }
      }

      $CMD_PURGE {
        if ( !$session ) { $src = $TARGET_SESSION ; $TargetObject = $TARGET_SESSION_LAST }

        switch -case ( $src ) {
          $TARGET_SESSION {
            if ( !( ( $TargetObject.ToLower() -eq    $TARGET_SESSION_ALL   )     -or
                    ( $TargetObject.ToLower() -eq    $TARGET_SESSION_FIRST )     -or
                    ( $TargetObject.ToLower() -eq    $TARGET_SESSION_LAST  )     -or
                    ( $TargetObject.ToLower() -match $REGEX_SESSION        ) ) ) { GetScriptSyntax }
          }
        }
      }
    }

    LoadFilter
  }

  . CheckScriptSyntax

  ##############################################################################

  $CurrentProfile = $PROFILE_DEFAULT
  if ( ($profile -ne $null) -and ($profile.length -ne 0) ) { $CurrentProfile = $profile }

  if ( Test-Path $SettingsDir\settings-$CurrentProfile.ps1 ) {
    . $SettingsDir\settings-$CurrentProfile.ps1
  } else {
    Write-Host
    Write-Host -foregroundcolor $COLOR_ERROR  "  + ERROR: can't find profile settings file:           $SettingsDir\settings-$CurrentProfile.ps1"
    Write-Host -foregroundcolor $COLOR_NORMAL "    + INFO: falling back to default profile settings:  " -noNewLine
    Write-Host -foregroundcolor $COLOR_BRIGHT $SettingsDir\settings-$PROFILE_DEFAULT.ps1
    Write-Host

    $CurrentProfile = $PROFILE_DEFAULT

    if ( Test-Path $SettingsDir\settings-$CurrentProfile.ps1 ) {
      . $SettingsDir\settings-$CurrentProfile.ps1
    } else {
      Write-Host -foregroundcolor $COLOR_ERROR  "  + ERROR: can't find default profile settings file:   $SettingsDir\settings-$CurrentProfile.ps1"
      Write-Host -foregroundcolor $COLOR_NORMAL "    + INFO: halting NMAgent Session..."
      Write-Host

      break
    }
  }


  if ( $BruteForceLoginMode ) {
    $MultiCredentialMode       = $false

    if ( $PerHostBFLogin ) {
      $PerModuleBFLogin        = $false
    } else {
      $PerModuleBFLogin        = $true
      $EnableBFLoginExtensions = $true
    }
  } else {
    $PerHostBFLogin            = $false
    $PerModuleBFLogin          = $false
    $EnableBFLoginExtensions   = $false
  }

  ##############################################################################

  [string] $ErrorLogFile        = $LogsDir + "\NMAgent-ErrorLog-"     + $($SessionId -replace "-", "") + ".log"
  [string] $SkippedNodesFile    = $LogsDir + "\NMAgent-SkippedNodes-" + $($SessionId -replace "-", "") + ".log"
  [string] $FailedNodesFile     = $LogsDir + "\NMAgent-FailedNodes-"  + $($SessionId -replace "-", "") + ".log"
  [string] $FailedUsersFile     = $LogsDir + "\NMAgent-FailedUsers-"  + $($SessionId -replace "-", "") + ".log"
  [string] $SuccessfulUsersFile = $LogsDir + "\NMAgent-SuccessfulUsers-"  + $($SessionId -replace "-", "") + ".log"

  trap {
    $error | format-list -force * >> $ErrorLogFile
  }

  ##############################################################################

  Write-Host
  Write-Host -foregroundcolor $COLOR_BRIGHT "  NMAgent - Network Management Agent"
  Write-Host -foregroundcolor $COLOR_BRIGHT "  -------------------------------------------------------------------------------------------"

  Write-Host -foregroundcolor $COLOR_NORMAL -noNewLine "  + Loading kernel functions... "

  . $InstallDir\nmagent-shell.ps1
  . $InstallDir\nmagent-functions.ps1
  . $InstallDir\nmagent-actions.ps1
  . $InstallDir\modules-helper.ps1

  Write-Host -foregroundcolor $COLOR_BRIGHT "done"

  ##############################################################################

  Write-Host -foregroundcolor $COLOR_NORMAL -noNewLine "  + Stablishing data connections... "

  . LoadDataSets

  Write-Host -foregroundcolor $COLOR_BRIGHT "done"

  ##############################################################################

  $NMAModules      = @{}
  $LibraryModules  = @{}
  $NodeCredentials = @{}

  ##############################################################################

  if ( ( $cmd.ToLower() -eq $CMD_EXEC ) -or ( $cmd.ToLower() -eq $CMD_SHELL ) ) {
    if ( $MultiCredentialMode -or $BruteForceLoginMode ) {
      . LoadBFModulesTable
      . LoadBFModules
      . LoadCreadentials
      . LoadExtendedCredentials
    }
  }

  ##############################################################################

  if ( ( $cmd.ToLower() -eq $CMD_EXEC ) -or ( $cmd.ToLower() -eq $CMD_SHELL ) ) {
    . LoadExtendedSettings
  }

  ##############################################################################

  if ( ( $cmd.ToLower() -eq $CMD_EXEC ) -or ( $cmd.ToLower() -eq $CMD_SHELL ) ) {
    . LoadProfileModules
    . LoadModulesTable
  }

  ##############################################################################

  [string[]] $NMAModulesKeys      = $( $NMAModules.Keys      | Sort-Object )
  [string[]] $BFModulesKeys       = $( $BFModules.Keys       | Sort-Object )
  [string[]] $NodeCredentialsKeys = $( $NodeCredentials.Keys | Sort-Object )

  ##############################################################################

  if ( ( $cmd.ToLower() -eq $CMD_EXEC ) -or ( $cmd.ToLower() -eq $CMD_SHELL ) ) {
    if ( $setup ) {
      $SessionSetUpIsOk = $STATUS_NO

      do {
        Write-Host

        $SkipSessionSetUp = $STATUS_NO
        $SkipSessionSetUp = Read-Host "  + Do you want to change your Profile Settings? [Y/N]"

        if ( $SkipSessionSetUp.ToUpper() -eq $STATUS_YES ) {
          New-NMASession
        }

        New-NMAModules
        New-NMABfModules
        New-NMAExtendedSettings

        Write-Host
        Write-Host -foregroundcolor $COLOR_BRIGHT '  -------------------------------------------------------------------------------------------'
        Write-Host

        $SessionSetUpIsOk = Read-Host "  + Are these settings correct? [Y/N]"
      } while ( $SessionSetUpIsOk.ToUpper() -eq $STATUS_NO )
    }
  }

  ##############################################################################

  if ( ( $cmd.ToLower() -eq $CMD_EXEC ) -or ( $cmd.ToLower() -eq $CMD_SHELL ) ) {
    if ( $rta ) {
      Start-NMARunTimeAdvisor

      Write-Host
      Write-Host -foregroundcolor $COLOR_BRIGHT '  -------------------------------------------------------------------------------------------'
      Write-Host

      $SessionSetUpIsOk = $STATUS_NO
      $SessionSetUpIsOk = Read-Host "  + Are these settings correct? [Y/N]"

      if ( $SessionSetUpIsOk.ToUpper() -eq $STATUS_NO ) {
        Write-Host
        Write-Host -foregroundcolor $COLOR_ERROR  "  + INFO: Session aborted by user."
        Write-Host
        break
      }
    }
  }

  ##############################################################################

  if ( $cmd.ToLower() -eq $CMD_EXEC) {
    if ( (!$MultiCredentialMode) -and (!$BruteForceLoginMode) ) {
      $NetworkCredentials = Get-Credential $NetworkUserId
    }
  }

  ##############################################################################

  function Start-NMASession() {
    $ErrorActionPreference = "silentlycontinue"

    trap {
      $NMAgentStartNMASessionEvent = @"

  ===========================================================================================
  $(get-date -format u) -  Start-NMASession Error Event
  -------------------------------------------------------------------------------------------
  + Error Description: [$($($_.FullyQualifiedErrorId | Out-String).Trim())]

  $_

  + Category Information:

  $($($_.CategoryInfo | Out-String).Trim())

  + Invocation Information:

  $($($_.InvocationInfo | Out-String).Trim())

"@

      Write-Host
      Write-Host -foregroundcolor $COLOR_ERROR  "  +  Start-NMASession Error Event: " $_ "[" $_.InvocationInfo.ScriptLineNumber ":" $_.InvocationInfo.OffsetInLine "]"
      Write-Host

      $NMAgentStartNMASessionEvent >> $ErrorLogFile

      # break
    }


    [string] $TargetObjectName = $TargetObject
    [string] $FilterLabel      = $filter

    if ( ($TargetObject -eq $null) -or ($TargetObject.Length -eq 0) ) { [string] $TargetObjectName = "N/A" }
    if ( ($filter       -eq $null) -or ($filter.Length       -eq 0) ) { [string] $FilterLabel      = "N/A" }

    $NMAgentHeader = @"
  -------------------------------------------------------------------------------------------
  Session ID:                     $SessionId
  -------------------------------------------------------------------------------------------
  Profile:                        $CurrentProfile
  Command:                        $cmd
  Source:                         $src
  Target Object:                  $TargetObjectName
  Filter:                         $FilterLabel
  View:                           $view
  Save results:                   $save
  Test mode:                      $test
  -------------------------------------------------------------------------------------------
  Multi-Credential Mode:          $MultiCredentialMode
  Brute Force Login Mode:         $BruteForceLoginMode
  Save Brute Force Login Results: $SaveBFLoginResults
  Enable Brute Force Modules:     $EnableBFLoginExtensions
  Per-Host Brute Force Login:     $PerHostBFLogin
  Per-Module Brute Force Login:   $PerModuleBFLogin
  Encrypted Credentials:          $CredentialsDbIsEncrypted
  -------------------------------------------------------------------------------------------
  $(get-date -format u)
  -------------------------------------------------------------------------------------------
"@

    $NMAgentFooter = @"

  -------------------------------------------------------------------------------------------
  $(get-date -format u)
  -------------------------------------------------------------------------------------------

"@


    Write-Host
    Write-Host -foregroundcolor $COLOR_BRIGHT $NMAgentHeader

    $SsnStartTime = get-date

    switch -case ($cmd.ToLower()) {
      $CMD_EXEC {
        if ( $EnableGlobalPreSessionHooks  ) { . RunHooks $HookTarget_IsSession $HookScope_IsGlobal  $HookTrigger_IsBefore }
        if ( $EnableLibraryPreSessionHooks ) { . RunHooks $HookTarget_IsSession $HookScope_IsLibrary $HookTrigger_IsBefore }

        switch -case ($src.ToLower()) {
          $TARGET_DB {
            . Start-NMAScanFromDb
          }

          $TARGET_FILE {
            . Start-NMAScanFromFile $TargetObject.ToLower()
          }

          $TARGET_HOST {
            . Start-NMAScanHost $TargetObject.ToLower()
          }

          $TARGET_NETWORK {
            . Start-NMAScanNetwork $TargetObject.ToLower()
          }

          $TARGET_SESSION {
            . Start-NMAScanFromSession
          }
        }

        if ( $EnableGlobalPostSessionHooks  ) { . RunHooks $HookTarget_IsSession $HookScope_IsGlobal  $HookTrigger_IsAfter }
        if ( $EnableLibraryPostSessionHooks ) { . RunHooks $HookTarget_IsSession $HookScope_IsLibrary $HookTrigger_IsAfter }
      }

      $CMD_QUERY {
        if ( ( $store -ne $null ) -and ( $store -ne "" ) -and ( $store.Length -ne 0 ) ) {
          if ( Test-NMAOfflineStore $store ) {
            Write-Host
            Write-Host -foregroundcolor $COLOR_NORMAL  "  + Selected Archived Contents: " -noNewLine
            Write-Host -foregroundcolor $COLOR_BRIGHT  "Session [$( $TargetObject.ToLower() )] @ Off-Line Store [$store]"
            Write-Host

            $OriginalColor                   = $host.UI.RawUI.ForegroundColor
            $host.UI.RawUI.ForegroundColor   = $COLOR_RESULT

            switch -case ( $view.ToLower() ) {
              $VIEW_SIMPLE {
                Get-NMAOfflineSessionItems $store $TargetObject.ToLower() | Format-Table RecordDate, NodeName, NodePropertyName, NodeAttributeName, NodeValue, NodeExtendedAttributes -autosize -groupby SessionId
              }

              $VIEW_ERRORS {
                Get-NMAOfflineSessionItems $store $TargetObject.ToLower() | Format-Table RecordDate, NodeName, NodePropertyName, NodeAttributeName, ErrorFound, ErrorText -autosize -groupby SessionId
              }

              $VIEW_MEMO   {
                Get-NMAOfflineSessionItems $store $TargetObject.ToLower() | Format-List RecordDate, NodeName, NodePropertyName, NodeAttributeName, NodeExtendedAttributes, NodeValue_Memo -groupby SessionId
              }

              $VIEW_RAW    {
                Get-NMAOfflineSessionItems $store $TargetObject.ToLower() | Format-List RecordDate, NodeName, NodePropertyName, NodeAttributeName, NodeExtendedAttributes, NodeQueryOutput -groupby SessionId
              }

              $VIEW_AGENTS {
                Get-NMAOfflineSessionItems $store $TargetObject.ToLower() | Format-Table RecordDate, AgentNodeName, NodeName, NodePropertyName, NodeAttributeName, NodeValue -autosize -groupby SessionId
              }

              $VIEW_USERS  {
                Get-NMAOfflineSessionItems $store $TargetObject.ToLower() | Format-Table RecordDate, AgentUserName, NodeName, NodePropertyName, NodeAttributeName, NodeValue -autosize -groupby SessionId
              }
            }


            $host.UI.RawUI.ForegroundColor   = $OriginalColor
          }
        } else {
          Write-Host
          Write-Host -foregroundcolor $COLOR_NORMAL  "  + Selected Session Contents: "
          Write-Host

          $OriginalColor                   = $host.UI.RawUI.ForegroundColor
          $host.UI.RawUI.ForegroundColor   = $COLOR_RESULT

          Get-NMASessionItems $TargetObject.ToLower() $filter $view

          $host.UI.RawUI.ForegroundColor   = $OriginalColor
        }
      }

      $CMD_EXPORT {
        $DisableFormatOutput = $true
        Export-NMASession $TargetObject.ToLower() $filter
      }

      $CMD_COMPARE {
        Compare-NMASession $TargetObject.ToLower()
      }

      $CMD_ANALYZE {
        Analyze-NMASession $TargetObject.ToLower()
      }

      $CMD_UPDATE {
        Update-NMASession $TargetObject.ToLower() $filter
      }

      $CMD_LIST {
        if ( ( $store -ne $null ) -and ( $store -ne "" ) -and ( $store.Length -ne 0 ) ) {
          Write-Host
          Write-Host -foregroundcolor $COLOR_NORMAL  "  + Off-Line Session Stores:"
          Write-Host

          $OriginalColor                   = $host.UI.RawUI.ForegroundColor
          $host.UI.RawUI.ForegroundColor   = $COLOR_RESULT

          Get-NMAOfflineStores | Format-Table

          $host.UI.RawUI.ForegroundColor   = $OriginalColor

          if ( Test-NMAOfflineStore $store ) {
            Write-Host -foregroundcolor $COLOR_NORMAL  "  + Archived Sessions in the Off-Line Store: " -noNewLine
            Write-Host -foregroundcolor $COLOR_BRIGHT  $store
            Write-Host

            $OriginalColor                 = $host.UI.RawUI.ForegroundColor
            $host.UI.RawUI.ForegroundColor = $COLOR_RESULT

            Get-NMAOfflineSessionItems $store $TargetObject.ToLower() | Select-Object SessionId -unique | Format-Table

            $host.UI.RawUI.ForegroundColor = $OriginalColor
          }
        } else {
          Write-Host
          Write-Host -foregroundcolor $COLOR_NORMAL  "  + Selected Sessions: "
          Write-Host

          $OriginalColor                 = $host.UI.RawUI.ForegroundColor
          $host.UI.RawUI.ForegroundColor = $COLOR_RESULT

          Get-NMASession $TargetObject.ToLower() | Format-Table

          $host.UI.RawUI.ForegroundColor = $OriginalColor
        }

      }

      $CMD_PURGE {
        if ( ( $store -ne $null ) -and ( $store -ne "" ) -and ( $store.Length -ne 0 ) ) {
          if ( Test-NMAOfflineStore $store ) {
            if ( $TargetObject.ToLower() -eq $TARGET_SESSION_ALL ) {
              Write-Host
              Write-Host -foregroundcolor $COLOR_NORMAL  "  + Removing Off-Line Store:      " -noNewLine
              Write-Host -foregroundcolor $COLOR_BRIGHT  $store

              Remove-NMAOfflineStore $store

              if ( Test-NMAOfflineStore $store ) {
                Write-Host -foregroundcolor $COLOR_DARK   "    + Remove Operation...         " -noNewLine
                Write-Host -foregroundcolor $COLOR_ERROR  "FAILED!"
                Write-Host
              } else {
                Write-Host -foregroundcolor $COLOR_DARK   "    + Remove Operation...         " -noNewLine
                Write-Host -foregroundcolor $COLOR_RESULT "done"
                Write-Host
              }
            } else {
              if ( Test-NMAOfflineSession $store $TargetObject.ToLower() ) {
                $TargetSession = $(Get-NMAOfflineSessionItems $store $TargetObject.ToLower() | Select-Object SessionId -unique).SessionId

                Write-Host
                Write-Host -foregroundcolor $COLOR_NORMAL  "  + Removing Archived Contents:   " -noNewLine
                Write-Host -foregroundcolor $COLOR_BRIGHT  "Session [$TargetSession] @ Off-Line Store [$store]"

                Remove-NMAOfflineSession $store $TargetSession

                if ( Test-NMAOfflineSession $store $TargetSession ) {
                  Write-Host -foregroundcolor $COLOR_DARK   "    + Remove Operation...         " -noNewLine
                  Write-Host -foregroundcolor $COLOR_ERROR  "FAILED!"
                  Write-Host
                } else {
                  Write-Host -foregroundcolor $COLOR_DARK   "    + Remove Operation...         " -noNewLine
                  Write-Host -foregroundcolor $COLOR_RESULT "done"
                  Write-Host
                }
              } else {
                Write-Host
                Write-Host -foregroundcolor $COLOR_ERROR "  + Session Clean up Aborted: the specified Session could not be found"
                Write-Host
              }
            }
          }
        } else {
          if ( Test-NMASession $TargetObject.ToLower() ) {
            Remove-NMASession $TargetObject.ToLower() $filter
          } else {
            Write-Host
            Write-Host -foregroundcolor $COLOR_ERROR "  + Session Clean up Aborted: the specified Session could not be found"
            Write-Host
          }
        }
      }

      $CMD_ARCHIVE {
        Write-Host
        Write-Host -foregroundcolor $COLOR_NORMAL  "  + Selected Sessions:"
        Write-Host

        $OriginalColor                 = $host.UI.RawUI.ForegroundColor
        $host.UI.RawUI.ForegroundColor = $COLOR_RESULT

        Get-NMASession $TargetObject.ToLower() | Format-Table

        $host.UI.RawUI.ForegroundColor = $OriginalColor

        Write-Host
        Write-Host -foregroundcolor $COLOR_NORMAL  "  + Archiving Sessions...         " -noNewLine

        Reset-NMASessionStore $TargetObject.ToLower()
        Backup-NMASession $store

        Write-Host -foregroundcolor $COLOR_RESULT  "done"
        Write-Host

        $ClearOriginalSession = $STATUS_NO
        $ClearOriginalSession = Read-Host "  + Would you like to clear the Original Session? [Y/N]"
        Write-Host

        if ( $ClearOriginalSession.ToUpper() -eq $STATUS_YES ) {
          Remove-NMASession $TargetObject.ToLower() $filter
        }
      }

      $CMD_RELOAD {
        Write-Host
        Write-Host -foregroundcolor $COLOR_NORMAL  "  + Selected Sessions:"
        Write-Host

        $OriginalColor                 = $host.UI.RawUI.ForegroundColor
        $host.UI.RawUI.ForegroundColor = $COLOR_RESULT

        Get-NMAOfflineSessionItems $store $TargetObject.ToLower() | Select-Object SessionId -unique | Format-Table

        $host.UI.RawUI.ForegroundColor = $OriginalColor

        Write-Host -foregroundcolor $COLOR_NORMAL  "  + Reloading Sessions...         " -noNewLine

        Restore-NMASession $store $TargetObject.ToLower()

        Write-Host -foregroundcolor $COLOR_RESULT  "done"
        Write-Host

        $ClearOriginalSession = $STATUS_NO
        $ClearOriginalSession = Read-Host "  + Would you like to clear the Original Offline Session? [Y/N]"
        Write-Host

        if ( $ClearOriginalSession.ToUpper() -eq $STATUS_YES ) {
          if ( Test-NMAOfflineStore $store ) {
            if ( $TargetObject.ToLower() -eq $TARGET_SESSION_ALL ) {
              Write-Host
              Write-Host -foregroundcolor $COLOR_NORMAL  "  + Removing Off-Line Store:      " -noNewLine
              Write-Host -foregroundcolor $COLOR_BRIGHT  $store

              Remove-NMAOfflineStore $store

              if ( Test-NMAOfflineStore $store ) {
                Write-Host -foregroundcolor $COLOR_DARK   "    + Remove Operation:           " -noNewLine
                Write-Host -foregroundcolor $COLOR_ERROR  "FAILED!"
                Write-Host
              } else {
                Write-Host -foregroundcolor $COLOR_DARK   "    + Remove Operation:           " -noNewLine
                Write-Host -foregroundcolor $COLOR_RESULT "SUCCESS!"
                Write-Host
              }
            } else {
              if ( Test-NMAOfflineSession $store $TargetObject.ToLower() ) {
                $TargetSession = $(Get-NMAOfflineSessionItems $store $TargetObject.ToLower() | Select-Object SessionId -unique).SessionId

                Write-Host
                Write-Host -foregroundcolor $COLOR_NORMAL  "  + Removing Archived Contents:   " -noNewLine
                Write-Host -foregroundcolor $COLOR_BRIGHT  "Session [$TargetSession] @ Off-Line Store [$store]"

                Remove-NMAOfflineSession $store $TargetSession

                if ( Test-NMAOfflineSession $store $TargetSession ) {
                  Write-Host -foregroundcolor $COLOR_DARK   "    + Remove Operation:           " -noNewLine
                  Write-Host -foregroundcolor $COLOR_ERROR  "FAILED!"
                  Write-Host
                } else {
                  Write-Host -foregroundcolor $COLOR_DARK   "    + Remove Operation:           " -noNewLine
                  Write-Host -foregroundcolor $COLOR_RESULT "SUCCESS!"
                  Write-Host
                }
              } else {
                Write-Host
                Write-Host -foregroundcolor $COLOR_ERROR "  + Session Clean up Aborted: the specified Session could not be found"
                Write-Host
              }
            }
          }
        }
      }

      $CMD_SHELL {
        $DisableFormatOutput = $true

        if ( !$LoadShellOnCurrentContext ) {
          $OriginalPrompt = Get-Content function:prompt

          function prompt() {
            $(
              Write-Host -foregroundcolor $COLOR_DARK "  >> $( Get-Location )"
              Write-Host -foregroundcolor $COLOR_BRIGHT -noNewLine "  >> NMAgent [$NestedPromptLevel]"
            ) + " # "
          }

          Write-Host
          $host.EnterNestedPrompt()

          . Invoke-Expression "function prompt() { $OriginalPrompt }"
        }
      }
    }

    Write-Host
    Write-Host -foregroundcolor $COLOR_BRIGHT "  # Session Elapsed Time:        " $($(Get-Date) - $SsnStartTime)

    Write-Host -foregroundcolor $COLOR_BRIGHT $NMAgentFooter
  }

  . Start-NMASession

  $NMAgentDb.Close()
}