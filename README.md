# :musical_note: 컬쳐요(Cultureyo)

컬쳐요(Cultureyo)는 **다양한 장르의 전국 공연정보 통합 제공과 맞춤형 동행자 매칭 서비스를 제공하는 크로스플랫폼 모바일 애플리케이션**입니다. 

사용자는 지역/장르 필터를 통한 사용자 친화적 탐색을 기반으로 공연 정보를 탐색 할 수 있고, 게시판 및 1:1 채팅 기능을 통해 공연 동행자를 구하여 공연 경험을 확장할 수 있습니다.

본 프로젝트는 Flutter를 활용하였으며 **Android와 iOS를 동시에 지원**합니다.

## 🤖 주요 기능
- **소셜 로그인**
<img src = "https://github.com/user-attachments/assets/5847fe73-c1d0-4f72-bd17-63a0550e4260" width="200" height="400">

사용자는 카카오톡, 네이버 두 가지 종류의 소셜 로그인 기능을 사용하여 로그인할 수 있습니다.
- **지역/장르 기반 공연정보 탐색**
<img src = "https://github.com/user-attachments/assets/6b54f5f9-57c3-4525-8833-e4915de613bb" width="200" height="400">
<img src = "https://github.com/user-attachments/assets/cf56b560-5983-4c25-828d-dac1b896bce2" width="200" height="400">
<img src = "https://github.com/user-attachments/assets/e9fce456-a2cd-4b10-91d1-dca6435fa746" width="200" height="400">

사용자는 지역과 장르 필터 선택을 통해 원하는 공연을 빠르게 탐색할 수 있습니다.
- **커뮤니티 기능 (리뷰 게시판 / 친구 찾기 게시판)**
<img src = "https://github.com/user-attachments/assets/809ff8ce-4b77-4270-866f-30261887946e" width="200" height="400">
<img src = "https://github.com/user-attachments/assets/e657062f-ebcb-4dca-b128-17681c2b9192" width="200" height="400">
<img src = "https://github.com/user-attachments/assets/03c060b8-8f16-46bd-9e98-69c3dbb71a8d" width="200" height="400">

사용자는 게시판 페이지를 통해 게시글이나 댓글 작성/삭제 등의 기본적인 커뮤니티 기능을 사용할 수 있습니다.

- **사용자 간 1:1 채팅**
<img src = "https://github.com/user-attachments/assets/48074947-3bce-4645-86cb-36e0a1e6dd1a" width="200" height="400">
<img src = "https://github.com/user-attachments/assets/c9ec636b-ea29-4615-8a5a-b314462c0174" width="200" height="400">

사용자는 게시물 상세 페이지의 작성자 아이콘을 통해 다른 사용자의 프로필에 접근, 1:1 채팅 기능을 사용할 수 있습니다.

- **회원 탈퇴**
<img src = "https://github.com/user-attachments/assets/e2010156-97f0-4d87-8d8e-088e9a6f5ebc" width="200" height="400">
<img src = "https://github.com/user-attachments/assets/01e6d4bb-0bbd-4600-95ca-cfc74c741649" width="200" height="400">
<img src = "https://github.com/user-attachments/assets/7aef78e6-2d0a-4d37-9aaa-782826fc0989" width="200" height="400">

사용자는 더 이상 서비스 이용을 원하지 않을 경우 하단바의 내 정보 탭 내부의 회원 탈퇴 기능을 통해 안전하게 회원 정보를 삭제할 수 있습니다. 

## ✍ 개발 환경
### Frontend
- **Flutter** 
- **Dart**

### Backend
- **Node.js** (서버)
- **Render** (서버 배포)

### Database
- **Redis** : 공연 정보 관리
- **Supabase** : 사용자 정보 관리
- **MongoDB** : 게시글 및 채팅 데이터 관리

### :family: 협업 Tool
- Discord, Notion, KaKaoTalk, Github
  

## :sunglasses: 팀 구성 및 역할
- **신성수(팀장, 백엔드 담당)** - 로그인 기능, 서버, DB, 공연 정보 API 구현 

- **이상엽(팀원, 프론트엔드 담당)** - 메인화면, 공연 탐색 기능, 마이페이지 UI 구현
 
- **김민욱(팀원, 프론트엔드 담당)** - 채팅 페이지 UI, 백엔드 지원 업무(게시판 API 구현)
 
- **최형서(팀원, 프론트엔드 담당)** - 게시판 기능, 로그인 화면 UI 구현

## 🚀 개발 기간
- **2025. 09. 04 ~ 2025. 12. 10**

## 😓 한계점 / 향후 개선 방안
- 게시판 CRUD 기능 수행 후 새로고침이 필요한 구조
- 알림 기능 미구현
- 낯선 사용자와 채팅 시 경고 문구 표시 기능 미구현

:point_right: 향후 논의와 개선을 통해 사용자 경험을 지속적으로 향상 시키겠습니다.
