. "$PSScriptRoot\logger.ps1"


# Initialize logger
# $logger = [LoggerSingleton]::GetLogger("./tls.log","ERROR")
 $logger = [LoggerSingleton]::GetLogger("./tls.log")



function Get-UniqueDomainsFromCsv {
    param(
        [Parameter(Mandatory)]
        [string]$CsvPath
    )
$logger.Info("CSV update started","extractdomain")

    if (-not (Test-Path $CsvPath)) {
        
        $logger.Error("CSV file not found: $CsvPath","extractdomain")
        return
    }

    # Import the CSV
    $rows = Import-Csv -Path $CsvPath

    $logger.Info("Iterate rows","extractdomain")

 
    $domains = foreach ($row in $rows) {
    $outputfile = ".\uniqueDomains.csv"
    $value = $row.DomainName

    if (-not $value) { 
        $value = $row.Alias
        $outputfile = ".\uniqueEmails.csv"
    }

    if (-not $value) {
        continue
    }

    # If it's an email address, extract the domain
    if ($value -match "@") {
        $domain = $value -split "@" | Select-Object -Last 1

        $logger.Info("split email  $value","extractdomain")

        # *** OUTPUT THE RESULT ***
        $domain
        continue
    }

    # Not an email — output as-is
    $logger.Info("no split email  $value","extractdomain")
    $value
}


    # Remove duplicates
    $uniqueDomains = $domains | Sort-Object -Unique


     $logger.Info("Number of itmes  $uniqueDomains","extractdomain")
# Convert the array of strings into objects so Export-Csv works properly
# incase we we stuck

    $uniqueDomains | ForEach-Object { [PSCustomObject]@{ Domain = $_ } } |
    Export-Csv -Path $outputfile -NoTypeInformation



    return $uniqueDomains
}


