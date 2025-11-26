class LoggerSingleton {
    [string]$LogFile
    [string[]]$ValidLevels = @("INFO","WARNING","ERROR")
    [string]$Mode = "ALL"   # ALL logs OR only errors

    static [LoggerSingleton]$Instance

    hidden LoggerSingleton([string]$Path, [string]$Mode="ALL") {
        $this.LogFile = $Path
        $this.Mode = $Mode.ToUpper()

        if (-not (Test-Path $this.LogFile)) {
            "" | Out-File -FilePath $this.LogFile
        }
    }

    # ---------- GET LOGGER (OVERLOADED BEHAVIOR) ----------

    static [LoggerSingleton] GetLogger() {
        # Default log file if none provided
        return [LoggerSingleton]::GetLogger("$PSScriptRoot\default.log", "ALL")
    }

    static [LoggerSingleton] GetLogger([string]$Path) {
        return [LoggerSingleton]::GetLogger($Path, "ALL")
    }

    static [LoggerSingleton] GetLogger([string]$Path, [string]$Mode) {
        if (-not [LoggerSingleton]::Instance) {
            [LoggerSingleton]::Instance = [LoggerSingleton]::new($Path, $Mode)
        } else {
            [LoggerSingleton]::Instance.Mode = $Mode.ToUpper()
            [LoggerSingleton]::Instance.LogFile = $Path
        }
        return [LoggerSingleton]::Instance
    }

    # ---------- LOGGING ----------

    [void] Write([string]$Message, [string]$Level="INFO", [string]$FunctionName="Global") {
        $Level = $Level.ToUpper()
        if ($this.ValidLevels -notcontains $Level) { $Level = "INFO" }

        # Respect mode (ALL or ERROR-only)
        if ($this.Mode -eq "ALL" -or ($this.Mode -eq "ERROR" -and $Level -eq "ERROR")) {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            "$timestamp [$Level] [$FunctionName] $Message" |
                Out-File -FilePath $this.LogFile -Append
        }
    }

    [void] Info([string]$Message, [string]$FunctionName="Global") {
        $this.Write($Message, "INFO", $FunctionName)
    }

    [void] Warning([string]$Message, [string]$FunctionName="Global") {
        $this.Write($Message, "WARNING", $FunctionName)
    }

    [void] Error([string]$Message, [string]$FunctionName="Global") {
        $this.Write($Message, "ERROR", $FunctionName)
    }
}
