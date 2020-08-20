# BFModules ::= {IsEnabled, 'ServiceTag', 'ModuleName'}

$script:BFModules = @{
  BF_SSH                              = $false, 'System', 'BF_SSH';
  BF_Windows                          = $false, 'System', 'BF_Windows'
}