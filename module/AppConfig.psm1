# module-scope variable (works in PS 5.1)
$script:AppConfigInstance = $null

class AppConfig {

    [hashtable] $Properties = @{}

    AppConfig([string] $filePath) {

        if (-not (Test-Path $filePath)) {
            throw "Properties file not found: $filePath"
        }

        Get-Content $filePath | ForEach-Object {
            if ($_ -match "^\s*([^#][^=]+)\s*=\s*(.+)$") {
                $key   = $matches[1].Trim()
                $value = $matches[2].Trim()
                $this.Properties[$key] = $value
            }
        }
    }

    [string] Get([string] $key) {
        return $this.Properties[$key]
    }
}

function Get-AppConfig {
    param([string] $FilePath)

    if (-not $script:AppConfigInstance) {
        $script:AppConfigInstance = [AppConfig]::new($FilePath)
    }

    return $script:AppConfigInstance
}

Export-ModuleMember -Function Get-AppConfig
