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
        [ValidateSet("list", "cd", "run", "remove", "new")]
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
            if ([string]::IsNullOrEmpty($Target)) {
                Write-Error "패턴을 입력해주세요. 예: gwt remove list*"
                return
            }

            $worktrees = Get-GitWorktrees
            $matchedWorktrees = @()

            if ($Target.Contains("*")) {
                $escapePattern = [regex]::Escape($Target).Replace("\*", ".*")
                $matchedWorktrees = $worktrees | Where-Object { $_.Name -match "^$escapePattern$" }
            } else {
                $matchedWorktrees = $worktrees | Where-Object { $_.Name -eq $Target }
            }

            if ($matchedWorktrees.Count -eq 0) {
                Write-Host "삭제할 worktree가 없습니다."
                return
            }

            $totalCount = $matchedWorktrees.Count
            Write-Host "`n다음 worktree들이 삭제됩니다: (총 ${totalCount}개)" -ForegroundColor Yellow
            foreach ($wt in $matchedWorktrees) {
                Write-Host "  $($wt.Name) - $($wt.Path)" -ForegroundColor Red
            }

            $confirmation = Read-Host "`n정말로 이 worktree들을 삭제하시겠습니까? (y/N)"
            if ($confirmation -ne "y") {
                Write-Host "작업이 취소되었습니다." -ForegroundColor Green
                return
            }

            $deletedCount = 0
            foreach ($wt in $matchedWorktrees) {
                git worktree remove $wt.Path
                if ($?) {
                    $deletedCount++
                    $remainingCount = $totalCount - $deletedCount
                    Write-Host "worktree가 삭제되었습니다: $($wt.Name)" -ForegroundColor Green
                    Write-Host "(삭제됨: $deletedCount, 남음: $remainingCount)" -ForegroundColor Green
                }
            }

            Write-Host "`n작업이 완료되었습니다. 총 ${deletedCount}개의 worktree가 삭제되었습니다." -ForegroundColor Cyan
        }

        "new" {
            if ([string]::IsNullOrEmpty($Target)) {
                Write-Error "브랜치 이름을 입력해주세요. 예: gwt new feature-branch"
                return
            }

            $repoName = (git rev-parse --show-toplevel | Split-Path -Leaf)
            $worktreePath = "$HOME/worktrees/$repoName-$Target"

            git worktree add -b $Target $worktreePath
            if ($?) {
                Set-Location $worktreePath
                Write-Host "새 worktree가 생성되었습니다: $worktreePath" -ForegroundColor Green
            }
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