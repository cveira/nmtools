$processes                  = Get-Content .\processes.txt
$processes                  = $processes | Select-String ".exe"

[string[]] $ProcessNameList = @()
$processes | ForEach-Object {
  if ( $_ -match '\s+(?<Pid>\d+)\s+(?<Process>\w+\.exe)\s+(?<CommandLine>[\w\s\\:\.\{\}/~"]*)' ) {
    $ProcessNameList += $Matches.Process
  }
}

$ProcessNameList | Select-Object $_ -unique >> .\unique-processes.txt