# VMware Power-Cli Library binding

 if ( $( Get-PSSnapin | ? {$_.Name -like "*VMware*"} ) -eq $null )  {
  Add-PSSnapin -Name "VMware.VimAutomation.Core"
}
