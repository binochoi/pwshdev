Set-Alias ex 'exit'
Set-Alias cl 'Clear-Host'
Set-Alias b 'btm'
Set-Alias a 'pwd'

Set-Alias nano 'nvim'
Set-Alias vi 'nvim'
Set-Alias v 'nvim'

function !down {
    sudo shutdown -h now
}

function !reboot {
    # Disable reopen windows when logging back in
    defaults write com.apple.loginwindow TALLogoutSavesState -bool false
    defaults write com.apple.loginwindow LoginwindowLaunchesRelaunchApps -bool false
    
    # Reboot
    sudo shutdown -r now
}

function Update-AllModules {
    Get-Module -ListAvailable | ForEach-Object { Update-Module -Name $_.Name -Force }
}

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

function dcu {
    docker-compose up $args
}

function Get-DockerContainers {
    docker ps -a
}

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
    docker system prune -a --volumes
}

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

function Set-Infisical-Key([string] $key) {
    infisical auth --api-key $key
}

function alert() {
    $null = afplay /System/Library/Sounds/Glass.aiff &
}

Export-ModuleMember -Function * -Alias *