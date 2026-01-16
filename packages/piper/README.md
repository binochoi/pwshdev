각종 편의 기능들을 넣은 pwsh 프레임워크

## 모듈

### Piper.Cache

파일 기반 캐시 모듈 with TTL 지원

```pwsh
using module Piper.Cache

# 기본 사용
$cache = [Cache]::new()
$cache.Set('user', @{name='John'; age=30})
$user = $cache.Get('user')

# TTL 사용 (초 단위)
$cache.Set('session', 'token123', 3600)  # 1시간

# 기타 메서드
$cache.Has('user')        # 키 존재 확인
$cache.Remove('user')     # 개별 삭제
$cache.Clear()            # 전체 삭제

# 커스텀 경로
$cache = [Cache]::new(@{CachePath='./my-cache'})
```

### Piper.Core

(개발 예정)

### Piper.Config

(개발 예정)