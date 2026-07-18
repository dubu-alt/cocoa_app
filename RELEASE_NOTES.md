# Apple Silicon 지원 릴리스

macOS Tahoe(26) 이후 Intel 전용 앱에 대해 "이후 버전의 macOS에서는 실행되지 않습니다" 경고가 표시되는 문제를 해결한 릴리스입니다.

## 주요 변경 사항

- **Apple Silicon(arm64) 네이티브 지원**: 두 앱 모두 arm64 + x86_64 유니버설 바이너리로 빌드되어 Apple Silicon Mac에서 Rosetta 없이 네이티브로 실행됩니다.
- **최소 지원 버전 상향**: macOS 11.0 (Big Sur) 이상
- **README.md 추가**: 앱 소개, 사용 방법, 빌드 방법 문서화

## 포함된 앱

| 앱 | 버전 | 설명 |
|---|---|---|
| Contact | 2.1 | 한글 파일명 자소 분리(NFD → NFC) 변환 스크립트 생성기 |
| HoursContentCopier | 1.5.2 | Hours 타임트래킹 기록 조회 및 복사 도구 |

## 설치 방법

1. 아래 자산(Assets)에서 zip 파일을 다운로드합니다.
2. 압축을 풀고 `.app`을 응용 프로그램 폴더로 옮깁니다.
3. 처음 실행 시 macOS 보안 경고가 뜨면: **시스템 설정 → 개인정보 보호 및 보안**에서 "그래도 열기"를 선택합니다.

## 요구 사항

- macOS 11.0 (Big Sur) 이상
- Apple Silicon / Intel Mac 모두 지원
