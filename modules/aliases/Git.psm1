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
    git log --graph --abbrev-commit --decorate --date=relative --format=format:'%C(bold blue)%h%C(reset) - %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset) %C(bold green)(%ar)%C(reset)'
}
function gp {
    param(
        [Parameter(Position = 0)]
        [string] $branchName,
        [Parameter()]
        [string] $remoteName = 'origin'
    )

    if ([string]::IsNullOrEmpty($branchName)) {
        git push $remoteName
    } else {
        git push $remoteName $branchName
    }
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
    $branches += git branch --format "%(refname:short)" 2>$null
    $branches += git branch -r --format "%(refname:short)" 2>$null | ForEach-Object { $_ -replace '^origin/', '' } | Sort-Object -Unique
    
    $branches | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

@('gk', 'gb', 'gp', 'gpl', 'gw', 'gm') | ForEach-Object {
    Register-ArgumentCompleter -CommandName $_ -ScriptBlock $gitBranchCompleter
}

function grrb([string] $pattern) {
    if([string]::IsNullOrEmpty($pattern)) {
        Write-Error "패턴을 입력해주세요. 예: grrb cursor/*"
        return
    }

    $branches = git branch -r
    
    if($pattern.Contains("*")) {
        $branches = $branches | Where-Object { $_ -match [regex]::Escape($pattern).Replace("\*", ".*") }
    } else {
        $exactBranchName = "origin/$pattern"
        $branches = $branches | Where-Object { $_.Trim() -eq $exactBranchName }
    }
    
    if($branches.Count -eq 0) {
        Write-Host "삭제할 브랜치가 없습니다: $pattern"
        return
    }

    $totalCount = $branches.Count
    Write-Host "`n다음 브랜치들이 삭제됩니다: (총 ${totalCount}개)" -ForegroundColor Yellow
    foreach($branch in $branches) {
        Write-Host $branch -ForegroundColor Red
    }

    $confirmation = Read-Host "`n정말로 이 브랜치들을 삭제하시겠습니까? (y/N)"
    if($confirmation -ne "y") {
        Write-Host "작업이 취소되었습니다." -ForegroundColor Green
        return
    }

    $deletedCount = 0
    foreach($branch in $branches) {
        $branchName = $branch.Trim() -replace "origin/", ""
        git push origin --delete $branchName
        if($?) {
            $deletedCount++
            $remainingCount = $totalCount - $deletedCount
            Write-Host "브랜치가 삭제되었습니다: $branchName" -ForegroundColor Green
            Write-Host "(삭제됨: $deletedCount, 남음: $remainingCount)" -ForegroundColor Green
        }
    }
    
    Write-Host "`n작업이 완료되었습니다. 총 ${deletedCount}개의 브랜치가 삭제되었습니다." -ForegroundColor Cyan
}

Set-Alias gl 'gpull'

function Get-GitRemotes() {
    git remote -v $args
}
function Set-GitRemoteURL([string] $url, [string] $remoteName = 'origin') {
    git remote set-url $remoteName $url;
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