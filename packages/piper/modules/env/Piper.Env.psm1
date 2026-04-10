class EnvVar {
    [void] Set() {
        if (Test-Path .env) {
            Get-Content .env | ForEach-Object {
                if ($_ -match '^\s*([^#][^=]*)\s*=\s*(.*)\s*$') {
                    [System.Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim(), 'Process')
                }
            }
        }
    }
}
Export-ModuleMember -Variable * -Function * -Alias *