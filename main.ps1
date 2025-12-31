Import-Module PSReadline
$PSMainPath = $PSScriptRoot;
# Set Intellisense grid selection
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
# Set Intellisense predictions
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView

<#
    tmux나 zellij같은 멀티플렉서를 같이 쓸 경우 paste할때마다
    200~${copied}201~ 이딴 게 같이 붙음.
    Bracketed Paste Mode 문제로, 이걸 해결하기 위한 설정.
#>
$PSStyle.OutputRendering = 'PlainText'

# 모든 로컬 모듈 자동 import
Get-ChildItem -Path "$PSScriptRoot/modules" -Recurse -Filter "*.psm1" | ForEach-Object {
    Import-Module $_.FullName -DisableNameChecking
}


if($IsLinux) {
    # WSL에서 시간 동기화 문제 해결
    hwclock -s
}

function j { just $args }
function p { pnpm $args }
function py { python3 $args }
function pt { poetry $args }
function m8s { microk8s $args }
function kb { kubectl $args }
function kbc { kubectx $args }

<#
  buildkit은 빌드 자체 성능을 높일 수 있지만, mac의 colima 체제 하에서는 error prone이므로 비활성화
#>
$ENV:DOCKER_BUILDKIT = 0
$SERIE_CONFIG_FILE = $ENV:SERIE_CONFIG_FILE = $PSScriptRoot + '/configs/serie.toml'
$ENV:STARSHIP_CONFIG = $PSScriptRoot + '/configs/starship.toml'

# kubectl completion powershell | Out-String | Invoke-Expression
Invoke-Expression (&starship init powershell)


if($IsMacOs) {
    <#
      watcher 제한을 늘려서 동시에 여러 개 프로젝트를 진행할 수 있게 함
    #>
    Start-Job -ScriptBlock {
        & ulimit -n 65536
    } | Out-Null
}

# ~/.pwshrc.ps1 파일이 있는지 체크하고 있다면 실행
if (Test-Path ~/.pwshrc.ps1) {
    . ~/.pwshrc.ps1
}

# odd.ps1 백그라운드 실행
Start-Job -ScriptBlock {
    & "$using:PSMainPath/systems/odd.ps1"
} | Out-Null
