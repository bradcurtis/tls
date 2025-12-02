
Import-Module .\module\AppConfig.psm1 -Force

. "$PSScriptRoot\DomainExtractor.ps1"
. "$PSScriptRoot\TlsChecker.ps1"
. "$PSScriptRoot\DomainMxUpdater.ps1"
. "$PSScriptRoot\logger.ps1"
. "$PSScriptRoot\DomainMxUpdater.ps1"
. "$PSScriptRoot\ThirdPartyUpdater.ps1"
. "$PSScriptRoot\DomainTlsCsvWriter.ps1"
. "$PSScriptRoot\DomainEmailEnricher.ps1"





$config = Get-AppConfig -FilePath ".\app.properties"
# Initialize logger

Write-Host "Server host: $($config.Get('log.level'))"
 $logger = [LoggerSingleton]::GetLogger("$($config.Get('log.file'))","$($config.Get('log.level'))")



$logger.Info("CSV update started","Main")

# Create the updater instance, passing the logger

<#
#  The updater will read the CSV, update the ThirdParty column, and save it back
# Create updater instance
$updater = [ThirdPartyUpdater]::new("$($config.Get('file.emaildomains'))", $logger)

# Update CSV
$updater.UpdateCsv()

$logger.Info("CSV update finished", "Main")

#>

<#
# the DomainMxUpdater will read the CSV, update the MX records, and save it back
# Create TlsChecker instance with logger and config

$mx = [DomainMxUpdater]::new("$($config.Get('file.emaildomains'))", $logger)

# Run the update
$mx.UpdateCsv()
#>

<#
# Create TlsChecker instance with logger and config
$tlsChecker = [TlsChecker]::new($logger, $config)

# Create unique domains instance with logger and output file
$extractor = [DomainExtractor]::new($logger, "$($config.Get('file.uniquedomains'))")

$domains = $extractor.GetUniqueDomainsFromCsv($config.Get('file.emailexport'))

# Create Domain Writer
$writer = [DomainTlsCsvWriter]::new($logger)

foreach($web in $domains){

    
    $logger.Info("Checking domain $web","Main")
    $result = $tlsChecker.CheckStartTls($web)
    #$tlsCheck = Get-tlsCheck -Domain $web
    $logger.Info("Returned from function $result","Main")

    $writer.AddRecord($config.Get('file.tlsoutput'), $web, $result)

}

#>

# Create the DomainEmailEnricher instance, passing the logger
$logger.Info("Enricher   $($config.Get('file.emailexport'))","Main")
$logger.Info("Enricher $($config.Get('file.emaildomains'))","Main")

$enricher = [DomainEmailEnricher]::new( $logger,"$($config.Get('file.emaildomains'))","$($config.Get('file.emailexport'))")

# Run it
$enricher.ProcessFiles()
