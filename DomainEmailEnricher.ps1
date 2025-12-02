. "$PSScriptRoot\logger.ps1"
class DomainEmailEnricher {

    [object]$Logger
    [string]$DomainFile
    [string]$AliasFile

    DomainEmailEnricher([object]$logger, [string]$domainFile, [string]$aliasFile) {
        $this.Logger     = $logger
        $this.DomainFile = $domainFile
        $this.AliasFile  = $aliasFile
    }

    [void] ProcessFiles() {

        $this.Logger.Info("CSV update started","extractdomain")
        # Validate domain CSV
        if (-not (Test-Path $this.DomainFile)) {
            $this.Logger.Error("Domain CSV not found: $($this.DomainFile)", "DomainEmailEnricher")
            return
        }

        # Validate alias CSV
        if (-not (Test-Path $this.AliasFile)) {
            $this.Logger.Error("Alias CSV not found: $($this.AliasFile)", "DomainEmailEnricher")
            return
        }

        $this.Logger.Info("Loading domain file: $($this.DomainFile)", "DomainEmailEnricher")
        $domains = Import-Csv -Path $this.DomainFile

        $this.Logger.Info("Loading alias file: $($this.AliasFile)", "DomainEmailEnricher")
        $aliases = Import-Csv -Path $this.AliasFile

        #
        # Remove duplicate aliases
        #
        $this.Logger.Info("Removing duplicate aliases", "DomainEmailEnricher")
        $aliases = $aliases | Sort-Object Alias -Unique

        #
        # Build lookup table of Domain -> Emails
        #
        $domainEmailMap = @{}

        foreach ($a in $aliases) {
            if (-not $a.Alias) { continue }

            # Extract domain from email
            $parts = $a.Alias -split "@"
            if ($parts.Count -ne 2) { continue }

            $domain = $parts[1]

            if (-not $domainEmailMap.ContainsKey($domain)) {
                $domainEmailMap[$domain] = New-Object System.Collections.Generic.List[string]
            }

            $domainEmailMap[$domain].Add($a.Alias)
        }

        #
        # Add Email column to domain CSV if missing
        #
        foreach ($row in $domains) {
            if (-not $row.PSObject.Properties.Match("Email")) {
                Add-Member -InputObject $row -MemberType NoteProperty -Name Email -Value ""
            }
        }

        #
        # Match domain rows to alias list
        #
        foreach ($row in $domains) {
            $domainName = $row.DomainName

            if ($domainEmailMap.ContainsKey($domainName)) {
                $emails = $domainEmailMap[$domainName] -join ","
                  $row | Add-Member -NotePropertyName 'Email' -NotePropertyValue '' -Force
                $row.Email = $emails

                $this.Logger.Info("Matched $domainName to emails: $emails", "DomainEmailEnricher")
            } else {
                 $row | Add-Member -NotePropertyName 'Email' -NotePropertyValue '' -Force
                $row.Email = "No matched emails"
                $this.Logger.Info("No emails matched for $domainName", "DomainEmailEnricher")
            }
        }

        #
        # Write file back out
        #
        $this.Logger.Info("Writing updated domain CSV to $($this.DomainFile)", "DomainEmailEnricher")
        $domains | Export-Csv -Path $this.DomainFile -NoTypeInformation
    }
}
