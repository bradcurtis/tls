. "$PSScriptRoot\logger.ps1"


# Initialize logger
$logger = [LoggerSingleton]::GetLogger("./tls.log","ERROR")
$logger.Info("CSV update started","tlscheckweb")

function Get-tlsCheck {
     param(
       [string]$Domain
    )

$Url = "https://ssl-tools.net/mailservers/$Domain"
 
try {
    #Write-Output "Querying SSL-Tools for $Domain..."
    $response = Invoke-WebRequest -Uri $Url -UseBasicParsing
    # The site returns HTML, so you can parse it or just display raw content
    $content = $response.Content
    if ($content -match "STARTTLS") {
        #Write-Output "✅ STARTTLS supported on $Domain MX servers"
        $logger.Info("STARTTLS supported on $Domain MX servers","tlscheckweb")
        return $true
    } else {
        #Write-Output "❌ STARTTLS not found in response"
        $logger.Info("STARTTLS not found in response","tlscheckweb")
        return $false
    }
} catch {
    #Write-Error "Failed to query SSL-Tools: $_"
    $logger.Error("Failed to query SSL-Tools: $_","tlscheckweb")
    return $false
}
}
