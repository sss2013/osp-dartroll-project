├── lib/
│   ├── src/
│   │   ├── core/                    # 앱 전체에서 사용하는 핵심 기능
│   │   │   ├── constants/           # 전역 상수(API 경로,앱 이름 등)정의
│   │   │       ├── api_endpoints.dart # 서버에게 API 요청을 보낼 엔드포인트
│   │   │   ├── errors/              # 커스텀 에러 클래스
│   │   │   ├── network/             # API 클라이언트, 인터셉터, 네트워크 예외 처리
│   │   │   ├── utils/               # 유틸리티 함수들 (포맷터, Validators)
│   │   │   └── extensions/          # Dart 확장 메서드
│   │   │   └── config/     
│   │   │       |── routes/          # 화면 네비게이션(Router)
│   │   │       |── app_config.dart  # 환경(flavor) 별 서버 URL 등 전역 설정
│   │   │
│   │   ├── features/                # 기능별 모듈화
│   │   │   ├── authentication/      # 로그인/인증 기능
│   │   │   │   ├── data/                
│   │   │   │   │   ├── datasources/  
│   │   │   │   │   ├── models/      
│   │   │   │   │   └── repositories/
│   │   │   │   ├── domain/
│   │   │   │   │   ├── entities/    # 엔티티 (CRUD 요청 시 사용할 데이터의 구조)
│   │   │   │   │   ├── repositories/
│   │   │   │   │   └── usecases/
│   │   │   │   └── presentation/
│   │   │   │       ├── pages/
│   │   │   │       ├── widgets/
│   │   │   │       └── bloc/        # 상태 관리
│   │   │   │
│   │   │   ├── events/              # 이벤트 정보 관련 기능
│   │   │   ├── community/           # 커뮤니티 기능
│   │   │   ├── chat/                # 채팅 기능
│   │   │   └── profile/             # 사용자 프로필 관리
│   │   │
│   │   ├── shared/                  # 공통으로 사용되는 컴포넌트
│   │   │   ├── widgets/             # 재사용 가능한 위젯
│   │   │   ├── services/            # 공통 서비스
│   │   │   ├── models/              # 공통 데이터 모델
│   │   │   └── theme/               # 앱 테마 설정
│   │   │
│   │   │
│   │   └── l10n/                    # 다국어 지원
│   │
│   └── main.dart
│
├── assets/                          # 정적 리소스
│   ├── images/                      # 아이콘,로고,일러스트 등 이미지 리소스
│   │   ├── icons/
│   │   ├── logos/                   
│   │   └── illustrations/
│   ├── fonts/                       # 커스텀 폰트 파일
│   └── data/                        # 로컬 데이터 파일
│
├── test/                           # 테스트 파일
│   ├── unit/                       # 단위 테스트
│   ├── widget/                     # 위젯 테스트
│   └── integration/                # 통합 테스트 코드
│
├── docs/                           # 프로젝트 문서화
│   ├── README.md                   # 프로젝트 개요,설치,실행 방법
│   ├── CONTRIBUTING.md             # 협업(기여) 가이드라
│   ├── architecture.md             # 전체 아키텍처 설명
│   └── api_documentation.md        # 백엔드 API 명세
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
├── pubspec.yaml                   # 의존성 관리
├── pubspec.lock
├── .gitignore
└── README.md


```dart
// 1. lib/src/core/ - 앱의 핵심 인프라

// lib/src/core/constants/app_constants.dart
class AppConstants {
  static const String appName = 'EventMatcher';
  static const String baseUrl = 'https://api.eventmatcher.com';
  static const Duration cacheExpiration = Duration(hours: 1);
}

// lib/src/core/network/api_client.dart
class ApiClient {
  static final Dio _dio = Dio();
  
  static Dio get instance => _dio;
}

// lib/src/core/utils/validators.dart
class Validators {
  static String? validateEmail(String? email) {
    // 이메일 유효성 검사 로직
  }
}

// 2. lib/src/features/ - 기능별 모듈화
// Clean Architecture 패턴 적용:
// Data Layer: API 호출, 로컬 저장소 관리 
// Domain Layer: 비즈니스 로직, 엔티티 정의 
// Presentation Layer: UI 컴포넌트, 상태 관리

// lib/src/features/events/domain/entities/event.dart
class Event {
  final String id;
  final String title;
  final DateTime startDate;
  final String location;
  
  Event({
    required this.id,
    required this.title,
    required this.startDate,
    required this.location,
  });
}

// lib/src/features/events/presentation/bloc/events_bloc.dart
class EventsBloc extends Bloc<EventsEvent, EventsState> {
  // 이벤트 상태 관리 로직
}

// 3. lib/src/shared/ - 공통 컴포넌트

// lib/src/shared/widgets/custom_button.dart
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  
  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
  }) : super(key: key);
}

// lib/src/shared/services/location_service.dart
class LocationService {
  static Future<Position> getCurrentLocation() async {
    // 위치 서비스 로직
  }
}
```