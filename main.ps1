. "$PSScriptRoot\extractdomain.ps1"
. "$PSScriptRoot\tlscheckweb.ps1"
. "$PSScriptRoot\updatecsv.ps1"
. "$PSScriptRoot\logger.ps1"


# Initialize logger
 $logger = [LoggerSingleton]::GetLogger("./tls.log","ERROR")

# comment out this line to place logger in debug mode
# $logger = [LoggerSingleton]::GetLogger("./tls.log")
$logger.Info("CSV update started","Main")


# $csv = ".\tlsexport.csv"
$csv = ".\emailexport.csv"

$domains = Get-UniqueDomainsFromCsv -CsvPath $csv

foreach($web in $domains){

    
    $logger.Info("Checking domain $web","Main")
    $tlsCheck = Get-tlsCheck -Domain $web
    $logger.Info("Returned from function $tlsCheck","Main")
   
    Add-DomainTlsRecord -CsvPath ".\domainlist.csv" -DomainName $web -Tls $tlsCheck

}