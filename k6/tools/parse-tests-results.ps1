param(
    $resultsPath = "${HOME}\projects",
    $resultsFile = "04_15_2021_22-03_results.csv",
	$outputFile = "k7_jmeter.csv",
    $dryRun = $false
)

Function Reset-File($resultsPath, $convertedFileName)
{
    $header = "timeStamp,elapsed,label,responseCode,responseMessage,threadName,dataType,success,failureMessage,bytes,sentBytes,grpThreads,allThreads,URL,Latency,IdleTime,Connect"
    if (Test-Path "$resultsPath\$convertedFileName")
    {
        Remove-Item "$resultsPath\$convertedFileName"
    }
    New-Item -Path "$resultsPath" -Name $convertedFileName -ItemType "file"
    Add-Content -Path "$resultsPath\$convertedFileName" -Value $header

}
Function ConvertToJmeterRow($row){
	$r=$row.split(',')
	$timeStamp=$r[1] -as [int]
    $timeStamp = $timeStamp * 1000
	$elapsed=[Math]::Floor([decimal]($r[2])) #round to integer ms
	$URL=$r[16]
	$responseCode=$r[13] -as [int]
	$errorCode=$r[4];
	$error="$r[3] - $URL";
	$responseMessage='success'
	$success='true'

	if($r[0] -eq 'http_req_duration')
	{
		$label = $r[9]
	}elseif($r[0] -eq 'group_duration'){
		$label = $r[7]
	}elseif($r[0] -eq 'TotalTime'){
		$label = $r[0]
		$elapsed=[Math]::Floor([decimal]($r[2]))
	}

	If( ($responseCode -as [int]) -gt 400){
		$responseMessage=if($errorCode) { $errorCode } else {'error'};
		$success='false'
	}
	$jmeter_row = "$timeStamp,$elapsed,$label,$responseCode,$responseMessage,threadName,dataType,$success,$error,bytes,sentBytes,grpThreads,allThreads,$URL,Latency,IdleTime,Connect"
	return $jmeter_row
}
Function ConvertJSONstoJMeterCSV($resultsPath, $resultsFile, $outputFile)
{
    Reset-File -resultsPath $resultsPath -convertedFileName $outputFile
 	  Get-Content "$resultsPath\$resultsFile" | ForEach-Object {
		if($_ -match "(http_req_duration|group_duration|TotalTime),.*"){
			$row = convertToJmeterRow -row $_;
			Add-Content -Path "$resultsPath\$outputFile" -Value $row
		}
	}
}

if (-Not $dryRun)
{
    ConvertJSONstoJmeterCSV -resultsPath $resultsPath -resultsFile $resultsFile -outputFile $outputFile
}
else
{
    Write-Host "Dry-run"
}
