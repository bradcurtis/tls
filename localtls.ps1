# ===========================================
# EmailDomainTlsTester.ps1
# PowerShell 5 class for checking MX records and STARTTLS
# ===========================================

class EmailDomainTlsTester {

    [string]$Domain
    $Logger

    EmailDomainTlsTester([string]$Domain, $Logger = $null) {
        $this.Domain = $Domain
        $this.Logger = $Logger
    }

    [string[]] GetMxRecords() {
        try {
            $records = Resolve-DnsName -Type MX -Name $this.Domain -ErrorAction Stop |
                       Sort-Object Preference |
                       Select-Object -ExpandProperty NameExchange
            if ($records -and $records.Count -gt 0) {
                return $records
            }
        } catch {
            if ($this.Logger) { $this.Logger.Warning("Resolve-DnsName failed for $($this.Domain), falling back to nslookup","EmailDomainTlsTester") }
        }

        # Fallback to nslookup
        try {
            $output = & nslookup -type=mx $this.Domain 2>$null
            if (-not $output) {
                if ($this.Logger) { $this.Logger.Warning("nslookup returned no MX data for $($this.Domain)","EmailDomainTlsTester") }
                return @()
            }

            $mx = $output |
                  Select-String -Pattern "mail exchanger" |
                  ForEach-Object { ($_ -split " = ")[-1].Trim() }

            if ($mx -and $mx.Count -gt 0) {
                if ($this.Logger) { $this.Logger.Info("nslookup found MX records for $($this.Domain)","EmailDomainTlsTester") }
                return $mx
            } else {
                if ($this.Logger) { $this.Logger.Warning("nslookup could not extract MX records for $($this.Domain)","EmailDomainTlsTester") }
                return @()
            }
        } catch {
            if ($this.Logger) { $this.Logger.Warning("nslookup fallback failed: $_","EmailDomainTlsTester") }
            return @()
        }
    }

    [PSCustomObject] StartTlsHandshake([System.IO.Stream]$Stream, [string]$Server) {
        try {
            $ssl = New-Object System.Net.Security.SslStream($Stream, $false, { $true })
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
        } catch {
            if ($this.Logger) { $this.Logger.Warning("TLS handshake failed for $Server : $_","EmailDomainTlsTester") }
            return $null
        }
    }

    [PSCustomObject] InvokeSmtpStartTls([string]$Server, [int]$Port = 25) {
        try {
            if ($this.Logger) { $this.Logger.Info("Connecting to $Server on port $Port","EmailDomainTlsTester") }

            $tcp = New-Object System.Net.Sockets.TcpClient
            $tcp.Connect($Server, $Port)

            $stream = $tcp.GetStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $writer = New-Object System.IO.StreamWriter($stream)

            Start-Sleep -Milliseconds 300
            $banner = $reader.ReadToEnd()

            if ($Port -eq 465) {
                return $this.StartTlsHandshake($stream, $Server)
            }

            $writer.WriteLine("EHLO local.test")
            $writer.Flush()
            Start-Sleep -Milliseconds 200
            $ehlo = $reader.ReadToEnd()

            if ($ehlo -notmatch "STARTTLS") {
                if ($this.Logger) { $this.Logger.Warning("STARTTLS not supported on $Server : $Port","EmailDomainTlsTester") }
                return $null
            }

            $writer.WriteLine("STARTTLS")
            $writer.Flush()
            Start-Sleep -Milliseconds 200

            return $this.StartTlsHandshake($stream, $Server)
        } catch {
            if ($this.Logger) { $this.Logger.Warning("SMTP connection failed to $Server : $Port - $_","EmailDomainTlsTester") }
            return $null
        }
    }

    [void] TestTls() {
        $mxRecords = $this.GetMxRecords()
        if (-not $mxRecords -or $mxRecords.Count -eq 0) {
            if ($this.Logger) { $this.Logger.Info("No MX records found for $($this.Domain)","EmailDomainTlsTester") }
            return
        }

        foreach ($mx in $mxRecords) {
            foreach ($port in 25, 465, 587) {
                $result = $this.InvokeSmtpStartTls($mx, $port)
                if ($result) {
                    Write-Host "`n--- TLS Result for $mx : $port ---" -ForegroundColor Green
                    $result | Format-List
                }
            }
        }
    }
}