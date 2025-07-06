<#
  background에서 간헐적으로 한 번씩만 실행해도 되는 코드들
#>
git config --global user.name "bino"
git config --global user.email "bonoself@gmail.com"

# 휴지통 자동 비우기 체크
$pwshdevPath = "~/.pwshdev"
$lastEmptyTrashAtPath = "$pwshdevPath/last-empty-trash-at"

# ~/.pwshdev 폴더와 last-empty-trash-at 파일이 없으면 생성
if (!(Test-Path $pwshdevPath)) {
    New-Item -ItemType Directory -Path $pwshdevPath | Out-Null
}

if (!(Test-Path $lastEmptyTrashAtPath)) {
    # 처음 실행시 바로 비우도록 한 달 전 날짜로 설정
    $initialDate = (Get-Date).AddMonths(-1).ToString("yyyy-MM-dd")
    Set-Content -Path $lastEmptyTrashAtPath -Value $initialDate
}

# last-empty-trash-at 파일 읽기
$lastEmptyTrashAt = [DateTime]::ParseExact((Get-Content $lastEmptyTrashAtPath), "yyyy-MM-dd", $null)
$today = Get-Date
$daysDifference = ($today - $lastEmptyTrashAt).Days

# 한 달(30일)이 지났으면 remove-trash.ps1 실행
if ($daysDifference -ge 30) {
    & "$PSScriptRoot/remove-trash.ps1"
} 