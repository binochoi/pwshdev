# Import-Module QuiteShortAliases
# Import-Module Terminal-Icons
Import-Module PSReadline
Import-Module "$PSScriptRoot/modules/short-aliases"

$PSMainPath = $PSScriptRoot;

# Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
# Set Intellisense grid selection
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
# Set Intellisense predictions
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView


if($IsLinux) {
    hwclock -s
}

. ($PSScriptRoot + '/aliases/index.ps1')
. ($PSScriptRoot + '/aliases/hangeul.ps1')

function p { pnpm $args }
function py { python3 $args }
function m8s { microk8s $args }
function kb { kubectl $args }
function kbc { kubectx $args }

kubectl completion powershell | Out-String | Invoke-Expression

$ENV:STARSHIP_CONFIG = $PSScriptRoot + '/assets/starship.config.toml'
Invoke-Expression (&starship init powershell)