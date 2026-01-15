<#
    GitHub 모듈
    gh CLI를 활용하여 모든 organization의 repositories를 관리하고 코드 검색 기능을 제공합니다.
#>

# ===========================
# 1. 상수 및 설정
# ===========================

$CACHE_DIR = "$HOME/.cache/pwshdev"
$CACHE_FILE = "$CACHE_DIR/github-repos.json"
$CACHE_TTL = 3600 * 24 * 7
$PARALLEL_LIMIT = 10

# ===========================
# 2. Helper 함수들
# ===========================

function Test-GhCli {
    <#
    .SYNOPSIS
    gh CLI 설치 및 인증 상태를 확인합니다.
    #>

    # gh 명령어 존재 확인
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        throw "gh CLI가 설치되지 않았습니다. 설치: brew install gh"
    }

    # gh 인증 상태 확인
    $authStatus = gh auth status 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "gh CLI 인증이 필요합니다. 실행: gh auth login"
    }
}

function Get-CachedRepos {
    <#
    .SYNOPSIS
    캐시에서 repository 목록을 읽어옵니다.
    .DESCRIPTION
    캐시 파일이 존재하고 TTL이 유효한 경우 repos 배열을 반환합니다.
    그렇지 않으면 $null을 반환합니다. (Piper.Cache 패턴)
    #>

    # 캐시 파일 존재 확인
    if (-not (Test-Path $CACHE_FILE)) {
        return $null
    }

    try {
        # JSON 파싱
        $cache = Get-Content $CACHE_FILE -Raw | ConvertFrom-Json

        # TTL 체크
        if ($cache.expiresAt) {
            $expiresAt = [DateTime]::Parse($cache.expiresAt)
            if ([DateTime]::Now -gt $expiresAt) {
                Write-Host "캐시 만료됨, 재수집합니다..." -ForegroundColor Gray
                return $null
            }
        }

        # repos 배열 반환
        return $cache.data.repos
    }
    catch {
        # JSON 파싱 실패나 기타 에러 시 조용히 $null 반환
        Write-Host "캐시 파일 손상됨, 재수집합니다..." -ForegroundColor Gray
        return $null
    }
}

function Set-CachedRepos {
    <#
    .SYNOPSIS
    Repository 목록을 캐시 파일에 저장합니다.
    .PARAMETER Repos
    저장할 repository 배열
    #>
    param(
        [Parameter(Mandatory)]
        [array]$Repos
    )

    # 디렉토리 생성 (없으면)
    $dir = Split-Path $CACHE_FILE -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    # TTL 계산 (ISO 8601 형식)
    $expiresAt = [DateTime]::Now.AddSeconds($CACHE_TTL).ToString("o")

    # 캐시 객체 생성
    $cache = @{
        data = @{
            repos = $Repos
        }
        expiresAt = $expiresAt
    }

    # JSON으로 저장
    $cache | ConvertTo-Json -Depth 10 | Set-Content $CACHE_FILE -Encoding UTF8
}

function Get-AllRepositories {
    <#
    .SYNOPSIS
    gh API를 사용하여 모든 organization의 repositories를 수집합니다.
    .DESCRIPTION
    사용자 본인의 repos와 모든 organization의 repos를 병렬로 조회합니다.
    #>

    $allRepos = @()

    try {
        # 1. 사용자 본인의 repositories 조회
        Write-Host "사용자 repositories 조회 중..." -ForegroundColor Gray
        $userReposJson = gh api user/repos --paginate --jq '.[] | {owner:.owner.login, name:.name, private:.private, url:.html_url}' 2>$null

        if ($userReposJson) {
            $userRepos = $userReposJson | ForEach-Object {
                $_ | ConvertFrom-Json
            }

            foreach ($repo in $userRepos) {
                $allRepos += @{
                    owner = $repo.owner
                    name = $repo.name
                    fullName = "$($repo.owner)/$($repo.name)"
                    url = $repo.url
                    isPrivate = $repo.private
                    org = $null
                }
            }
        }

        # 2. Organizations 조회
        Write-Host "Organizations 조회 중..." -ForegroundColor Gray
        $orgsJson = gh api user/orgs --paginate --jq '.[].login' 2>$null

        if ($orgsJson) {
            $orgs = $orgsJson | ForEach-Object { $_ }

            Write-Host "총 $($orgs.Count)개 organizations 발견" -ForegroundColor Gray

            # 3. 각 organization의 repos 병렬 조회
            $orgRepos = $orgs | ForEach-Object -Parallel {
                $org = $_

                try {
                    $reposJson = gh api "orgs/$org/repos" --paginate --jq '.[] | {owner:.owner.login, name:.name, private:.private, url:.html_url}' 2>$null

                    if ($reposJson) {
                        $repos = $reposJson | ForEach-Object {
                            $_ | ConvertFrom-Json
                        }

                        foreach ($repo in $repos) {
                            [PSCustomObject]@{
                                owner = $repo.owner
                                name = $repo.name
                                fullName = "$($repo.owner)/$($repo.name)"
                                url = $repo.url
                                isPrivate = $repo.private
                                org = $org
                            }
                        }
                    }
                }
                catch {
                    # 권한 없는 org는 조용히 스킵
                }
            } -ThrottleLimit 10

            if ($orgRepos) {
                $allRepos += $orgRepos
            }
        }

        # 4. 중복 제거 (fullName 기준)
        $uniqueRepos = @{}
        foreach ($repo in $allRepos) {
            $fullName = $repo.fullName
            if (-not $uniqueRepos.ContainsKey($fullName)) {
                $uniqueRepos[$fullName] = $repo
            }
        }

        # 5. 배열로 변환하여 반환
        return $uniqueRepos.Values | Sort-Object -Property fullName

    }
    catch {
        Write-Host "Repository 수집 중 오류 발생: $_" -ForegroundColor Red
        throw
    }
}

function Update-RepositoryCache {
    <#
    .SYNOPSIS
    Repository 캐시를 갱신합니다.
    .PARAMETER Force
    캐시가 유효하더라도 강제로 갱신합니다.
    #>
    param(
        [switch]$Force
    )

    # Force가 아니면 캐시 확인
    if (-not $Force) {
        $cached = Get-CachedRepos
        if ($cached) {
            return $cached
        }
    }

    # gh CLI 검증
    Test-GhCli

    # Repository 수집
    Write-Host "GitHub repositories 수집 중..." -ForegroundColor Yellow
    $repos = Get-AllRepositories

    if (-not $repos) {
        Write-Host "수집된 repositories가 없습니다." -ForegroundColor Yellow
        return @()
    }

    # 캐시 저장
    Set-CachedRepos -Repos $repos

    Write-Host "총 $($repos.Count)개 repositories 수집 완료" -ForegroundColor Green

    return $repos
}

# ===========================
# 3. 서브커맨드 구현 함수들
# ===========================

function Invoke-GithubRepos {
    <#
    .SYNOPSIS
    모든 repository 목록을 표시합니다.
    .PARAMETER Detailed
    상세 정보 (organization별 그룹화, private 여부)를 표시합니다.
    #>
    param(
        [switch]$Detailed
    )

    # 캐시에서 repos 로드
    $repos = Update-RepositoryCache

    if (-not $repos -or $repos.Count -eq 0) {
        Write-Host "Repository가 없습니다." -ForegroundColor Yellow
        return
    }

    if ($Detailed) {
        # 상세 정보 출력 (organization별 그룹화)
        $grouped = $repos | Group-Object -Property {
            if ($_.org) { $_.org } else { "(Personal)" }
        }

        foreach ($group in ($grouped | Sort-Object Name)) {
            Write-Host "`n[$($group.Name)]" -ForegroundColor Cyan
            foreach ($repo in ($group.Group | Sort-Object fullName)) {
                $privacy = if ($repo.isPrivate) { "Private" } else { "Public" }
                Write-Host "  $($repo.fullName) " -NoNewline
                Write-Host "($privacy)" -ForegroundColor Gray
            }
        }

        Write-Host "`n총 $($repos.Count)개 repositories" -ForegroundColor Green
    }
    else {
        # 단순 목록
        $repos | ForEach-Object { $_.fullName }
    }
}

function Invoke-GithubRefresh {
    <#
    .SYNOPSIS
    캐시를 수동으로 갱신합니다.
    #>

    Write-Host "캐시 갱신 중..." -ForegroundColor Yellow
    Update-RepositoryCache -Force | Out-Null
}

function Invoke-GithubClone {
    <#
    .SYNOPSIS
    Repository를 clone합니다.
    .PARAMETER Repo
    Clone할 repository (owner/repo 형식)
    .PARAMETER Path
    Clone할 경로 (선택적, 없으면 현재 디렉토리)
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Repo,

        [Parameter()]
        [string]$Path
    )

    # gh CLI 검증
    Test-GhCli

    # git clone처럼 동작
    if ($Path) {
        gh repo clone $Repo $Path
    }
    else {
        gh repo clone $Repo
    }
}

function Invoke-GithubSearch {
    <#
    .SYNOPSIS
    모든 repositories에서 코드를 검색합니다.
    .PARAMETER Keyword
    검색할 키워드
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Keyword
    )

    if (-not $Keyword) {
        throw "검색 키워드를 입력하세요"
    }

    # gh CLI 검증
    Test-GhCli

    # 모든 repos 가져오기 (캐시 사용)
    $repos = Update-RepositoryCache

    if (-not $repos -or $repos.Count -eq 0) {
        Write-Host "검색할 repository가 없습니다." -ForegroundColor Yellow
        return
    }

    Write-Host "총 $($repos.Count)개 repositories에서 '$Keyword' 검색 중..." -ForegroundColor Yellow

    # 병렬 검색 - 키워드를 변수로 저장
    $searchKeyword = $Keyword
    $results = $repos | ForEach-Object -Parallel {
        $repo = $_
        $kw = $using:searchKeyword

        try {
            # gh search code 사용
            $output = gh search code --repo "$($repo.fullName)" "$kw" --json path,textMatches 2>$null

            if ($output -and $output -ne "[]") {
                $data = $output | ConvertFrom-Json

                foreach ($item in $data) {
                    [PSCustomObject]@{
                        Repo = $repo.fullName
                        Path = $item.path
                        Matches = $item.textMatches
                    }
                }
            }
        }
        catch {
            # 조용히 무시 (권한 없는 repo 등)
        }
    } -ThrottleLimit 10

    # 결과 출력
    if (-not $results -or $results.Count -eq 0) {
        Write-Host "`n검색 결과 없음" -ForegroundColor Yellow
        return
    }

    # 포맷팅 출력
    $currentRepo = $null
    foreach ($result in $results) {
        if ($result.Repo -ne $currentRepo) {
            Write-Host "`n[$($result.Repo)]" -ForegroundColor Cyan
            $currentRepo = $result.Repo
        }

        Write-Host "$($result.Path)" -ForegroundColor Gray

        if ($result.Matches) {
            foreach ($match in $result.Matches) {
                # fragment가 있으면 출력
                if ($match.fragment) {
                    Write-Host "  $($match.fragment)" -ForegroundColor White
                }
            }
        }
    }

    Write-Host "`n총 $($results.Count)개 파일에서 검색됨" -ForegroundColor Green
}

# ===========================
# 4. 메인 함수
# ===========================

function github {
    <#
    .SYNOPSIS
    GitHub 통합 커맨드
    .DESCRIPTION
    gh CLI를 활용하여 repositories를 관리하고 코드를 검색합니다.
    .PARAMETER Command
    실행할 서브커맨드 (search, clone, repos, refresh)
    .PARAMETER Target
    서브커맨드의 대상 (예: clone의 경우 repo 이름, search의 경우 키워드)
    .PARAMETER Path
    clone 시 사용할 경로 (선택적)
    .PARAMETER Detailed
    repos 서브커맨드에서 상세 정보 표시
    .EXAMPLE
    github search "function"
    .EXAMPLE
    github clone owner/repo
    .EXAMPLE
    github repos -Detailed
    .EXAMPLE
    github refresh
    #>
    param(
        [Parameter(Position = 0)]
        [ValidateSet("search", "clone", "repos", "refresh")]
        [string]$Command,

        [Parameter(Position = 1)]
        [string]$Target,

        [Parameter(Position = 2)]
        [string]$Path,

        [switch]$Detailed
    )

    # 커맨드 없이 호출 시 도움말 표시
    if (-not $Command) {
        Write-Host "사용법: github <command> [args]" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Commands:" -ForegroundColor Cyan
        Write-Host "  search <keyword>      - 모든 repositories에서 코드 검색"
        Write-Host "  clone <repo> [path]   - Repository clone"
        Write-Host "  repos [-Detailed]     - Repository 목록 표시"
        Write-Host "  refresh               - 캐시 수동 갱신"
        Write-Host ""
        Write-Host "Examples:" -ForegroundColor Cyan
        Write-Host "  github search `"function`""
        Write-Host "  github clone owner/repo"
        Write-Host "  github clone owner/repo ~/projects/myrepo"
        Write-Host "  github repos"
        Write-Host "  github repos -Detailed"
        Write-Host "  github refresh"
        return
    }

    try {
        switch ($Command) {
            "search" {
                if (-not $Target) {
                    throw "검색 키워드를 입력하세요. 사용법: github search <keyword>"
                }
                Invoke-GithubSearch -Keyword $Target
            }
            "clone" {
                if (-not $Target) {
                    throw "Repository를 지정하세요. 사용법: github clone <owner/repo> [path]"
                }
                Invoke-GithubClone -Repo $Target -Path $Path
            }
            "repos" {
                Invoke-GithubRepos -Detailed:$Detailed
            }
            "refresh" {
                Invoke-GithubRefresh
            }
        }
    }
    catch {
        Write-Host "오류: $_" -ForegroundColor Red
        throw
    }
}

# ===========================
# 5. Tab Completion
# ===========================

Register-ArgumentCompleter -CommandName github -ParameterName Target -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    # clone 커맨드일 때만 repo 목록 제공
    $command = $fakeBoundParameters['Command']
    if ($command -ne 'clone') {
        return
    }

    # 캐시에서 repos 로드 (TTL 무시 - completion은 stale data 허용)
    try {
        $cacheFile = "$HOME/.cache/pwshdev/github-repos.json"
        if (Test-Path $cacheFile) {
            $data = Get-Content $cacheFile -Raw | ConvertFrom-Json
            $repos = $data.data.repos

            $repos |
                Where-Object { $_.fullName -like "$wordToComplete*" } |
                ForEach-Object {
                    $desc = if ($_.isPrivate) { "Private" } else { "Public" }
                    [System.Management.Automation.CompletionResult]::new(
                        $_.fullName,
                        $_.fullName,
                        'ParameterValue',
                        "$($_.fullName) ($desc)"
                    )
                }
        }
    }
    catch {
        # 조용히 무시
    }
}

# ===========================
# 6. Module Export
# ===========================

Export-ModuleMember -Function github
