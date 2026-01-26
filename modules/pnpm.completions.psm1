<#
    pnpm.completions
    pnpm 스크립트 자동완성 모듈
    p 명령어에 package.json의 scripts를 자동완성으로 제공
#>

function Get-PackageJsonScripts {
    $currentPath = Get-Location
    $packageJsonPath = Join-Path $currentPath "package.json"

    if (-not (Test-Path $packageJsonPath)) {
        return @()
    }

    try {
        $packageJson = Get-Content $packageJsonPath -Raw | ConvertFrom-Json

        if ($packageJson.scripts) {
            return $packageJson.scripts.PSObject.Properties | ForEach-Object { $_.Name }
        }
    }
    catch {
        return @()
    }

    return @()
}

function p {
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments)]
        [string[]]$Args
    )

    pnpm @Args
}

# ---- TAB COMPLETION ----

Register-ArgumentCompleter -CommandName p -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    Get-PackageJsonScripts |
        Where-Object { $_ -like "$wordToComplete*" } |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new(
                $_, $_, 'ParameterValue', $_
            )
        }
}

Export-ModuleMember -Function p
