function Get-MxRecords {
    param ([string]$Domain)

    try {
        Resolve-DnsName -Type MX -Name $Domain -ErrorAction Stop |
            Sort-Object Preference |
            Select-Object -ExpandProperty NameExchange
    }
    catch {
        Write-Warning "Could not resolve MX records for $Domain"
        return $null
    }
}

function Invoke-SmtpStartTls {
    param(
        [string]$Server,
        [int]$Port = 25
    )

    Write-Host "Connecting to $Server on port $Port ..." -ForegroundColor Cyan

    try {
        # TCP Connection
        $tcp = New-Object System.Net.Sockets.TcpClient
        $tcp.Connect($Server, $Port)

        $stream = $tcp.GetStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $writer = New-Object System.IO.StreamWriter($stream)

        # Read banner
        Start-Sleep -Milliseconds 300
        $banner = $reader.ReadToEnd()
        Write-Host "Banner:`n$banner" -ForegroundColor DarkGray

        # If port 465, immediately start TLS (implicit SSL)
        if ($Port -eq 465) {
            return Start-TlsHandshake -Stream $stream -Server $Server
        }

        # Send EHLO
        $writer.WriteLine("EHLO local.test")
        $writer.Flush()
        Start-Sleep -Milliseconds 200
        $ehlo = $reader.ReadToEnd()
        Write-Host "EHLO response:`n$ehlo" -ForegroundColor DarkGray

        if ($ehlo -notmatch "STARTTLS") {
            Write-Warning "STARTTLS not supported on $Server : $Port"
            return $null
        }

        Write-Host "STARTTLS supported!" -ForegroundColor Green

        # Issue STARTTLS
        $writer.WriteLine("STARTTLS")
        $writer.Flush()
        Start-Sleep -Milliseconds 200
        $resp = $reader.ReadToEnd()
        Write-Host "STARTTLS response:`n$resp" -ForegroundColor DarkGray

        return Start-TlsHandshake -Stream $stream -Server $Server
    }
    catch {
        Write-Warning "SMTP connection failed: $_"
        return $null
    }
}

function Start-TlsHandshake {
    param(
        [System.IO.Stream]$Stream,
        [string]$Server
    )

    try {
        $ssl = New-Object System.Net.Security.SslStream(
            $Stream,
            $false,
            { $true }   # Accept all certs
        )

        $ssl.AuthenticateAsClient($Server)

        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($ssl.RemoteCertificate)

        return [PSCustomObject]@{
            Server       = $Server
            TLSVersion   = $ssl.SslProtocol
            Cipher       = $ssl.NegotiatedCipherSuite
            CertSubject  = $cert.Subject
            CertIssuer   = $cert.Issuer
            CertExpires  = $cert.NotAfter
            CertValid    = $cert.Verify()
        }
    }
    catch {
        Write-Warning "TLS handshake failed: $_"
        return $null
    }
}

# ---------------------------
# Main Function
# ---------------------------
function Test-EmailDomainTLS {
    param([string]$Domain)

    Write-Host "`n=== Testing TLS for domain: $Domain ===`n" -ForegroundColor Yellow

    $mxRecords = Get-MxRecords -Domain $Domain

    if (-not $mxRecords) {
        Write-Host "No MX records found." -ForegroundColor Red
        return
    }

    foreach ($mx in $mxRecords) {
        foreach ($port in 25, 465, 587) {
            $result = Invoke-SmtpStartTls -Server $mx -Port $port

            if ($result) {
                Write-Host "`n--- TLS Result for $mx : $port ---" -ForegroundColor Green
                $result | Format-List
            }
        }
    }
}

# -------------------------
# Example: test a domain
# -------------------------
Test-EmailDomainTLS -Domain "office365.com"
