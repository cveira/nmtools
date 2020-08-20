Write-Host

SaveNodeData $NodeName $NodeIP $PropertyName $AttributeName $ExtendedAttributes $IsSupported $ErrorFound $ErrorText $IsString $ResultValue $RawOutput


if ( $EnableGlobalPostMContextHooks  ) { RunHooks $HookTarget_IsMContext $HookScope_IsGlobal  $HookTrigger_IsAfter }
if ( $EnableLibraryPostMContextHooks ) { RunHooks $HookTarget_IsMContext $HookScope_IsLibrary $HookTrigger_IsAfter }