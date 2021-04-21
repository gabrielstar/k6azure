param(
      $PropertiesPath="${HOME}\projects\workbooks.properties",
      $FilePathCSV="${HOME}\projects\",
      $OutFilePathCSV="${HOME}\projects\out_data.csv",
      $DryRun=$false,
      $JmeterArg = '-Jthreads=5 | k6 custom parameters',
      $BuildId = "$(Get-Date -Format 'yyyy_MM_dd_HH-mm-ss')",
      $BuildStatus = 'unknown',
      $PipelineId = "PC of ${env:username}",
      $ByRows=10000,
      $AzurePostLimitMB=30,
      $Slaves=1,
      $Mode='PC k6',
      $UsePropertiesFile='true',
      $WorkbooksId='',
      $SharedKey='',
      $LogType='somelogtype'
)

Import-Module $PSScriptRoot\Workbooks.psm1 -Force

function Send-JMeterDataToLogAnalytics($FilePathCSV, $WorkbooksId, $SharedKey, $LogType)
{
    $status = 999
    $filePathJSON = "$PSScriptRoot/../tmp/results.json"
    try
    {

        $status = Send-DataToLogAnalytics `
                        -FilePathCSV "$FilePathCSV" `
                        -FilePathJSON "$filePathJSON" `
                        -WorkbooksId $WorkbooksId `
                        -SharedKey $SharedKey `
                        -LogType $LogType

    }catch {
        Write-Host $_
    } finally {
        Write-Host ""
        Write-Host " - Data sent with HTTP status $status"
        Write-Host " - filePathJSON $filePathJSON"
    }
    return $status
}
function Split-File($FilePathCSV,[long]$ByRows=1000){
    $files=@() #return list of files for upload to analytics
    try
    {
        $startrow = 0;
        $counter = 1;
        Get-Content $FilePathCSV -read 1000 | % { $totalRows += $_.Length } #efficient count of lines for large file
        $totalRows -= 1; #exclude header
        Write-Host "$( $FilePathCSV | Split-Path -Leaf ) File has $totalRows lines"

        while ($startrow -lt $totalRows)
        {
            try
            {
                $partialFile = "$FilePathCSV$( $counter )"
                Write-Host "Splitting file $( $FilePathCSV | Split-Path -Leaf ) by $ByRows part $counter as $( $partialFile | Split-Path -Leaf )"
                Import-CSV $FilePathCSV | select-object -skip $startrow -first $ByRows | Export-CSV "$partialFile" -NoTypeInformation
                $startrow += $ByRows;
                $counter++;
                $files += $partialFile
            }
            catch
            {
                Write-Host $_
            }
        }
    }catch{
        Write-Host $_
    }
    return $files
}
function Add-MetaDataToCSV($FilePathCSV, $OutFilePathCSV ){
    $inputTempFile = New-TemporaryFile
    $outputTempFile = New-TemporaryFile
    Copy-Item -Path $FilePathCSV -Destination $inputTempFile
    $hash = [ordered]@{
        jmeterArgs = $JmeterArg
        slaves = $Slaves
        mode = $Mode
        buildId = $BuildId
        buildStatus = $BuildStatus
        pipelineId = $PipelineId
    }
    foreach ($h in $hash.GetEnumerator()) {
        #Write-Host "$($h.Name): $($h.Value)"
        Add-ColumnToCSV -filePathCSV $inputTempFile -outFilePathCSV $outputTempFile -columnHeader "$($h.Name)" -columnFieldsValue "$($h.Value)"
        Copy-Item -Path $outputTempFile -Destination $inputTempFile
    }
    Copy-Item $inputTempFile -Destination $OutFilePathCSV
}
function Start-Script(){
    $sourceSizeMB = ((Get-Item $FilePathCSV).length/1MB)
    "File {0} size {1:n5} Megs" -f $FilePathCSV,$sourceSizeMB | Write-Host
    Set-Variable AZURE_POST_LIMIT -option Constant -value $AzurePostLimitMB
    $files = Split-File -filePathCSV $FilePathCSV -ByRows $ByRows
    foreach($file in $files)
    {
        $OutFilePathCSV = "${file}_out"
        Add-MetaDataToCSV -filePathCSV $file -outFilePathCSV $OutFilePathCSV
        $sizeMB = ((Get-Item $OutFilePathCSV).length/1MB)
        "Output file {0} has {1:n5} Megs" -f $OutFilePathCSV, $sizeMB | Write-Host
        if ($sizeMB -gt $AZURE_POST_LIMIT)
        {
            Write-Error "File $( $OutFilePathCSV | Split-Path -Leaf ) size exceeds limit of $AZURE_POST_LIMIT Megs: $sizeMB Megs" -ErrorAction Stop
        }
        if (-Not $DryRun)
        {
            "Uploading file with size {0:n5} MB" -f $sizeMB | Write-Host
            if($UsePropertiesFile -eq "true")
            {
                $properties = Read-Properties -propertiesFilePath $PropertiesPath
                Write-Host "Using properties file $PropertiesPath for the upload"
                $status = Send-JMeterDataToLogAnalytics `
                            -filePathCSV "$OutFilePathCSV" `
                            -WorkbooksId $properties."workbooks.workbooksID" `
                            -SharedKey $properties."workbooks.sharedKey" `
                            -LogType $properties."workbooks.logType"
            }else{
                Write-Host "Reading WorkbooksId: $WorkbooksId, SharedKey: ***** and LogType: $LogType from parameters"
                $status = Send-JMeterDataToLogAnalytics `
                            -filePathCSV "$OutFilePathCSV" `
                            -WorkbooksId $WorkbooksId `
                            -SharedKey $SharedKey `
                            -LogType $LogType
            }
        }
        else
        {
            $status = 200
            Write-Host "Data Upload Mocked"
        }
        if ("$status" -ne "200")
        {
            Write-Error "Data has not been uploaded $status" -ErrorAction Stop
        }
    }
}
Write-Host "Uplaoding results to workbooks"
Start-Script
