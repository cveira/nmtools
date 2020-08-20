$ClearTextUserName = GetClearTextUserName $NetworkCredentials
$ClearTextPassword = GetClearTextPassword $NetworkCredentials

Connect-VIServer -server $TargetNode -username $ClearTextUserName -password $ClearTextPassword | Out-Null