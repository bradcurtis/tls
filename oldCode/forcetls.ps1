$emailList = @(
    "user1@gmail.com",
    "user2@outlook.com",
    "user3@yourdomain.com"
)

# Function to get domain from email
function Get-DomainFromEmail($email) {
    return ($email -split "@")[1]
}

# Function to test TLS connection
function Test-TLS {
    param (
        [string]$Server,
        [int]$Port = 587
    )

    try {
        $tcp = New-Object System.Net.Sockets.TcpClient($Server, $Port)
        $ssl = New-Object System.Net.Security.SslStream($tcp.GetStream(), $false,
            { param($sender,$cert,$chain,$errors) return $true })

        $ssl.AuthenticateAsClient($Server)

        return [PSCustomObject]@{
            Server     = $Server
            Port       = $Port
            TLSVersion = $ssl.SslProtocol
            Cipher     = $ssl.NegotiatedCipherSuite
        }

    } catch {
        return [PSCustomObject]@{
            Server     = $Server
            Port       = $Port
            TLSVersion = "Connection failed"
            Cipher     = $null
        }
    }
}

# Check each email domain
foreach ($email in $emailList) {
    $domain = Get-DomainFromEmail $email
    Write-Host "`nChecking TLS for $domain ..." -ForegroundColor Cyan

    $result = Test-TLS -Server $domain -Port 587
    $result | Format-Table -AutoSize
}