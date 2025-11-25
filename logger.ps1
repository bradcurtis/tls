class LoggerSingleton {
    [string]$LogFile
    [string[]]$ValidLevels = @("INFO","WARNING","ERROR")
    [string]$Mode = "ALL"   # "ALL" or "ERROR" only

    static [LoggerSingleton]$Instance

    hidden LoggerSingleton([string]$Path, [string]$Mode="ALL") {
        $this.LogFile = $Path
        $this.Mode = $Mode.ToUpper()
        if (-not (Test-Path $this.LogFile)) {
            "" | Out-File -FilePath $this.LogFile
        }
    }

    static [LoggerSingleton] GetLogger([string]$Path, [string]$Mode="ALL") {
        if (-not [LoggerSingleton]::Instance) {
            [LoggerSingleton]::Instance = [LoggerSingleton]::new($Path, $Mode)
        } else {
            # Update mode if a different one is requested
            [LoggerSingleton]::Instance.Mode = $Mode.ToUpper()
        }
        return [LoggerSingleton]::Instance
    }

    [void] Write([string]$Message, [string]$Level="INFO", [string]$FunctionName="Global") {
        $Level = $Level.ToUpper()
        if ($this.ValidLevels -notcontains $Level) { $Level = "INFO" }

        # Only log if Mode = ALL, or if Mode = ERROR and Level = ERROR
        if ($this.Mode -eq "ALL" -or ($this.Mode -eq "ERROR" -and $Level -eq "ERROR")) {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            "$timestamp [$Level] [$FunctionName] $Message" | Out-File -FilePath $this.LogFile -Append
        }
    }

    # Convenience methods
    [void] Info([string]$Message, [string]$FunctionName="Global") {
        $this.Write($Message,"INFO",$FunctionName)
    }
    [void] Warning([string]$Message, [string]$FunctionName="Global") {
        $this.Write($Message,"WARNING",$FunctionName)
    }
    [void] Error([string]$Message, [string]$FunctionName="Global") {
        $this.Write($Message,"ERROR",$FunctionName)
    }
}
