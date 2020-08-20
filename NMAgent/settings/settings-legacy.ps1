$script:NodeIdCollisionOffSet         = 1000000
$script:NewNodeTemplateId             = 34
$script:SystemServiceTag              = 'System'

$script:AgentUserId                   = 45              # default: 45 (NMAgent OpenSLIM Contact UserId)
$script:AgentUserName                 = 'NMAgent'       # default: 'NMAgent' (No blank spaces!)
$script:AgentUserSessionStore         = '_SessionStore' # default: '_SessionStore'


$script:NMAgentDbType                 = "ms-sql-server" # "<ms-access|ms-sql-server>"

$script:NMAgentDbServer               = ""
$script:NMAgentDbName                 = "NMAgent"
$script:NMAgentDbUserName             = ""
$script:NMAgentDbPassword             = ""

$script:OpenSLIMDbServer              = ""
$script:OpenSLIMDbName                = "OpenSLIM-current"
$script:OpenSLIMDbUserName            = ""
$script:OpenSLIMDbPassword            = ""

$script:NetworkUserId                 = "Administrator"


$script:OpenSLIMDbBasicFilter         = "NodeIsDeleted = 'False' AND NodeIsActive = 'True'"

# All Nodes except: Consoles, Cluster Resources, Deleted/Decomissioned, Broken/Inactive for some reason.
$script:OpenSLIMDbUserFilter          = "NodeTypeId NOT IN (1,2,12,13,11,15) AND SystemTypeId IN (3,4)"
# All Nodes except: Unix, NT 4.0, Consoles, Cluster Resources, Deleted/Decomissioned, Broken/Inactive for some reason.
# $script:OpenSLIMDbUserFilter          = "NodeTypeId NOT IN (1,2,12,13,11,15) AND SystemTypeId NOT IN (3,7,8,9,10,11,12,13,14,15,23,24,25)"


$script:LoadShellOnCurrentContext     = $false
$script:StatsDisplayFrequency         = 10

$script:MultiCredentialMode           = $false
$script:CredentialsDbIsEncrypted      = $false

$script:BruteForceLoginMode           = $true
$script:SaveBFLoginResults            = $false
$script:PerHostBFLogin                = $true
$script:PerModuleBFLogin              = $false
$script:EnableBFLoginExtensions       = $false

$script:MergeInputFiles               = $false
$script:MergeCredentialsFiles         = $true


# [string[]] $script:ModulesLibraries   = "Library1", "Library2", "Library3", ...
[string[]] $script:ModulesLibraries   = "openslim", "storage"


$script:EnableGlobalPreSessionHooks    = $true
$script:EnableGlobalPostSessionHooks   = $true
$script:EnableGlobalPreNodeHooks       = $true
$script:EnableGlobalPostNodeHooks      = $true
$script:EnableGlobalPreModuleHooks     = $true
$script:EnableGlobalPostModuleHooks    = $true
$script:EnableGlobalPreMContextHooks   = $true
$script:EnableGlobalPostMContextHooks  = $true

$script:EnableLibraryPreSessionHooks   = $true
$script:EnableLibraryPostSessionHooks  = $true
$script:EnableLibraryPreNodeHooks      = $true
$script:EnableLibraryPostNodeHooks     = $true
$script:EnableLibraryPreModuleHooks    = $true
$script:EnableLibraryPostModuleHooks   = $true
$script:EnableLibraryPreMContextHooks  = $true
$script:EnableLibraryPostMContextHooks = $true