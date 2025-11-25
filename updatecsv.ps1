. "$PSScriptRoot\logger.ps1"


# Initialize logger
$logger = [LoggerSingleton]::GetLogger("./tls.log","ERROR")
$logger.Info("CSV update started","updatecsv")

function Add-DomainTlsRecord {
    param(
        [Parameter(Mandatory)]
        [string]$CsvPath,

        [Parameter(Mandatory)]
        [string]$DomainName,

        [Parameter(Mandatory)]
        [bool]$Tls
    )

    # If file does not exist, create it with headers
    if (-not (Test-Path $CsvPath)) {
       
        $logger.Info("CSV not found creating new file at $CsvPath","updatecsv")

        $header = [PSCustomObject]@{
            DomainName = $DomainName
            Tls        = $Tls
        }

        # Create CSV with first row
        $header | Export-Csv -Path $CsvPath -NoTypeInformation
        return
    }

    # CSV exists → append new row
    $newRow = [PSCustomObject]@{
        DomainName = $DomainName
        Tls        = $Tls
    }

    $newRow | Export-Csv -Path $CsvPath -NoTypeInformation -Append
}
