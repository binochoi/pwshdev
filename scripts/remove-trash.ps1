# ~/.Trash 폴더를 비우고 last-empty-trash-at 파일을 업데이트하는 스크립트

$pwshdevPath = "~/.pwshdev"
$lastEmptyTrashAtPath = "$pwshdevPath/last-empty-trash-at"

# ~/.pwshdev 폴더가 없으면 생성
if (!(Test-Path $pwshdevPath)) {
    New-Item -ItemType Directory -Path $pwshdevPath | Out-Null
}

# ~/.Trash 폴더가 있는지 확인
if (!(Test-Path "~/.Trash")) {
    Write-Host "휴지통 폴더가 없습니다."
    exit
}

# 휴지통 비우기
Remove-Item -Path "~/.Trash/*" -Recurse -Force
Write-Host "휴지통을 비웠습니다."

# last-empty-trash-at 파일 업데이트
$currentDate = Get-Date -Format "yyyy-MM-dd"
Set-Content -Path $lastEmptyTrashAtPath -Value $currentDate
Write-Host "last-empty-trash-at 파일이 업데이트되었습니다. (날짜: $currentDate)" 