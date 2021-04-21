param(
  $RunTests = $true,
	$SaveResultsToWorkbooks = $false,
	$UsePropertiesFile = $true,
	$WorkbooksProperties = "${HOME}\projects\workbooks.properties",
	$WorkbooksId = '',
    $SharedKey = '',
    $LogType = 'tr',
	$ResultsFolder = "${HOME}\projects\",
	$Arguments = "-e SAMPLE_FILE=file.json -e VUS=1 -e ITERATIONS=1 -e SCENARIO=Scenario1",
	$K6_Args = '',
	$TestScript = 'script.js',
	$K6From = 'system' ,
    $BuildId = "$(Get-Date -Format 'yyyy_MM_dd_HH-mm-ss')",
    $BuildStatus = 'unknown',
    $PipelineId = "PC of ${env:username}",
	$Mode = 'local PC'
)

$date = "$(Get-Date -Format 'MM_dd_yyyy_HH_mm')";
$CSVFilename="${date}_results.csv";
$CSVFilenameAbsolutePath="${ResultsFolder}/${CSVFilename}"

#Invokes local k6 (win/linux)
Function Invoke-K6(){
	$cmd = "k6 run ${K6_Args} ${Arguments} --include-system-env-vars=false --out csv=${CSVFilenameAbsolutePath} ${TestScript}"
	Write-Host "${cmd} "
	Invoke-Expression "$cmd" 	#--http-debug
}

#Invokes docker k6 equivalent on powershell (win/linux)
Function Invoke-K6AsDocker(){
	Write-Host "docker run --rm --entrypoint /bin/sh -i -v ${PWD}:/home/k6 loadimpact/k6 -c k6 run ${K6_Args}  ${Arguments} --include-system-env-vars=false --out csv=/home/k6/out.csv ${TestScript}"
	(Get-Content -Path ${PSScriptRoot}/${TestScript}) | docker run --rm --entrypoint /bin/sh -i -v ${PWD}:/home/k6 loadimpact/k6 -c "k6 run ${K6_Args}  ${Arguments} --include-system-env-vars=false --out csv=/home/k6/out.csv ${TestScript}"
  Copy-Item out.csv ${CSVFilenameAbsolutePath}
}

#Sends parsed results to workbooks by .properties or inline creds
Function Save-ResultsToWorkbooks(){
	$JMeterFormatFileName = "jmeter_${CSVFilename}"
	$users = [regex]::Match($Arguments,'.*VUS=(\d+)').captures.groups[1].value; #extracts users from args string
	Invoke-Expression "${PSScriptRoot}\tools\parse-tests-results.ps1 -resultsFile ${CSVFilename} -resultsPath ${ResultsFolder} -outputFile ${JMeterFormatFileName}"
	If($UsePropertiesFile){ #use on local machine
		Invoke-Expression "${PSScriptRoot}\tools\upload-to-workbooks.ps1 -WorkbooksProperties ${WorkbooksProperties} -FilePathCSV ${ResultsFolder}/${JMeterFormatFileName} -JmeterArg '$Arguments -Jthreads=$users' -BuildId $BuildId -PipelineId $PipelineId -Mode $Mode -BuildStatus $BuildStatus";
	} Else { #pass as params in pipeline
		Invoke-Expression "${PSScriptRoot}\tools\upload-to-workbooks.ps1 -WorkbooksId ${WorkbooksId} -SharedKey ${SharedKey} -LogType ${LogType} -UsePropertiesFile ${UsePropertiesFile} -FilePathCSV ${ResultsFolder}/${JMeterFormatFileName} -JmeterArg '$Arguments -Jthreads=$users' -BuildId $BuildId -PipelineId $PipelineId -Mode $Mode -BuildStatus $BuildStatus";
	}
}

#Script flow
If($RunTests){
    Write-Host "Running k6 using ${K6From} installation"
	If($K6From -eq "system"){ #run from system
		Invoke-K6;
	}Elseif($K6From -eq "docker"){ #run from docker, overwrite entrypoint to pass params
		Invoke-K6AsDocker;
	}
}
If($SaveResultsToWorkbooks){
	Save-ResultsToWorkbooks;
}
