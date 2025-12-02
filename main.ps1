
Import-Module .\module\AppConfig.psm1 -Force

. "$PSScriptRoot\extractdomain.ps1"
. "$PSScriptRoot\tlscheckweb.ps1"
. "$PSScriptRoot\updatecsv.ps1"
. "$PSScriptRoot\logger.ps1"
. "$PSScriptRoot\DomainMxUpdater.ps1"
. "$PSScriptRoot\ThirdPartyUpdater.ps1"



$config = Get-AppConfig -FilePath ".\app.properties"
# Initialize logger

Write-Host "Server host: $($config.Get('log.level'))"
 $logger = [LoggerSingleton]::GetLogger("$($config.Get('log.file'))","$($config.Get('log.level'))")


# comment out this line to place logger in debug mode
# $logger = [LoggerSingleton]::GetLogger("./tls.log")
$logger.Info("CSV update started","Main")

$logger.Error("test","Main")



# $csv = ".\tlsexport.csv"
#$csv = ".\emailexport.csv"

# Create the updater instance, passing the logger


# Create updater instance
$updater = [ThirdPartyUpdater]::new("$($config.Get('file.emaildomains'))", $logger)

# Update CSV
$updater.UpdateCsv()

$logger.Info("CSV update finished", "Main")

<#

$mx = [DomainMxUpdater]::new("$($config.Get('file.emaildomains'))", $logger)

# Run the update
$mx.UpdateCsv()

$domains = Get-UniqueDomainsFromCsv -CsvPath $csv
foreach($web in $domains){

    
    $logger.Info("Checking domain $web","Main")
    $tlsCheck = Get-tlsCheck -Domain $web
    $logger.Info("Returned from function $tlsCheck","Main")
   
    Add-DomainTlsRecord -CsvPath ".\domainlist.csv" -DomainName $web -Tls $tlsCheck

}
#>