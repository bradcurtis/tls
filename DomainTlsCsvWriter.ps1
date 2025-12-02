class DomainTlsCsvWriter {

    [object]$Logger

    DomainTlsCsvWriter([object]$logger) {
        $this.Logger = $logger
    }

    [void] AddRecord([string]$CsvPath, [string]$DomainName, [bool]$Tls) {

        # CSV does not exist: create it
        if (-not (Test-Path $CsvPath)) {

            $this.Logger.Info("CSV not found. Creating new file at $CsvPath","DomainTlsCsvWriter")

            $header = [PSCustomObject]@{
                DomainName = $DomainName
                Tls        = $Tls
            }

            $header | Export-Csv -Path $CsvPath -NoTypeInformation
            return
        }

        # Append new row
        $newRow = [PSCustomObject]@{
            DomainName = $DomainName
            Tls        = $Tls
        }

        $this.Logger.Info("Appending domain $DomainName TLS=$Tls","DomainTlsCsvWriter")

        $newRow | Export-Csv -Path $CsvPath -NoTypeInformation -Append
    }
}
