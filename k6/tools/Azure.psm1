# Create the function to create the authorization signature
function New-Signature ($CustomerId, $SharedKey, $Date, $ContentLength, $Method, $ContentType, $Resource)
{
    $xHeaders = "x-ms-date:" + $Date
    $stringToHash = $Method + "`n" + $ContentLength + "`n" + $ContentType + "`n" + $xHeaders + "`n" + $Resource

    $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $keyBytes = [Convert]::FromBase64String($SharedKey)

    $sha256 = New-Object System.Security.Cryptography.HMACSHA256
    $sha256.Key = $keyBytes
    $calculatedHash = $sha256.ComputeHash($bytesToHash)
    $encodedHash = [Convert]::ToBase64String($calculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $CustomerId,$encodedHash
    return $authorization
}
# Create the function to create and post the request
function Send-LogAnalyticsData($CustomerId, $SharedKey, $Body, $LogType)
{
    $method = "POST"
    $contentType = "application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString("r")
    $contentLength = $Body.Length
    $signature = New-Signature `
        -CustomerId $CustomerId `
        -SharedKey $SharedKey `
        -Date $rfc1123date `
        -ContentLength $contentLength `
        -Method $method `
        -ContentType $contentType `
        -Resource $resource
    $uri = "https://" + $CustomerId + ".ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"

    $headers = @{
        "Authorization" = $signature;
        "Log-Type" = $LogType;
        "x-ms-date" = $rfc1123date;
        #"time-generated-field" = $TimeStampField;
    }
   
    $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $Body -UseBasicParsing
    return $response.StatusCode

}

Export-ModuleMember -function *