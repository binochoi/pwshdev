Import-Module QuiteShortAliases
Import-Module Terminal-Icons
Import-Module PSReadline

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

function p { pnpm $args }
function py { python3 $args }

$ENV:STARSHIP_CONFIG = $PSScriptRoot + '/assets/starship.config.toml'
Invoke-Expression (&starship init powershell)