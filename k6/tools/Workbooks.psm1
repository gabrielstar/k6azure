Import-Module $PSScriptRoot\Azure.psm1

function Convert-JmeterCSVResultsToJSON($FilePathCSV, $FilePathJSON)
{
    try
    {
        $csv = Get-Content -Path $FilePathCSV -ErrorAction Stop
        $csv = $csv | ConvertFrom-Csv | ConvertTo-Json | Out-File -Encoding UTF8 $FilePathJSON
    }
    catch [System.Management.Automation.ItemNotFoundException]
    {
        "IO Error while rading/writing file: {0},{1}" -f $FilePathCSV, $FilePathJSON
        "Terminating"
    }
}

function Read-Properties($PropertiesFilePath)
{
    $properties = ConvertFrom-StringData (Get-Content -Path $PropertiesFilePath -raw -ErrorAction Stop)
    return $properties
}
function Send-RawDataToLogAnalytics($FilePathJSON, $WorkbooksId, $SharedKey, $LogType)
{

    $body = Get-Content -Path $FilePathJSON
    $statusCode = Send-LogAnalyticsData -CustomerId $WorkbooksId `
                            -SharedKey $SharedKey `
                            -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) `
                            -logType $LogType
    return $statusCode
}

function Add-ColumnToCSV($FilePathCSV, $OutFilePathCSV, $ColumnHeader, $ColumnFieldsValue)
{
    Write-Host "$ColumnHeader -> $ColumnFieldsValue"
    Import-Csv $FilePathCSV |
            Select-Object *, @{ Name = $ColumnHeader; Expression = { "$ColumnFieldsValue" } } |
            Export-Csv "$OutFilePathCSV" -NoTypeInformation
}

function Send-DataToLogAnalytics($FilePathCSV, $FilePathJSON, $WorkbooksId, $SharedKey, $LogType)
{
    $status = 999
    try
    {
        Convert-JmeterCSVResultsToJSON -FilePathCSV $FilePathCSV -FilePathJSON $FilePathJSON
        $status = Send-RawDataToLogAnalytics `
                                            -FilePathJSON $FilePathJSON `
                                            -WorkbooksId $WorkbooksId `
                                            -SharedKey $SharedKey `
                                            -LogType $LogType
    }
    catch
    {
        Write-Host "Unexpected exception"
        Write-Host $_
        Write-Host $_.ScriptStackTrace
    }
    return $status
}


Export-ModuleMember -function *