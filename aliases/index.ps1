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
function gbr {
	git branch --remote $args
}
function gbd() {
    git branch -D $args
    git push origin --delete $args
}
function gc {
	git commit -v $args
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
    git status -bs
}
function gg() {
    git log --graph --abbrev-commit --decorate --date=relative --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)'
}
function gpush {
    $args = $args[0..10]
    if($args.count -eq 0) {
        $args = @('HEAD:main')
    }
    Invoke-Expression "git push origin $args"
}
function gpull([string] $branchName) {
    $args = $args[0..10]
    if($args.count -eq 0) {
        $args = @('main')
    }
    Invoke-Expression "git pull origin --recurse-submodules $args"
}
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