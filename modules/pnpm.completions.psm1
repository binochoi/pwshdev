<#
    pnpm.completions
    pnpm 스크립트 자동완성 모듈
    p run 명령어에 package.json의 scripts를 자동완성으로 제공
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

    # 명령어 AST에서 모든 요소 추출
    $commandElements = $commandAst.CommandElements

    # p run 뒤에 오는 경우에만 scripts 자동완성 제공
    if ($commandElements.Count -ge 2 -and $commandElements[1].Value -eq 'run') {
        Get-PackageJsonScripts |
            Where-Object { $_ -like "$wordToComplete*" } |
            ForEach-Object {
                [System.Management.Automation.CompletionResult]::new(
                    $_, $_, 'ParameterValue', $_
                )
            }
    }
}

Export-ModuleMember -Function p
