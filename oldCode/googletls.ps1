function Test-GoogleCheckMx {
    param (
        [Parameter(Mandatory)]
        [string]$Domain
    )

    # Google Admin Toolbox JSON endpoint
    $url = "https://admin.google.com/tools/checkmx/json?domain=$Domain"

    try {
        $response = Invoke-RestMethod -Uri $url -Method Get

        # Build output object
        $obj = [PSCustomObject]@{
            Domain           = $Domain
            MX               = $response.mxRecords
            SPF_Status       = $response.spf.status
            SPF_Record       = $response.spf.record
            DKIM_Status      = $response.dkim.status
            DMARC_Status     = $response.dmarc.status
            DNSSEC_Enabled   = $response.dnssec.status
            Overall_Status   = $response.summary
        }

        return $obj
    }
    catch {
        Write-Warning "Failed to query Google CheckMX for $Domain : $_"
        return $null
    }
}

# Example: test multiple domains
$domains = @(
    "google.com",
    "microsoft.com",
    "example.com",
    "gmail.com"
)

$results = foreach ($domain in $domains) {
    Write-Host "Checking $domain..." -ForegroundColor Cyan
    Test-GoogleCheckMx -Domain $domain
}

# Show results
$results | Format-List

# Optional: save to CSV
# $results | Export-Csv -Path checkmx_results.csv -NoTypeInformation