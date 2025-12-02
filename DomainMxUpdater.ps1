# DomainMxUpdater.ps1
class DomainMxUpdater {

    [string] $CsvPath
    [System.Collections.Generic.List[Object]] $Rows
    $Logger

    DomainMxUpdater([string] $csvPath, $logger) {
        if (-not (Test-Path $csvPath)) {
            throw "CSV file not found: $csvPath"
        }

        $this.CsvPath = $csvPath
        $this.Logger = $logger

        # Load CSV rows
        $this.Rows = [System.Collections.Generic.List[Object]] (Import-Csv $csvPath)
        $this.Logger.Info("Loaded CSV with $($this.Rows.Count) rows", "DomainMxUpdater")
    }

    [string] LookupMx([string] $domain) {
        $mxRecords = @()

        # Try Resolve-DnsName with public DNS
        try {
            $mxRecords = Resolve-DnsName -Name $domain -Type MX -Server 8.8.8.8 -ErrorAction Stop |
                         Select-Object -ExpandProperty MailExchange
        }
        catch {
            $this.Logger.Warn("Resolve-DnsName failed for $domain. Will try nslookup.", "DomainMxUpdater")
        }

        # Fallback to nslookup if Resolve-DnsName returned nothing
        if ($mxRecords.Count -eq 0) {
            try {
                $nslookupOutput = nslookup -type=mx $domain 2>$null
                $mxRecords = $nslookupOutput |
                    Where-Object { $_ -match "mail exchanger" } |
                    ForEach-Object {
                        ($_ -split " = ")[-1].Trim()
                    }
            }
            catch {
                $this.Logger.Warn("nslookup also failed for $domain", "DomainMxUpdater")
            }
        }

        # Determine result
        if ($mxRecords.Count -eq 0) {
            $this.Logger.Warn("No MX record found for $domain", "DomainMxUpdater")
            return "NO_MX_RECORD"
        } else {
            $mxStr = ($mxRecords -join "; ")
            $this.Logger.Info("MX record for $domain : $mxStr", "DomainMxUpdater")
            return $mxStr
        }
    }

    [void] UpdateCsv() {
        $this.Logger.Info("Starting MX updates for CSV: $($this.CsvPath)", "DomainMxUpdater")

        foreach ($row in $this.Rows) {
            $domain = $row.DomainName

            # Ensure MxRecord exists
            $row | Add-Member -MemberType NoteProperty -Name MxRecord -Value "" -Force

            # Set MX record
            $row.MxRecord = $this.LookupMx($domain)
        }

        # Overwrite CSV
        $this.Rows | Export-Csv -Path $this.CsvPath -NoTypeInformation -Force
        $this.Logger.Info("CSV update complete: $($this.CsvPath)", "DomainMxUpdater")
    }
}
