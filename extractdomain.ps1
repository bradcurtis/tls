. "$PSScriptRoot\logger.ps1"


# Initialize logger
$logger = [LoggerSingleton]::GetLogger("./tls.log","ERROR")
$logger.Info("CSV update started","extractdomain")

function Get-UniqueDomainsFromCsv {
    param(
        [Parameter(Mandatory)]
        [string]$CsvPath
    )

    if (-not (Test-Path $CsvPath)) {
        
        $logger.Error("CSV file not found: $CsvPath","extractdomain")
        return
    }

    # Import the CSV
    $rows = Import-Csv -Path $CsvPath

    $logger.Info("Iterate rows","extractdomain")

    $domains = foreach ($row in $rows) {

        $value = $row.DomainName   # <-- column name in your CSV

        if (-not $value) { 
            continue 
        }

        # If it's an email address, extract only the domain
        if ($value -match "@") {
            $value -split "@" | Select-Object -Last 1
        }
        else {
            $value
        }
    }

    # Remove duplicates
    $uniqueDomains = $domains | Sort-Object -Unique

    # Define the output CSV path
    $csvPathUnique = ".\uniqueDomains.csv"

# Convert the array of strings into objects so Export-Csv works properly
# incase we we stuck
    $uniqueDomains | ForEach-Object { [PSCustomObject]@{ Domain = $_ } } |
    Export-Csv -Path $csvPathUnique -NoTypeInformation

    return $uniqueDomains
}


