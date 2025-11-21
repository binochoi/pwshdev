Remove-Alias gc -Force -ErrorAction SilentlyContinue
Remove-Alias gcb -Force -ErrorAction SilentlyContinue
Remove-Alias gcm -Force -ErrorAction SilentlyContinue
Remove-Alias gcs -Force -ErrorAction SilentlyContinue
Remove-Alias gl -Force -ErrorAction SilentlyContinue
Remove-Alias gm -Force -ErrorAction SilentlyContinue
Remove-Alias gp -Force -ErrorAction SilentlyContinue
Remove-Alias gpv -Force -ErrorAction SilentlyContinue

function g {
	git $args
}
function ga {
    git add $args
}
function gaa {
	git add --all $args
    gs
}
function gst {
    git stage $args
}
function gre($fullPath) {
    git restore --staged $($fullPath ? $fullPath : '.')
}
function gb {
	git branch $args
}
function gbr {
	git branch -r $args
}
function gbk {
    gb $args
    gk $args
}
function gba {
	git branch -a $args
}
function grb {
	git branch --remote $args
}
function gbd() {
    git branch -D $args
    git push origin --delete $args
}
function gc {
	git commit -v $args
}
function gcp {
    gc && git push
}
function gc! {
	git commit -v --amend $args
}
function gclone {
	git clone --recursive $args
}
function gclean {
    git restore .
}
function !gclean {
    git reset --hard && git clean -fd
}
function gw {
    git switch $args
}
function gf {
	git fetch $args
}
function gfa {
	git fetch --all --prune $args
}

function gs() {
    bash "$PSMainPath/scripts/git-st.sh"
}
function gg() {
    # git log --graph --abbrev-commit --decorate --date=relative --format=format:'%C(bold blue)%h%C(reset) - %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset) %C(bold green)(%ar)%C(reset)'
    serie --order=topo $args
}
function gp {
    param(
        [Parameter(Position = 0)]
        [string] $branchName = 'main',
        [Parameter()]
        [string] $remoteName = 'origin'
    )

    if ([string]::IsNullOrEmpty($branchName)) {
        git push $remoteName
    } else {
        git push $remoteName $branchName
    }
}
<# git push from HEAD #>
function gph {
    param(
        [Parameter(Position = 0)]
        [string] $branchName = 'main',
        [string] $remoteName = 'origin'
    )
    git push $remoteName HEAD:$branchName
}
function gpl([string] $branchName) {
    $args = $args[0..10]
    if($args.count -eq 0) {
        $args = @('main')
    }
    Invoke-Expression "git pull origin --recurse-submodules $args"
}
function gk {
    git checkout $args
}

function gm {
    git merge $args
}

$gitBranchCompleter = {
    param($wordToComplete, $commandAst, $cursorPosition)
    
    $branches = @()
    $isGbdr = $commandAst.CommandElements[0].Value -eq 'gbdr'
    
    # stderr를 완전히 무시하는 가장 간단한 방법
    $ErrorActionPreference = 'SilentlyContinue'
    
    try {
        if ($isGbdr) {
            # gbdr는 origin/브랜치도 보여줌
            $branches += (git branch --format "%(refname:short)" 2>&1 | Where-Object { $_ -notmatch "HEAD detached" -and $_ -notmatch "fatal:" }) | Where-Object { $_.Trim() }
            $branches += (git branch -r --format "%(refname:short)" 2>&1 | Where-Object { $_ -notmatch "HEAD detached" -and $_ -notmatch "fatal:" }) | Where-Object { $_.Trim() } | Sort-Object -Unique
        } else {
            $branches += (git branch --format "%(refname:short)" 2>&1 | Where-Object { $_ -notmatch "HEAD detached" -and $_ -notmatch "fatal:" }) | Where-Object { $_.Trim() }
            $branches += (git branch -r --format "%(refname:short)" 2>&1 | Where-Object { $_ -notmatch "HEAD detached" -and $_ -notmatch "fatal:" }) | Where-Object { $_.Trim() } | ForEach-Object { $_ -replace '^origin/', '' } | Sort-Object -Unique
        }
    } catch {
        # 에러 발생 시 빈 배열
        $branches = @()
    } finally {
        $ErrorActionPreference = 'Continue'
    }
    
    $branches | Where-Object { $_ -and $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

@('gk', 'gb', 'gp', 'gph', 'gpl', 'gw', 'gm', 'gbd', 'gbdr', 'grbd') | ForEach-Object {
    Register-ArgumentCompleter -CommandName $_ -ScriptBlock $gitBranchCompleter
}

# 브랜치 삭제 공통 함수들
function Get-BranchesByPattern([string] $pattern, [bool] $isRemote) {
    if([string]::IsNullOrEmpty($pattern)) {
        Write-Error "패턴을 입력해주세요. 예: $($isRemote ? 'grbd' : 'gbd') cursor/*"
        return @()
    }

    if($isRemote) {
        $branches = git branch -r
    } else {
        $branches = git branch | Where-Object { $_ -notmatch '\*' }  # 현재 브랜치 제외
    }
    
    if($pattern.Contains("*")) {
        $escapePattern = [regex]::Escape($pattern).Replace("\*", ".*")
        if($isRemote) {
            $branches = $branches | Where-Object { $_ -match $escapePattern }
        } else {
            $branches = $branches | Where-Object { $_.Trim() -match $escapePattern }
        }
    } else {
        if($isRemote) {
            $exactBranchName = "origin/$pattern"
            $branches = $branches | Where-Object { $_.Trim() -eq $exactBranchName }
        } else {
            $branches = $branches | Where-Object { $_.Trim() -eq $pattern }
        }
    }
    
    return $branches
}

function Confirm-BranchDeletion([array] $branches, [bool] $isRemote) {
    if($branches.Count -eq 0) {
        Write-Host "삭제할 브랜치가 없습니다."
        return $false
    }

    $totalCount = $branches.Count
    $branchType = $isRemote ? "원격" : "로컬"
    Write-Host "`n다음 ${branchType} 브랜치들이 삭제됩니다: (총 ${totalCount}개)" -ForegroundColor Yellow
    foreach($branch in $branches) {
        Write-Host $branch -ForegroundColor Red
    }

    $confirmation = Read-Host "`n정말로 이 브랜치들을 삭제하시겠습니까? (y/N)"
    return $confirmation -eq "y"
}

function Remove-BranchesWithProgress([array] $branches, [bool] $isRemote) {
    $totalCount = $branches.Count
    $deletedCount = 0
    
    foreach($branch in $branches) {
        $branchName = $branch.Trim()
        
        if($isRemote) {
            $branchName = $branchName -replace "origin/", ""
            git push origin --delete $branchName
        } else {
            git branch -D $branchName
        }
        
        if($?) {
            $deletedCount++
            $remainingCount = $totalCount - $deletedCount
            $branchType = $isRemote ? "원격" : "로컬"
            Write-Host "${branchType} 브랜치가 삭제되었습니다: $branchName" -ForegroundColor Green
            Write-Host "(삭제됨: $deletedCount, 남음: $remainingCount)" -ForegroundColor Green
        }
    }
    
    $branchType = $isRemote ? "원격" : "로컬"
    Write-Host "`n작업이 완료되었습니다. 총 ${deletedCount}개의 ${branchType} 브랜치가 삭제되었습니다." -ForegroundColor Cyan
}

# 로컬 브랜치 삭제 (패턴 매칭 지원)
function gbd([string] $pattern) {
    $branches = Get-BranchesByPattern $pattern $false
    if($branches.Count -eq 0) { return }
    
    if(Confirm-BranchDeletion $branches $false) {
        Remove-BranchesWithProgress $branches $false
    } else {
        Write-Host "작업이 취소되었습니다." -ForegroundColor Green
    }
}

# 원격 + 로컬 브랜치 동시 삭제 (패턴 매칭 지원)
function gbdr([string] $pattern) {
    # 원격 브랜치 찾기
    $remoteBranches = Get-BranchesByPattern $pattern $true
    if($remoteBranches.Count -eq 0) { 
        Write-Host "삭제할 원격 브랜치가 없습니다."
        return 
    }

    # 현재 브랜치 확인 (detached HEAD 고려)
    $currentBranch = try { git symbolic-ref --short HEAD 2>$null } catch { '' }
    if ([string]::IsNullOrWhiteSpace($currentBranch)) {
        # (HEAD detached from ...) 상태 확인
        $headLine = git branch | Where-Object { $_ -match '^\*' }
        if ($headLine -and $headLine -match '\(HEAD detached') {
            $currentBranch = '(HEAD detached)'
        } else {
            $currentBranch = 'HEAD'
        }
    }

    # 해당하는 로컬 브랜치 찾기
    $localBranches = @()
    foreach($remoteBranch in $remoteBranches) {
        $branchName = $remoteBranch.Trim() -replace "origin/", ""
        $localBranch = git branch | Where-Object { $_.Replace('*', '').Trim() -eq $branchName }
        if($localBranch) {
            $localBranches += $branchName
        }
    }

    # 삭제 대상 표시
    $totalRemoteCount = $remoteBranches.Count
    $totalLocalCount = $localBranches.Count
    
    Write-Host "`n삭제 대상:" -ForegroundColor Yellow
    Write-Host "원격 브랜치 (총 ${totalRemoteCount}개):" -ForegroundColor Cyan
    foreach($branch in $remoteBranches) {
        Write-Host "  $branch" -ForegroundColor Red
    }
    
    if($totalLocalCount -gt 0) {
        Write-Host "로컬 브랜치 (총 ${totalLocalCount}개):" -ForegroundColor Cyan
        foreach($branch in $localBranches) {
            Write-Host "  $branch" -ForegroundColor Red
        }
    } else {
        Write-Host "해당하는 로컬 브랜치가 없습니다." -ForegroundColor Gray
    }

    $confirmation = Read-Host "`n정말로 이 브랜치들을 삭제하시겠습니까? (y/N)"
    if($confirmation -ne "y") {
        Write-Host "작업이 취소되었습니다." -ForegroundColor Green
        return
    }

    # 현재 브랜치가 삭제 대상에 포함되어 있으면(단, HEAD/detached는 제외)
    if($currentBranch -ne 'HEAD' -and $currentBranch -notlike '(HEAD detached*' -and $localBranches -contains $currentBranch) {
        $safeBranch = @("main", "master", "develop") | Where-Object { 
            $_ -ne $currentBranch -and 
            (git branch | Where-Object { $_.Replace('*', '').Trim() -eq $_ }) 
        } | Select-Object -First 1
        
        if($safeBranch) {
            Write-Host "현재 브랜치($currentBranch)가 삭제 대상이므로 $safeBranch 로 전환합니다." -ForegroundColor Yellow
            git checkout $safeBranch
        } else {
            Write-Error "현재 브랜치($currentBranch)가 삭제 대상이지만 전환할 안전한 브랜치가 없습니다."
            return
        }
    }

    # 원격 브랜치 삭제
    $deletedRemoteCount = 0
    Write-Host "`n원격 브랜치 삭제 중..." -ForegroundColor Yellow
    foreach($remoteBranch in $remoteBranches) {
        $branchName = $remoteBranch.Trim() -replace "origin/", ""
        git push origin --delete $branchName
        if($?) {
            $deletedRemoteCount++
            Write-Host "원격 브랜치 삭제됨: $branchName" -ForegroundColor Green
        }
    }

    # 로컬 브랜치 삭제
    $deletedLocalCount = 0
    if($localBranches.Count -gt 0) {
        Write-Host "`n로컬 브랜치 삭제 중..." -ForegroundColor Yellow
        foreach($localBranch in $localBranches) {
            # HEAD/detached는 삭제 시도하지 않음
            if($localBranch -eq 'HEAD' -or $localBranch -like '(HEAD detached*') { continue }
            git branch -D $localBranch
            if($?) {
                $deletedLocalCount++
                Write-Host "로컬 브랜치 삭제됨: $localBranch" -ForegroundColor Green
            }
        }
    }

    Write-Host "`n작업 완료!" -ForegroundColor Cyan
    Write-Host "삭제된 원격 브랜치: $deletedRemoteCount/$totalRemoteCount" -ForegroundColor Cyan
    Write-Host "삭제된 로컬 브랜치: $deletedLocalCount/$totalLocalCount" -ForegroundColor Cyan
}

# 원격 브랜치 삭제 (패턴 매칭 지원)
function grbd([string] $pattern) {
    $branches = Get-BranchesByPattern $pattern $true
    if($branches.Count -eq 0) { return }
    
    if(Confirm-BranchDeletion $branches $true) {
        Remove-BranchesWithProgress $branches $true
    } else {
        Write-Host "작업이 취소되었습니다." -ForegroundColor Green
    }
}

Set-Alias gl 'gpull'

function Get-GitRemotes() {
    git remote -v $args
}
function Add-GitRemoteURL([string] $url, [string] $remoteName = 'origin') {
    git remote add $remoteName $url
}
function Set-GitRemoteURL([string] $url, [string] $remoteName = 'origin') {
    $remotes = git remote
    if ($remotes -contains $remoteName) {
        git remote set-url $remoteName $url
    } else {
        Add-GitRemoteURL $url $remoteName
    }
    gfa
}

function Find-CommitMessage([string] $keyword, [string] $author) {
    if($keyword -eq '' -and $author -eq '') {
        Write-Error 'call with any parameter !'
        return
    }
    $command = "git log --color --all --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(dim white)<%an>%Creset' --abbrev-commit"
    if($keyword -ne '') {
        $command += " --grep '$keyword'"
    }
    if($author -ne '') {
        $command += " --author '$author'"
    }
    Invoke-Expression $command
}
function Find-ContentsOnGitHistory([string] $matches) {
    $revList = git rev-list --all
    $searched = $revList | %{
        git grep --color --line-number $matches $_
    }
    if($searched.length -eq 0) {
        Write-Host -ForegroundColor White 'nothing'
        return
    }
    echo $searched[0..100]
}
function Get-GitConfig {
	git config --list $args
}
function Set-GitConfig([string] $name, [string] $email, [boolean] $isGlobal) {
    git config --$($isGlobal ? 'global' : 'local') user.name "$name"
    git config --$($isGlobal ? 'global' : 'local') user.email "$email"
}
function Set-GitSubmodule {
    git submodule update --init --recursive $args
}

Export-ModuleMember -Function * -Alias *