class ThirdPartyUpdater {

    [string] $CsvPath
    [System.Collections.Generic.List[Object]] $Rows
    $Logger

    ThirdPartyUpdater([string] $csvPath, $logger) {
        if (-not (Test-Path $csvPath)) {
            throw "CSV file not found: $csvPath"
        }

        $this.CsvPath = $csvPath
        $this.Logger = $logger

        # Load CSV rows
        $this.Rows = [System.Collections.Generic.List[Object]] (Import-Csv $csvPath)
        $this.Logger.Info("Loaded CSV with $($this.Rows.Count) rows", "ThirdPartyUpdater")
    }

    [bool] IsThirdParty([string] $mxRecord) {
        if (-not $mxRecord) { return $false }

        $keywords = @("google", "outlook", "yahoo")
        foreach ($keyword in $keywords) {
            if ($mxRecord.ToLower() -like "*$keyword*") {
                return $true
            }
        }
        return $false
    }

    [void] UpdateCsv() {
        $this.Logger.Info("Starting ThirdParty update for CSV: $($this.CsvPath)", "ThirdPartyUpdater")

        foreach ($row in $this.Rows) {
            # Ensure ThirdParty column exists
            $row | Add-Member -MemberType NoteProperty -Name ThirdParty -Value $false -Force

            # Determine if MX record belongs to a third-party
            $row.ThirdParty = $this.IsThirdParty($row.MxRecord)
        }

        # Save CSV
        $this.Rows | Export-Csv -Path $this.CsvPath -NoTypeInformation -Force
        $this.Logger.Info("ThirdParty update complete: $($this.CsvPath)", "ThirdPartyUpdater")
    }
}
