


$Env:EXA_COLORS+="nb=38;5;239:ub=38;5;241:"    #  0  -> <1KB : grey
$Env:EXA_COLORS+="nk=38;5;29:uk=38;5;100:"     # 1KB -> <1MB : green
$Env:EXA_COLORS+="nm=38;5;26:um=38;5;32:"      # 1MB -> <1GB : blue
$Env:EXA_COLORS+="ng=38;5;130:ug=38;5;166;1:"  # 1GB -> <1TB : orange
$Env:EXA_COLORS+="nt=38;5;160:ut=38;5;197;1:"  # 1TB -> +++  : red
$basedParams = '--icons --color=always --oneline --long --git -L=2 -b --changed -F'
function d {
    Invoke-Expression "eza $basedParams --no-permissions --no-user --no-time $args"
}
function dd {
    Invoke-Expression "eza $basedParams --time-style=relative -a $args"
}
function re { . $profile }
function c($path) {
    Set-Location $path
    d
}
function cc() { Set-Location - }
function ..() { c .. }
function ...() { c ../../ }
function ....() { c ../../../ }
function .....() { c ../../../../ }
function /() { c / }

$profilePath = Split-Path -Path $profile -Parent

Export-ModuleMember -Function *
Export-ModuleMember -Variable *