# EventMatcher Mobile App

### 1. 프로젝트 구조
- `lib/src/features/`: 기능별 모듈
- `lib/src/shared/`: 공통 컴포넌트
- `lib/src/core/`: 핵심 유틸리티

## 개발 환경 설정
의존성 설치: `flutter pub get`

## 파일명: snake_case
user_profile_page.dart
event_list_widget.dart

## 클래스명: PascalCase
class UserProfilePage extends StatelessWidget {}

## 변수명: camelCase
String userName = '';
DateTime eventStartDate = DateTime.now();


### 2. Git 규칙

### 1) Branch (git flow)

git branch는 다음과 보통 다음과 같이 있다 - main, develop, feature, (release, hotfixes)

- main: 배포본
- develop : 배포본 이전본, 총 통합 브랜치 역할
- feature/기능명 : 기능ex) feature/login, feature/main

1. 개인이 맡은 기능(feature) 브랜치에서 작업하고,
2. 해당 기능이 완성 됐으면 develop 브랜치에 올린다.
3. develop에 모든 기능들이 모이고 문제 없이 정상적으로 작동하면
4. main 브랜치(배포본)에 올린다.

### 2) Commit 컨벤션

feat : 새로운 기능 추가

- fix : 기능 수정
- style : 스타일 관련
- refactor : 코드 리펙토링
