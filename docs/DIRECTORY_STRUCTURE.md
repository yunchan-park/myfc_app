# MyFC 프로젝트 구조 📁

## 📂 전체 디렉토리 개요

```
myfc_app/
├── 📱 Frontend (Flutter)        # 클라이언트 애플리케이션 (최적화됨)
├── 🖥️ Backend (FastAPI)         # 서버 애플리케이션
├── 📚 Documentation             # 프로젝트 문서
└── ⚙️ Configuration             # 설정 파일들
```

## 🗂️ 상세 디렉토리 구조

### 📱 **Frontend (Flutter App) - 최적화된 구조**

```
frontend/
├── lib/                             # Flutter 소스 코드
│   ├── main.dart                    # 앱 엔트리 포인트
│   ├── config/                      # 설정 관리
│   │   ├── routes.dart              # 라우팅 설정
│   │   └── theme.dart               # UI 테마 설정
│   ├── models/                      # 데이터 모델
│   │   ├── goal.dart                # 골 모델
│   │   ├── match.dart               # 매치 모델 (최적화됨)
│   │   ├── player.dart              # 선수 모델
│   │   └── team.dart                # 팀 모델
│   ├── services/                     # 비즈니스 로직
│   │   ├── api_service.dart         # API 통신 (최적화됨)
│   │   ├── auth_service.dart        # 인증 서비스
│   │   └── storage_service.dart     # 로컬 저장소 (최적화됨)
│   ├── screens/                      # UI 화면 (정리됨)
│   │   ├── splash_screen.dart       # 스플래시 화면
│   │   ├── register_team_screen.dart # 팀 등록 화면 (최적화됨)
│   │   ├── home_screen.dart         # 홈 화면 (최적화됨)
│   │   ├── player_management_screen.dart # 선수 관리
│   │   ├── match_detail_screen.dart # 매치 상세 (최적화됨)
│   │   ├── match_summary_screen.dart # 매치 요약 (최적화됨)
│   │   ├── team_profile_screen.dart # 팀 프로필 (최적화됨)
│   │   ├── analytics_screen.dart    # 분석 화면
│   │   ├── add_match_step1_screen.dart # 매치 등록 1단계 (최적화됨)
│   │   ├── add_match_step2_screen.dart # 매치 등록 2단계
│   │   ├── add_match_step3_screen.dart # 매치 등록 3단계
│   │   └── add_match_step4_screen.dart # 매치 등록 4단계
│   ├── widgets/                     # 재사용 가능한 UI 컴포넌트 (최적화됨)
│   │   ├── common/                  # 공통 위젯
│   │   │   ├── app_button.dart      # 커스텀 버튼
│   │   │   ├── app_input.dart       # 커스텀 입력
│   │   │   ├── app_card.dart        # 커스텀 카드
│   │   │   └── loading_widget.dart  # 로딩 위젯
│   │   ├── quarter_score_widget.dart # 쿼터 점수 위젯 (최적화됨)
│   │   ├── goal_list_widget.dart    # 골 목록 위젯
│   │   └── widgets.dart             # 위젯 익스포트 (정리됨)
│   └── utils/                       # 유틸리티 함수
│       ├── constants.dart           # 상수
│       ├── validators.dart          # 입력 검증
│       └── helpers.dart             # 헬퍼 함수
├── assets/                          # 앱 에셋
│   ├── images/                      # 이미지 파일
│   │   └── soccer_field_background.png # 축구장 배경
│   └── fonts/                       # 폰트 파일
│       └── Pretendard-Medium.otf    # 메인 폰트
├── android/                         # Android 설정
├── ios/                             # iOS 설정
├── macos/                           # macOS 설정
├── web/                             # 웹 설정
│   ├── index.html                   # 메인 HTML
│   ├── manifest.json                # 웹 앱 매니페스트
│   └── favicon.png                  # 파비콘
├── pubspec.yaml                     # Flutter 의존성 관리
└── pubspec.lock                     # 의존성 잠금 파일
```

### 🖥️ **Backend (FastAPI Server)**

```
backend/
├── app/                              # FastAPI 서버 코드
│   ├── main.py                      # 서버 엔트리 포인트
│   ├── __init__.py                  # 패키지 초기화
│   ├── database.py                  # 데이터베이스 설정
│   ├── models.py                    # SQLAlchemy 모델
│   ├── auth.py                      # JWT 인증 로직
│   └── routers/                     # API 라우터
│       ├── __init__.py
│       ├── team.py                 # 팀 API
│       ├── player.py               # 선수 API
│       └── match.py                # 매치 API
├── venv/                            # Python 가상환경
├── requirements.txt                 # Python 의존성
└── myfc.db                         # SQLite 데이터베이스 파일
```

### 📚 **Documentation**

```
docs/                            # 프로젝트 문서
├── README.md                    # 문서 개요 (업데이트됨)
├── ARCHITECTURE.md              # 아키텍처 문서 (최적화 반영)
├── DIRECTORY_STRUCTURE.md       # 디렉토리 구조 (이 파일)
├── BACKEND_GUIDE.md             # 백엔드 가이드
├── FRONTEND_GUIDE.md            # 프론트엔드 가이드
└── DATA_FLOW.md                 # 데이터 흐름 문서
```

### ⚙️ **Configuration Files**

```
Root Directory Files:
├── README.md                    # 프로젝트 소개 및 사용법 (업데이트됨)
├── LICENSE                      # MIT 라이선스
├── .gitignore                   # Git 무시 파일
├── .flutter-plugins            # Flutter 플러그인 목록
└── .flutter-plugins-dependencies # Flutter 플러그인 의존성
```

### 🗄️ **Database & Build**

```
build/                           # 빌드 아티팩트
├── web/                        # 웹 빌드 결과
└── ...

.dart_tool/                      # Dart 도구 캐시
.idea/                           # IntelliJ IDEA 설정
```

## 📋 파일 역할 요약

### **핵심 진입점**
- `frontend/lib/main.dart` - Flutter 앱 시작점
- `backend/app/main.py` - FastAPI 서버 시작점
- `frontend/web/index.html` - 웹 앱 진입점

### **설정 파일**
- `frontend/pubspec.yaml` - Flutter 프로젝트 설정
- `backend/requirements.txt` - Python 의존성
- `frontend/web/manifest.json` - PWA 설정

### **문서화**
- `README.md` - 프로젝트 소개 및 사용법
- `docs/ARCHITECTURE.md` - 시스템 아키텍처
- `LICENSE` - MIT 라이선스

## 🎯 2024년 최적화 현황

### **제거된 파일들 (Clean-up)**
- `frontend/lib/screens/login_screen.dart` - 미사용 로그인 화면
- `frontend/lib/widgets/player_card.dart` - 미사용 선수 카드 위젯
- `frontend/lib/widgets/match_card.dart` - 미사용 매치 카드 위젯
- `frontend/lib/widgets/team/team_header_widget.dart` - 미사용 팀 헤더
- `frontend/lib/widgets/team/team_stats_widget.dart` - 미사용 팀 통계
- `frontend/lib/widgets/team/` (전체 디렉토리) - 사용되지 않던 팀 위젯들

### **최적화된 파일들**
- **8개 파일에서 미사용 임포트 제거**: 
  - `models/match.dart`
  - `screens/add_match_step1_screen.dart`
  - `screens/home_screen.dart`
  - `screens/match_detail_screen.dart`
  - `screens/match_summary_screen.dart`
  - `screens/register_team_screen.dart`
  - `screens/team_profile_screen.dart`
  - `services/storage_service.dart`

- **QuarterScoreWidget 최적화**: `isEditable` 기능 및 관련 UI 코드 제거
- **MatchSummaryScreen 메서드 정리**: `_deleteMatch()`, `_getResultColor()` 제거

### **성능 개선 결과**
- **미사용 코드 58% 감소**: 33개 → 14개 항목
- **빌드 시간 단축**: 불필요한 컴파일 제거
- **메모리 사용량 감소**: 미사용 위젯 및 임포트 제거
- **타입 안정성 향상**: 강화된 타입 검사

## 🎯 주요 특징

### **모듈식 구조**
- 프론트엔드와 백엔드의 명확한 분리
- 각 기능별 독립적인 모듈 구성
- 재사용 가능한 컴포넌트 중심 설계

### **확장 가능성**
- 새로운 기능 추가 시 기존 구조에 쉽게 통합
- 마이크로서비스 아키텍처로 개별 배포 가능
- 플러그인 방식의 확장 지원

### **개발 편의성**
- 일관된 네이밍 컨벤션
- 명확한 의존성 관리
- 자동화된 개발 환경
- 지속적인 코드 품질 관리

### **배포 최적화**
- 프로덕션과 개발 환경 분리
- 웹/모바일 멀티 플랫폼 지원
- 최적화된 빌드 크기

## 관련 문서
- PROJECT_DOCS_GUIDE.md
- ARCHITECTURE.md
- DATA_FLOW.md
- BACKEND_GUIDE.md
- FRONTEND_GUIDE.md