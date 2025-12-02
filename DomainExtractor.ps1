. "$PSScriptRoot\logger.ps1"
class DomainExtractor {

    [object]$Logger
    [string]$OutputFile
    [string]$InputFile

    DomainExtractor([object]$logger, [string]$outputFile,[string]$inputFile) {
        $this.Logger     = $logger
        $this.OutputFile = $outputFile
        $this.InputFile = $inputFile
    }

        DomainExtractor([object]$logger, [string]$outputFile) {
        $this.Logger     = $logger
        $this.OutputFile = $outputFile
        
    }

    [System.Collections.ArrayList] GetUniqueDomainsFromCsv([string]$CsvPath) {

        $this.Logger.Info("CSV update started","extractdomain")

        if (-not (Test-Path $CsvPath)) {
            $this.Logger.Error("CSV file not found: $CsvPath","extractdomain")
            return [System.Collections.ArrayList]::new()
        }

        $rows = Import-Csv -Path $CsvPath

        $this.Logger.Info("Iterating rows","extractdomain")

        $domains = New-Object System.Collections.ArrayList

        foreach ($row in $rows) {

            $value = $row.DomainName

            # fallback to Alias
            if (-not $value) { 
                $value = $row.Alias
            }

            if (-not $value) { continue }

            if ($value -match "@") {
                $domain = ($value -split "@")[-1]
                $this.Logger.Info("Extracted domain from email: $value","extractdomain")
                $domains.Add($domain) | Out-Null
            }
            else {
                $this.Logger.Info("Value is domain already: $value","extractdomain")
                $domains.Add($value) | Out-Null
            }
        }

        # Remove duplicates
        $uniqueDomains = $domains | Sort-Object -Unique

        $this.Logger.Info("Unique domain count: $($uniqueDomains.Count)","extractdomain")

        $uniqueDomains | ForEach-Object { 
            [PSCustomObject]@{ Domain = $_ }
        } | Export-Csv -Path $this.OutputFile -NoTypeInformation

        return $uniqueDomains
    }
}
