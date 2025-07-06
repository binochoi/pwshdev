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

# Import git aliases and functions
. "$PSScriptRoot/git.ps1"

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