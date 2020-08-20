[string] $ActiveModules += $LibraryModulesKeys | Where-Object { $LibraryModules.$_[$NMAModules_IsEnabled] }

if ( $ActiveModules.Contains("RunPsCmd") ) {
  Remove-PSSession $TargetSession
}