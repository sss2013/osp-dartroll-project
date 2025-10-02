# EventMatcher Mobile App

## 프로젝트 구조
- `lib/src/features/`: 기능별 모듈
- `lib/src/shared/`: 공통 컴포넌트
- `lib/src/core/`: 핵심 유틸리티

## 개발 환경 설정
1. Flutter SDK 설치
2. 의존성 설치: `flutter pub get`

## 브랜치 전략
- `main`: 프로덕션 브랜치
- `develop`: 개발 브랜치
- `feature/*`: 기능 개발 브랜치

## 파일명: snake_case
user_profile_page.dart
event_list_widget.dart

## 클래스명: PascalCase
class UserProfilePage extends StatelessWidget {}

## 변수명: camelCase
String userName = '';
DateTime eventStartDate = DateTime.now();