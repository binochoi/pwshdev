brew install starship

Install-Module -Scope AllUsers QuiteShortAliases
Install-Module -Scope AllUsers Terminal-Icons
Install-Module -Scope AllUsers PSReadline

git config --global safe.directory '*'
# 명령어 실행 결과 화면에서 유지
git config --global --replace-all core.pager "less -IXF"
# 영문 대소문자 구분
git config --global core.ignorecase false
git config --global help.autocorrect 1

git config --global pull.rebase false