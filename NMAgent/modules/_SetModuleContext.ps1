[string] $AttributeName = ""


# old strategy: $MyInvocation.MyCommand.Name
[string[]] $CurrentContext    = $MyInvocation.ScriptName.Split("\")
[string]   $CurrentContext    = $CurrentContext[$( $CurrentContext.Count - 1 )]

switch -regex ( $CurrentContext ) {
  "RunWinCmd(?!_PsInfo)" {
    $RemoteSystemDir          = GetSystemDir
    $RemoteSystemRoot         = GetSystemRoot
  }
}


if ( $EnableGlobalPreMContextHooks  ) { . RunHooks $HookTarget_IsMContext $HookScope_IsGlobal  $HookTrigger_IsBefore }
if ( $EnableLibraryPreMContextHooks ) { . RunHooks $HookTarget_IsMContext $HookScope_IsLibrary $HookTrigger_IsBefore }