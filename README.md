# cocoa_app

macOS용 Cocoa 유틸리티 앱입니다. Swift로 작성되었으며, **Apple Silicon(arm64) + Intel(x86_64) 유니버설 바이너리**로 빌드됩니다.

## 앱 소개

### Contact (v2.3)

한글 파일명의 **자소 분리(NFD)** 문제를 해결해주는 앱입니다.

macOS에서 파일명을 저장할 때 한글이 자소 단위(ㅎㅏㄴㄱㅡㄹ)로 분리되는 NFD 방식이 사용되어, Windows나 다른 시스템으로 파일을 옮기면 파일명이 깨져 보이는 문제가 있습니다. Contact는 파일이나 폴더를 드래그 앤 드롭하면 파일명을 완성형(NFC)으로 즉시 변환해줍니다.

**사용 방법**

1. 앱을 실행하고 변환할 파일 또는 폴더를 창에 드래그 앤 드롭합니다 (열기 버튼으로 선택도 가능).
2. "Done!"이 표시되면 변환 완료입니다. 내부적으로 `mv` 기반 변환 스크립트를 생성해 자동 실행합니다.

폴더를 드롭하면 하위 항목까지 재귀적으로 처리하며, `.DS_Store` 같은 숨김 파일과 `.app` 번들 내부는 제외됩니다.

**참고**: 변환 후에도 Gmail 등 웹 브라우저 업로드로 파일을 보내면 macOS가 업로드 과정에서 파일명을 다시 NFD로 분해하는 경우가 있습니다. 이때는 zip으로 묶어 전송하세요 (`ditto -c -k 폴더명 파일명.zip`).

## 다운로드

빌드 없이 바로 사용하려면 [Releases](https://github.com/dubu-alt/cocoa_app/releases) 페이지에서 최신 버전의 zip 파일을 다운로드하세요.

## 요구 사항

- macOS 11.0 (Big Sur) 이상
- Apple Silicon 및 Intel Mac 모두 지원 (유니버설 바이너리)

## 빌드 방법

Xcode에서 `Contact/Contact.xcodeproj`를 열어 빌드(⌘B)하거나, 터미널에서:

```bash
cd Contact
xcodebuild -scheme Contact -configuration Release build
```

빌드된 바이너리의 아키텍처는 아래 명령으로 확인할 수 있습니다. `arm64 x86_64`가 출력되면 유니버설 바이너리입니다.

```bash
lipo -archs Contact.app/Contents/MacOS/Contact
```

## 프로젝트 구조

```
cocoa_app/
└── Contact/                  # 한글 파일명 NFC 변환기
    ├── Contact/              # 앱 소스 (드래그 앤 드롭, NFC 변환, 다이얼로그)
    ├── ContactTests/         # 단위 테스트
    └── ContactUITests/       # UI 테스트
```

## 변경 이력

### Contact 2.3

- **NFC 변환이 실제로 동작하지 않던 문제 근본 수정**: FileManager 등 Foundation API가 경로를 `fileSystemRepresentation`으로 변환하며 파일명을 다시 NFD로 분해하는 문제를 우회하기 위해, POSIX `rename()` 시스템 호출로 UTF-8 바이트를 그대로 전달하도록 변경
- APFS가 NFD/NFC 이름을 같은 파일로 취급하는 문제는 임시 이름을 거치는 2단계 변경으로 해결
- 외부 셸(/bin/sh) 실행 방식을 앱 내 직접 변환으로 교체하고, 드래그 앤 드롭 URL 읽기를 정식 API(`readObjects`)로 교체
- 변환/실패 개수를 화면에 표시하고, 실패 시 원인을 다이얼로그로 안내
- 이미 완성형(NFC)인 파일명은 건너뛰도록 개선

### 공통 (2026-07)

- Apple Silicon(arm64) + Intel(x86_64) 유니버설 바이너리 지원
- 최소 지원 버전을 macOS 11.0으로 상향

## 라이선스

[MIT License](LICENSE)
