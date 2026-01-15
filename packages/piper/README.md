각종 편의 기능들을 넣은 pwsh 프레임워크

```pwsh
Import-Module Piper.Core
Import-Module Piper.Cache
Import-Module Piper.Config

$cache = [Piper.Cache]::new()
$a = 2
```