[string] $ActiveModules += $LibraryModulesKeys | Where-Object { $LibraryModules.$_[$NMAModules_IsEnabled] }

if ( $ActiveModules.Contains("RunPsCmd") ) {
  if ( $NeedCredentials ) {
    $TargetSession = New-PSSession  -computername $TargetNode -credential $NetworkCredentials
  } else {
    $TargetSession = New-PSSession  -computername $TargetNode
  }
}