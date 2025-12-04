Import-Module .\module\AppConfig.psm1 -Force
. "$PSScriptRoot\logger.ps1"

. "$PSScriptRoot\localtls.ps1"

$config = Get-AppConfig -FilePath ".\app.properties"

Write-Host "Server host: $($config.Get('log.level'))"
$logger = [LoggerSingleton]::GetLogger("$($config.Get('log.file'))","$($config.Get('log.level'))")


$tester = [EmailDomainTlsTester]::new("acebright.com", $logger)
$tester.TestTls()




