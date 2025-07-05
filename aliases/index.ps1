Set-Alias ex 'exit'
Set-Alias cl 'Clear-Host'
Set-Alias b 'btm'
Set-Alias a 'pwd'

<#
    replacements
#>
Set-Alias nano 'micro'
Set-Alias vi 'micro'
Set-Alias v 'micro'

function Update-AllModules {
    Get-Module -ListAvailable | ForEach-Object { Update-Module -Name $_.Name -Force }
}
# recursive touch
function rtouch {
    $dir = Split-Path $args[0] -Parent
    New-Item -ItemType Directory -Path $dir | Out-Null
    New-Item -ItemType File -Path $args[0] | Out-Null
}
function k([number] $uid) {
    kill -9 $uid
}
function trash([string] $fileNameWithPath) {
    if($fileNameWithPath -eq $null) {
        Write-Error 'unexpected syntax'
        return
    }
    $isNotExistTrashBin = !(Test-Path -Path '~/.Trash')
    if($isNotExistTrashBin) {
        mkdir ~/.trash
    }
    
    <# 이름이 중복되면 숫자 붙여서 변경함 #>
    $nameIndex = 1
    $modifiedNameWithPath = $fileNameWithPath;
    while(Test-Path ('~/.trash/' + $modifiedNameWithPath)) {
        $modifiedNameWithPath = $fileNameWithPath + $nameIndex
        ++$nameIndex
    }
    try {
        if(-not(Test-Path $fileNameWithPath)) {
            Write-Host 'not exist'
            return
        }
        $modifiedFileName = $modifiedNameWithPath.split('/')[-1];
        Move-Item -Force $fileNameWithPath ('~/.trash/' + $modifiedFileName)
        Write-Output '+ add to ~/.Trash bin'
    } catch{}
}
function Get-Ports() {
    if($isWindows) {
        netstat -a -b
    } else {
        netstat -tnlp
    }
}

<#
    docker
#>
# docker up
function dcu {
    docker-compose up $args
}
# container list
function Get-DockerContainers {
    docker ps -a
}
# enter docker shell
function de($containerId) {
    docker exec -it  $containerId /bin/bash
}
function Remove-DockerContainersAll() {
    docker stop $(docker ps -a -q) && docker rm $(docker ps -a -q) $args
}
function Remove-DockerImagesAll() {
    docker rmi -f $(docker images -aq) $args
}
function Remove-DockerVolumesAll() {
    docker volume rm $(docker volume ls -q) $args
}
function Remove-DockerNetworksAll() {
    docker network rm $(docker network ls -q) $args
}
function Remove-DockerProcessAll() {
    Remove-DockerContainersAll
    Remove-DockerImagesAll
    Remove-DockerVolumesAll
    Remove-DockerNetworksAll
    # 한 번에 모든 미사용 Docker 객체 삭제
    docker system prune -a --volumes
}
<#
    GCP
#>
function Get-GcpAllProjects {
    gcloud projects list
}
function Set-GcpProject([string] $name) {
    gcloud config set project $name
}
function Get-GcpAllSecrets {
	gcloud secrets list
}
function Get-GcpSecret([string] $name) {
    gcloud secrets versions access latest --secret $name
}
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
function gdiscard {
    git restore .
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
	git clean -df $args
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
    git push $args
}
function gpull([string] $branchName) {
    $args = $args[0..10]
    if($args.count -eq 0) {
        $args = @('main')
    }
    Invoke-Expression "git pull origin --recurse-submodules $args"
}
function gk {
    git checkout $args
}
<#
    git remove remote branch filter
#>
function grrb([string] $pattern) {
    if([string]::IsNullOrEmpty($pattern)) {
        Write-Error "패턴을 입력해주세요. 예: grrb cursor/*"
        return
    }

    # 원격 브랜치 목록 가져오기
    $branches = git branch -r
    
    # 패턴에 * 가 있는지 확인
    if($pattern.Contains("*")) {
        # * 가 있으면 패턴 매칭
        $branches = $branches | Where-Object { $_ -match [regex]::Escape($pattern).Replace("\*", ".*") }
    } else {
        # * 가 없으면 정확한 이름 매칭
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
        # origin/ 제거하고 실제 브랜치 이름만 추출
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


function Set-Infisical-Key([string] $key) {
    infisical auth --api-key $key
}
<#
    short functions
#>
# Set-Alias ex 'exit'
# Set-Alias cl 'Clear-Host'
# 
# $Env:EXA_COLORS+="nb=38;5;239:ub=38;5;241:"    #  0  -> <1KB : grey
# $Env:EXA_COLORS+="nk=38;5;29:uk=38;5;100:"     # 1KB -> <1MB : green
# $Env:EXA_COLORS+="nm=38;5;26:um=38;5;32:"      # 1MB -> <1GB : blue
# $Env:EXA_COLORS+="ng=38;5;130:ug=38;5;166;1:"  # 1GB -> <1TB : orange
# $Env:EXA_COLORS+="nt=38;5;160:ut=38;5;197;1:"  # 1TB -> +++  : red
# function d {
#     $basedParams = '--icons --color=always --oneline --long --git -L=2 -b --changed -F'
#     Invoke-Expression "eza $basedParams --no-permissions --no-user --no-time $args"
# }
# function re { . $profile }
# function dd { d --time-style=relative -a }
# function c($path) {
#     Set-Location $path
#     d
# }
# function cc() { Set-Location - }
# function ..() { c .. }
# function ...() { c ../../ }
# function ....() { c ../../../ }
# function .....() { c ../../../../ }
# function /() { c / }

function alert() {
    $null = afplay /System/Library/Sounds/Glass.aiff &
}