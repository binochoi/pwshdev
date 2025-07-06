Import-Module PSReadline
$PSMainPath = $PSScriptRoot;
# Set Intellisense grid selection
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
# Set Intellisense predictions
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView

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

# kubectl completion powershell | Out-String | Invoke-Expression
$ENV:STARSHIP_CONFIG = $PSScriptRoot + '/assets/starship.config.toml'
Invoke-Expression (&starship init powershell)

# ~/.pwshrc.ps1 파일이 있는지 체크하고 있다면 실행
if (Test-Path ~/.pwshrc.ps1) {
    . ~/.pwshrc.ps1
}

# odd.ps1 백그라운드 실행
Start-Job -ScriptBlock {
    & "$using:PSMainPath/systems/odd.ps1"
} | Out-Null
