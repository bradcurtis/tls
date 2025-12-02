. "$PSScriptRoot\logger.ps1"

class TlsChecker {

    $Logger
    $Config

    TlsChecker([LoggerSingleton] $logger, [object] $config) {
        if (-not $logger) {
            throw "Logger instance is required"
        }
        if (-not $config) {
            throw "Config object is required"
        }

        $this.Logger = $logger
        $this.Config = $config

        # Optionally log config values
        $logLevel = $this.Config.Get('log.level')
        $this.Logger.Info("TlsChecker initialized with log level $logLevel", "TlsChecker")
    }

    [bool] CheckStartTls([string] $Domain) {
        if (-not $Domain) {
            throw "Domain parameter is required"
        }

        $Url = "https://ssl-tools.net/mailservers/$Domain"

        try {
            $response = Invoke-WebRequest -Uri $Url -UseBasicParsing
            $content = $response.Content

            if ($content -match "STARTTLS") {
                $this.Logger.Info("STARTTLS supported on $Domain MX servers", "TlsChecker")
                return $true
            }
            else {
                $this.Logger.Info("STARTTLS not found in response for $Domain", "TlsChecker")
                return $false
            }
        }
        catch {
            $this.Logger.Error("Failed to query SSL-Tools for $Domain : $_", "TlsChecker")
            return $false
        }
    }
}
