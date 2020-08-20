$services                   = Get-Content .\services.txt
$services                   = $services | Select-String "OK"

[string[]] $ServiceNameList = @()

$services | ForEach-Object {
  if ( $_ -match '\s+(?<ExitCode>\d+)\s+(?<ServiceName>\w+)\s+(?<Pid>\d+)\s+(?<StartMode>\w+)\s+(?<State>\w+)\s+(?<Status>\w+)' )  {
    $ServiceNameList += $Matches.ServiceName
  }
}

$ServiceNameList | Select-Object $_ -unique >> .\unique-services.txt