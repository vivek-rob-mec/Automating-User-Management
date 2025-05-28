$logFilePath = "D:\DevOps_HandsOn\Automating User Management\users_management_log.txt"
$reportPath = "D:\DevOps_HandsOn\Automating User Management\log_report.csv"

# Reading the logs of the file as well as creating filters
function AnalyzeLogs {
    param (
        [string]$logFilePath,
        [string]$dateFilter = "",
        [string]$timeFilter = ""
    )
    
    $logEntries = Get-Content $logFilePath | Where-Object {
        if ($dateFilter -ne ""){
            $_ -match $dateFilter
        }elseif ($timeFilter -ne "") {
            $_ -match $timeFilter
        }
        else {
            $true
        }
    }

    $logSummary = @()

    foreach ($log in $logEntries){
        $date = ($log -split ' ')[0] # extract date
        $time = ($log -split ' ')[1] # extract time
        $description = ($log -split ' - ')[1] # extract message

        $logSummary += [PSCustomObject]@{
            Date = $date
            Time = $time
            Description = $description
        }
    }
    return $logSummary

}

# Generate csv report
$dateFilter = "" # You can provide the date filter here
$timeFilter = "" # You can provide the time filter here

$analysisResult = AnalyzeLogs -logFilePath $logFilePath -dateFilter $dateFilter -timeFilter $timeFilter

$analysisResult | Export-Csv -Path $reportPath -NoTypeInformation

Write-Host "Log analysis is completed. Report is generated at: $reportPath"