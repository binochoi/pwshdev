class Cache {
    [string]$CachePath
    hidden [string]$_resolvedPath

    # 기본 생성자
    Cache() {
        $this.CachePath = '~/.cache/pwsh-piper/cache'
        $this.Initialize()
    }

    # 옵션을 받는 생성자
    Cache([hashtable]$options) {
        if ($options.CachePath) {
            $this.CachePath = $options.CachePath
        } else {
            $this.CachePath = '~/.cache/pwsh-piper/cache'
        }
        $this.Initialize()
    }

    # 초기화 메서드
    hidden [void] Initialize() {
        # 틸드 경로를 절대 경로로 변환
        $path = $this.CachePath
        if ($path.StartsWith('~')) {
            $path = $path.Replace('~', [System.Environment]::GetFolderPath('UserProfile'))
        }
        $this._resolvedPath = [System.IO.Path]::GetFullPath($path)

        # 캐시 디렉토리가 없으면 생성
        if (-not (Test-Path $this._resolvedPath)) {
            New-Item -ItemType Directory -Path $this._resolvedPath -Force | Out-Null
        }
    }

    # Set 메서드 (TTL 없음)
    [void] Set([string]$key, [object]$value) {
        $this.Set($key, $value, $null)
    }

    # Set 메서드 (TTL 있음)
    [void] Set([string]$key, [object]$value, [object]$ttlSeconds) {
        $filePath = Join-Path $this._resolvedPath "$key.json"

        # 데이터 구조 생성
        $cacheData = @{
            data = $value
        }

        # TTL이 지정되었으면 만료 시간 추가
        if ($null -ne $ttlSeconds -and $ttlSeconds -gt 0) {
            $expiresAt = (Get-Date).AddSeconds($ttlSeconds).ToString('o')
            $cacheData['expiresAt'] = $expiresAt
        }

        # JSON으로 변환하여 저장
        try {
            $json = $cacheData | ConvertTo-Json -Depth 10 -Compress
            Set-Content -Path $filePath -Value $json -Encoding UTF8 -ErrorAction Stop
        }
        catch {
            # 에러 발생 시 조용히 무시
        }
    }

    # Get 메서드
    [object] Get([string]$key) {
        $filePath = Join-Path $this._resolvedPath "$key.json"

        # 파일이 없으면 $null 반환
        if (-not (Test-Path $filePath)) {
            return $null
        }

        # JSON 파일 읽기 및 파싱
        try {
            $content = Get-Content -Path $filePath -Raw -Encoding UTF8 -ErrorAction Stop
            $cacheData = $content | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            # 잘못된 JSON이면 파일 삭제 후 $null 반환
            try {
                Remove-Item -Path $filePath -Force -ErrorAction SilentlyContinue
            }
            catch {
                # 삭제 실패해도 무시
            }
            return $null
        }

        # TTL 확인
        if ($cacheData.PSObject.Properties.Name -contains 'expiresAt') {
            try {
                $expiresAt = [DateTime]::Parse($cacheData.expiresAt)
                if ((Get-Date) -gt $expiresAt) {
                    # 만료되었으면 파일 삭제 후 $null 반환
                    try {
                        Remove-Item -Path $filePath -Force -ErrorAction SilentlyContinue
                    }
                    catch {
                        # 삭제 실패해도 무시
                    }
                    return $null
                }
            }
            catch {
                # 날짜 파싱 실패 시 파일 삭제 후 $null 반환
                try {
                    Remove-Item -Path $filePath -Force -ErrorAction SilentlyContinue
                }
                catch {
                    # 삭제 실패해도 무시
                }
                return $null
            }
        }

        # 데이터 반환
        return $cacheData.data
    }

    # Remove 메서드
    [void] Remove([string]$key) {
        $filePath = Join-Path $this._resolvedPath "$key.json"
        if (Test-Path $filePath) {
            try {
                Remove-Item -Path $filePath -Force -ErrorAction Stop
            }
            catch {
                # 삭제 실패해도 무시
            }
        }
    }

    # Clear 메서드
    [void] Clear() {
        if (Test-Path $this._resolvedPath) {
            try {
                $files = Get-ChildItem -Path $this._resolvedPath -Filter "*.json" -ErrorAction SilentlyContinue
                foreach ($file in $files) {
                    Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
                }
            }
            catch {
                # 에러 발생해도 무시
            }
        }
    }

    # Has 메서드
    [bool] Has([string]$key) {
        $value = $this.Get($key)
        return $null -ne $value
    }
}

# 클래스를 Export
Export-ModuleMember -Variable * -Function * -Alias *
