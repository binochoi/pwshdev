# Piper.Cache 모듈 설계

## 개요

PowerShell용 파일 기반 캐시 모듈. JSON 형식으로 데이터를 저장하며 TTL(Time-To-Live) 기능을 지원합니다.

## 요구사항

- 모듈 이름: `Piper.Cache`
- 기본 저장 경로: `~/.cache/pwsh-piper/cache`
- 저장 형식: JSON (키당 하나의 `.json` 파일)
- 지원 기능: get, set, remove, clear, has, TTL

## 아키텍처

### 클래스 구조

단일 `Cache` 클래스로 구현:

```powershell
class Cache {
    [string]$CachePath          # 사용자 지정 캐시 경로
    hidden [string]$_resolvedPath  # 내부 절대 경로
}
```

### 생성자

두 가지 생성자를 제공:

1. **기본 생성자**: `[Piper.Cache]::new()`
   - 기본 경로 사용: `~/.cache/pwsh-piper/cache`

2. **옵션 생성자**: `[Piper.Cache]::new(@{CachePath='...'})`
   - 해시테이블로 옵션 전달
   - 현재 지원: `CachePath` (향후 확장 가능)

### 데이터 형식

각 캐시 항목은 다음 JSON 구조로 저장:

```json
{
  "data": <실제 데이터>,
  "expiresAt": "2026-01-16T12:00:00.0000000+09:00"  // 선택적
}
```

- `data`: 사용자가 저장한 실제 값 (string, number, hashtable 등)
- `expiresAt`: TTL이 설정된 경우 만료 시간 (ISO 8601 형식)

### 파일명 규칙

- 키 `'name'` → 파일 `name.json`
- 특수문자나 경로 구분자는 지원하지 않음 (단순 키만 허용)

## 메서드 상세

### Set(key, value, [ttlSeconds])

캐시에 데이터를 저장합니다.

**시그니처:**
```powershell
[void] Set([string]$key, [object]$value)
[void] Set([string]$key, [object]$value, [int]$ttlSeconds)
```

**동작:**
1. `$key.json` 파일 경로 생성
2. 데이터를 `{ "data": value }` 구조로 래핑
3. TTL이 지정되면 `expiresAt` 필드 추가
4. JSON으로 직렬화하여 파일에 저장

**예제:**
```powershell
$cache.Set('user', @{name='John'; age=30})
$cache.Set('session', 'abc123', 3600)  # 1시간 TTL
```

### Get(key)

캐시에서 데이터를 읽습니다.

**시그니처:**
```powershell
[object] Get([string]$key)
```

**동작:**
1. `$key.json` 파일 존재 확인
2. 파일이 없으면 `$null` 반환
3. JSON 파싱 시도 (실패 시 파일 삭제 후 `$null` 반환)
4. TTL 확인 (만료되었으면 파일 삭제 후 `$null` 반환)
5. `data` 필드 값 반환

**예제:**
```powershell
$user = $cache.Get('user')
if ($null -ne $user) {
    Write-Host $user.name
}
```

### Remove(key)

특정 캐시 항목을 삭제합니다.

**시그니처:**
```powershell
[void] Remove([string]$key)
```

**동작:**
- 해당 키의 JSON 파일을 삭제
- 파일이 없어도 에러 없음

**예제:**
```powershell
$cache.Remove('session')
```

### Clear()

모든 캐시 항목을 삭제합니다.

**시그니처:**
```powershell
[void] Clear()
```

**동작:**
- 캐시 디렉토리의 모든 `.json` 파일 삭제
- 디렉토리 자체는 유지

**예제:**
```powershell
$cache.Clear()
```

### Has(key)

캐시에 키가 존재하는지 확인합니다.

**시그니처:**
```powershell
[bool] Has([string]$key)
```

**동작:**
- 내부적으로 `Get(key)`를 호출
- 결과가 `$null`이 아니면 `$true` 반환
- TTL 만료도 체크됨

**예제:**
```powershell
if ($cache.Has('user')) {
    # 캐시 사용
} else {
    # 새로 조회
}
```

## TTL (Time-To-Live)

### 만료 처리 전략

**Lazy Cleanup 방식:**
- `Get()` 호출 시에만 만료 여부 확인
- 만료된 항목은 즉시 파일 삭제 후 `$null` 반환
- 백그라운드 정리 작업 없음 (단순하고 효율적)

### TTL 설정 방법

```powershell
# 1시간 TTL
$cache.Set('temp', $data, 3600)

# TTL 없음 (영구 저장)
$cache.Set('config', $data)
```

### 만료 시간 형식

- ISO 8601 형식으로 저장: `2026-01-16T12:00:00.0000000+09:00`
- PowerShell의 `[DateTime]::Parse()`로 파싱
- 시스템 로컬 타임존 사용

## 에러 처리

### 원칙

**모든 에러는 조용히 처리하고 `$null` 반환:**
- 파일이 없음 → `$null`
- JSON 파싱 실패 → 파일 삭제 후 `$null`
- TTL 만료 → 파일 삭제 후 `$null`
- 파일 시스템 권한 에러 → `$null`

### 근거

- PowerShell 관례에 부합 (cmdlet들도 주로 `$null` 반환)
- 사용자가 간단한 null 체크로 처리 가능
- try-catch 강제하지 않아 사용성 좋음

## 파일 시스템 구조

```
~/.cache/pwsh-piper/cache/
├── user.json          # { "data": {...} }
├── session.json       # { "data": "abc123", "expiresAt": "..." }
└── config.json        # { "data": {...} }
```

## 제약사항

1. **키 이름**: 파일명으로 사용 가능한 문자만 허용
   - `/`, `\`, `:` 등 경로 구분자 불가
   - 계층적 캐시 구조 미지원

2. **동시성**: 파일 잠금 미지원
   - 단일 프로세스 사용 가정
   - 멀티 프로세스 환경에서는 race condition 가능

3. **용량**: 디스크 용량 제한 없음
   - 사용자가 직접 관리 필요
   - `Clear()` 또는 수동 삭제

4. **성능**:
   - 모든 I/O는 동기식
   - 대량 데이터나 고빈도 액세스에는 부적합

## 구현 파일 구조

```
packages/piper/modules/cache/
└── Piper.Cache.psm1    # 단일 파일에 모든 구현
```

## 사용 예제

```powershell
# 모듈 임포트
Import-Module Piper.Cache

# 기본 사용
$cache = [Piper.Cache]::new()
$cache.Set('user', @{name='John'; age=30})
$user = $cache.Get('user')

# 커스텀 경로
$cache = [Piper.Cache]::new(@{CachePath='./my-cache'})

# TTL 사용
$cache.Set('session', 'token123', 3600)  # 1시간
Start-Sleep -Seconds 3601
$session = $cache.Get('session')  # $null (만료됨)

# 조건부 사용
if (-not $cache.Has('expensive-data')) {
    $data = Get-ExpensiveData
    $cache.Set('expensive-data', $data, 300)  # 5분
}
$data = $cache.Get('expensive-data')

# 정리
$cache.Remove('session')
$cache.Clear()
```

## 향후 확장 가능성

현재 설계는 단순하지만 필요시 다음을 추가할 수 있습니다:

- 자동 cleanup 메서드
- 캐시 통계 (hit/miss rate)
- 최대 캐시 크기 제한
- 키 네임스페이스 (폴더 구조)
- 압축 지원
- 메모리 캐시 레이어

하지만 **YAGNI 원칙**에 따라 필요할 때 추가합니다.
