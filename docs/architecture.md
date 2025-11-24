//폴더 구조

your_app_name/
├── lib/
│   ├── src/
│   │   ├── core/                    # 앱 전체에서 사용하는 핵심 기능
│   │   │   ├── constants/           # 상수 값들
│   │   │   ├── errors/              # 커스텀 에러 클래스
│   │   │   ├── network/             # API 클라이언트, 인터셉터 
│   │   │   ├── utils/               # 유틸리티 함수들
│   │   │   └── extensions/          # Dart 확장 메서드
│   │   │
│   │   ├── features/                # 기능별 모듈화
│   │   │   ├── authentication/      # 로그인/인증 기능
│   │   │   │   ├── data/
│   │   │   │   │   ├── datasources/
│   │   │   │   │   ├── models/
│   │   │   │   │   └── repositories/
│   │   │   │   ├── domain/
│   │   │   │   │   ├── entities/
│   │   │   │   │   ├── repositories/
│   │   │   │   │   └── usecases/
│   │   │   │   └── presentation/
│   │   │   │       ├── pages/
│   │   │   │       ├── widgets/
│   │   │   │       └── bloc/        # 상태 관리
│   │   │   │
│   │   │   ├── events/              # 이벤트 관련 기능
│   │   │   ├── community/           # 커뮤니티 기능
│   │   │   ├── chat/                # 채팅 기능
│   │   │   └── profile/             # 프로필 관리
│   │   │
│   │   ├── shared/                  # 공통으로 사용되는 컴포넌트
│   │   │   ├── widgets/             # 재사용 가능한 위젯
│   │   │   ├── services/            # 공통 서비스
│   │   │   ├── models/              # 공통 데이터 모델
│   │   │   └── theme/               # 앱 테마 설정
│   │   │
│   │   ├── config/                  # 앱 설정
│   │   │   ├── routes/              # 라우팅 설정
│   │   │   ├── env/                 # 환경 변수
│   │   │   └── app_config.dart      # 앱 전역 설정
│   │   │
│   │   └── l10n/                    # 다국어 지원
│   │
│   └── main.dart
│
├── assets/                          # 정적 리소스
│   ├── images/
│   │   ├── icons/
│   │   ├── logos/
│   │   └── illustrations/
│   ├── fonts/
│   └── data/                        # 로컬 데이터 파일
│
├── test/                           # 테스트 파일
│   ├── unit/
│   ├── widget/
│   └── integration/
│
├── docs/                           # 프로젝트 문서화
│   ├── README.md
│   ├── CONTRIBUTING.md
│   ├── architecture.md
│   └── api_documentation.md
│
├── scripts/                        # 빌드 및 배포 스크립트
│   ├── build.sh
│   └── deploy.sh
│
├── .github/                        # GitHub 설정
│   ├── workflows/                  # CI/CD 파이프라인
│   │   ├── test.yml
│   │   └── deploy.yml
│   ├── ISSUE_TEMPLATE/
│   └── pull_request_template.md
│
├── analysis_options.yaml          # 린트 규칙
├── pubspec.yaml
├── pubspec.lock
├── .gitignore
├── .env.example                   # 환경 변수 예제
└── README.md