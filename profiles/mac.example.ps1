
$Env:PATH += ':/opt/homebrew/opt/node@22/bin'
$Env:PATH += ':/opt/homebrew/bin'
$Env:PATH += ':/opt/homebrew/opt/openjdk@11/bin'
$Env:PATH += ':/Users/bino/Documents/google-cloud-sdk/bin'
$Env:PATH += ':/Users/bino/.local/bin'
$Env:PATH += ':/opt/homebrew/opt/openjdk/bin'
$Env:PATH += ':/Users/bino/Library/Android/sdk/build-tools/36.0.0'
# $Env:JAVA_HOME = "/opt/homebrew/opt/openjdk@21"
$Env:JAVA_HOME = "/opt/homebrew/opt/openjdk"
# $Env:ANDROID_HOME = '/Users/bino/Library/Android/sdk'
$ENv:SDKROOT = '/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk'
$Env:NODE_EXTRA_CA_CERTS="$(mkcert -CAROOT)/rootCA.pem"
$Env:LFTECH_INFISICAL_TOKEN=""
$Env:BINOCORP_INFISICAL_TOKEN=""

. /Users/bino/Documents/pwshdev/main.ps1

function crystal {
	open -n "/Applications/Crystal.app"
}
function claudia {
	open -n "/Applications/Claudia.app"
}
function clauded {
    claude --dangerously-skip-permissions $args
}
function ze {
  ~/Applications/zellij $args
}

function pip {
  pip3 $args
}

