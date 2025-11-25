function Get-MxRecords {
    param([string]$Domain)

    try {
        $mx = Resolve-DnsName -Name $Domain -Type MX -ErrorAction Stop |
            Sort-Object -Property Preference |
            Select-Object -ExpandProperty NameExchange
        return $mx
    }
    catch {
        Write-Warning "DNS lookup failed for $Domain"
        return $null
    }
}

function Send-SmtpCommand {
    param(
        [System.IO.StreamWriter]$Writer,
        [System.IO.StreamReader]$Reader,
        [string]$Command
    )

    if ($Command) {
        $Writer.WriteLine($Command)
        $Writer.Flush()
    }

    # Read until no more data is immediately available
    Start-Sleep -Milliseconds 200
    $response = ""
    while ($Reader.Peek() -ge 0) {
        $response += $Reader.ReadLine() + "`n"
    }

    return $response.Trim()
}

function Test-StartTls {
    param(
        [string]$Server,
        [int]$Port = 25
    )

    Write-Host " I am starting `nTesting $Server" -ForegroundColor Cyan

    try {
        # TCP connection
        $tcp = New-Object System.Net.Sockets.TcpClient
        $tcp.Connect($Server, $Port)

        $stream = $tcp.GetStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $writer = New-Object System.IO.StreamWriter($stream)

        # SMTP banner
        $banner = Send-SmtpCommand -Writer $writer -Reader $reader
        Write-Host $banner -ForegroundColor DarkGray

        # EHLO
        $ehlo = Send-SmtpCommand -Writer $writer -Reader $reader -Command "EHLO testdomain.com"
        Write-Host $ehlo -ForegroundColor DarkGray

        if ($ehlo -notmatch "STARTTLS") {
            Write-Host "STARTTLS not supported on $Server" -ForegroundColor Yellow
            $tcp.Close()
            return
        }

        Write-Host "STARTTLS supported. Negotiating TLS..." -ForegroundColor Green

        # STARTTLS command
        $resp = Send-SmtpCommand -Writer $writer -Reader $reader -Command "STARTTLS"
        Write-Host $resp -ForegroundColor DarkGray

        # Begin TLS
        $sslStream = New-Object System.Net.Security.SslStream(
            $stream,
            $false,
            { $true }  # Ignore cert errors
        )

        $sslStream.AuthenticateAsClient($Server)

        # Get TLS info
        $tlsVersion = $sslStream.SslProtocol
        $cipher = $sslStream.NegotiatedCipherSuite

        Write-Host "TLS Version: $tlsVersion" -ForegroundColor Green
        Write-Host "Cipher Suite: $cipher" -ForegroundColor Green

        # Certificate details
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($sslStream.RemoteCertificate)

        Write-Host "Certificate Subject: $($cert.Subject)"
        Write-Host "Issuer:             $($cert.Issuer)"
        Write-Host "Expires:            $($cert.NotAfter)"
        Write-Host "Valid:              $($cert.Verify())"

        # Cleanup
        $sslStream.Close()
        $tcp.Close()
    }
    catch {
        Write-Warning "Connection or TLS handshake failed: $_"
    }
}

# MAIN LOOP ---------------------------------------------------------

$domain = "google.com"

$mxRecords = Get-MxRecords -Domain $domain

if (-not $mxRecords) {
    Write-Host "No MX records found."
    exit
}

foreach ($mx in $mxRecords) {
    Test-StartTls -Server $mx -Port 25
}
