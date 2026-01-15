<#
    GWT (git worktree)
    git worktree 커맨드를 축약한 모듈
#>
function Get-GitWorktrees {
    $output = git worktree list --porcelain 2>$null
    if (-not $output) { return @() }

    $list = @()
    $current = @{}

    foreach ($line in $output) {
        if ($line -like "worktree *") {
            if ($current.Path) {
                # Name이 설정되지 않은 경우 폴더 이름 사용 (bare worktree 등)
                if (-not $current.Name) {
                    $current.Name = Split-Path $current.Path -Leaf
                }
                $list += [pscustomobject]$current
                $current = @{}
            }
            $current.Path = $line.Substring(9)
        }
        elseif ($line -like "branch *") {
            $current.Branch = $line.Substring(7)
            # 브랜치 이름을 Name으로 사용 (refs/heads/ 제거)
            $current.Name = $current.Branch -replace '^refs/heads/', ''
        }
    }

    if ($current.Path) {
        # Name이 설정되지 않은 경우 폴더 이름 사용
        if (-not $current.Name) {
            $current.Name = Split-Path $current.Path -Leaf
        }
        $list += [pscustomobject]$current
    }

    return $list
}

function Resolve-Worktree {
    param($Name)

    $wt = Get-GitWorktrees | Where-Object {
        $_.Name -eq $Name
    }

    if (-not $wt) {
        throw "worktree 없음: $Name"
    }

    return $wt.Path
}

function gwt {
    param(
        [Parameter(Position = 0)]
        [ValidateSet("list", "cd", "run", "remove")]
        [string]$Command,

        [Parameter(Position = 1)]
        [string]$Target,

        [Parameter(Position = 2, ValueFromRemainingArguments)]
        [string[]]$Args
    )

    switch ($Command) {

        "list" {
            Get-GitWorktrees |
                Format-Table Name, Branch, Path -AutoSize
        }

        "cd" {
            $path = Resolve-Worktree $Target
            Set-Location $path
        }

        "run" {
            if (-not $Args) {
                throw "실행할 커맨드 없음"
            }

            $path = Resolve-Worktree $Target
            Push-Location $path
            try {
                & $Args
            }
            finally {
                Pop-Location
            }
        }

        "remove" {
            $path = Resolve-Worktree $Target
            git worktree remove $path
        }
    }
}

# ---- TAB COMPLETION ----

Register-ArgumentCompleter -CommandName gwt -ParameterName Target -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete)

    Get-GitWorktrees |
        ForEach-Object Name |
        Where-Object { $_ -like "$wordToComplete*" } |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new(
                $_, $_, 'ParameterValue', $_
            )
        }
}

Export-ModuleMember -Function gwt