<#
  background에서 간헐적으로 한 번씩만 실행해도 되는 코드들
#>
git config --global user.name "bino"
git config --global user.email "bonoself@gmail.com"
git config --global core.ignorecase false

# 휴지통 자동 비우기 체크
$pwshdevPath = "~/.pwshdev"
$lastEmptyTrashAtPath = "$pwshdevPath/last-empty-trash-at"

# ~/.pwshdev 폴더가 없으면 생성
if (!(Test-Path $pwshdevPath)) {
    New-Item -ItemType Directory -Path $pwshdevPath | Out-Null
}

if (!(Test-Path $lastEmptyTrashAtPath)) {
    & "$PSScriptRoot/scripts/remove-trash.ps1"
} else {
    # last-empty-trash-at 파일 읽기
    $lastEmptyTrashAt = [DateTime]::ParseExact((Get-Content $lastEmptyTrashAtPath), "yyyy-MM-dd", $null)
    $today = Get-Date
    $daysDifference = ($today - $lastEmptyTrashAt).Days

    # 한 달(30일)이 지났으면 remove-trash.ps1 실행
    if ($daysDifference -ge 30) {
        & "$PSScriptRoot/scripts/remove-trash.ps1"
    }
}

# git repository 체크 및 fetch
$currentPath = Get-Location
if (Test-Path "$currentPath/.git") {
    gf
}