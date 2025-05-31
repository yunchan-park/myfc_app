# MyFC - 축구 클럽 관리 시스템

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![MIT License](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 📖 프로젝트 개요

MyFC는 축구 클럽의 효율적인 관리를 위한 현대적인 모바일/웹 애플리케이션입니다. Flutter와 FastAPI를 기반으로 구축된 풀스택 솔루션으로, 팀 관리, 선수 관리, 경기 기록, 통계 분석 등 축구 클럽 운영에 필요한 모든 기능을 제공합니다.

## 🏗️ 시스템 아키텍처

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │────│   FastAPI       │────│   SQLite DB     │
│   (Frontend)    │    │   (Backend)     │    │   (Database)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 프론트엔드 (Flutter)
- **크로스 플랫폼**: iOS, Android, 웹 지원
- **반응형 UI**: 모든 화면 크기에 최적화
- **오프라인 지원**: 로컬 캐싱으로 네트워크 없이도 사용 가능
- **한국어 최적화**: 직관적인 한국어 UI
- **최적화된 코드베이스**: 사용하지 않는 코드 제거로 성능 향상

### 백엔드 (FastAPI)
- **RESTful API**: 명확한 엔드포인트 설계
- **JWT 인증**: 안전한 토큰 기반 인증
- **자동 API 문서**: Swagger/OpenAPI 지원
- **높은 성능**: 비동기 처리로 빠른 응답

## 🚀 빠른 시작

### 시스템 요구사항
- **Python**: 3.9+
- **Flutter**: 3.16.0+
- **Git**: 최신 버전

### 1. 저장소 복제
```bash
git clone https://github.com/yunchan-park/myfc_app.git
cd myfc_app
```

### 2. 백엔드 설정 및 실행
```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 3. 프론트엔드 설정 및 실행
```bash
cd ../frontend
flutter pub get
flutter run -d chrome  # 웹에서 실행
# 또는
flutter run  # 연결된 모바일 기기에서 실행
```

## 🎯 주요 기능

### ✅ 구현 완료
- **팀 관리**: 팀 생성, 로그인, 프로필 관리, 팀 정보 수정
- **선수 관리**: 선수 등록, 수정, 삭제, 통계 관리, 포지션별 관리
- **경기 관리**: 경기 등록, 쿼터별 점수, 골 기록, 경기 삭제
- **통계 대시보드**: 팀 성과, 선수별 통계, 득점왕/도움왕/MVP 시스템
- **경기 상세 분석**: 쿼터별 점수 추적, 골 기록 상세 정보
- **반응형 UI**: 모바일/웹 최적화된 사용자 인터페이스
- **오프라인 지원**: 로컬 캐싱 및 동기화
- **코드 최적화**: 불필요한 코드 제거로 성능 및 유지보수성 향상

### 🔄 개발 중
- 경기 일정 관리
- 고급 통계 분석 (팀 전술 분석, 선수 히트맵)
- 팀원 권한 관리
- 이미지 업로드 기능 (팀 로고, 선수 사진)

### 🎯 최근 개선사항
- **코드베이스 정리**: 58% 미사용 코드 제거 (33개 → 14개 항목)
- **성능 최적화**: 불필요한 임포트 및 메서드 제거
- **UI 개선**: QuarterScoreWidget의 불필요한 편집 기능 제거
- **타입 안정성**: 강화된 타입 검사 및 오류 수정

## 🔧 개발 환경

### 백엔드 개발 서버
```bash
cd backend
source venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```
- **API 문서**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

### 프론트엔드 개발 서버
```bash
cd frontend
flutter run -d chrome --web-port 3000
```
- **웹 앱**: http://localhost:3000

## 📚 API 엔드포인트

### 팀 관리
- `POST /teams/create` - 팀 생성
- `POST /teams/login` - 팀 로그인
- `GET /teams/{team_id}` - 팀 정보 조회
- `PUT /teams/{team_id}` - 팀 정보 수정
- `POST /teams/{team_id}/logo` - 팀 로고 업로드
- `POST /teams/{team_id}/image` - 팀 이미지 업로드

### 선수 관리
- `POST /players/create` - 선수 등록
- `GET /players/team/{team_id}` - 팀 선수 목록
- `PUT /players/{player_id}` - 선수 정보 수정
- `DELETE /players/{player_id}` - 선수 삭제

### 경기 관리
- `POST /matches/create` - 경기 등록
- `GET /matches/team/{team_id}` - 팀 경기 목록
- `GET /matches/{match_id}/detail` - 경기 상세 정보
- `POST /matches/{match_id}/goals` - 골 기록 추가
- `DELETE /matches/{match_id}` - 경기 삭제

## 🚀 배포

### 프론트엔드 웹 배포
```bash
cd frontend
flutter build web --release
# 빌드 결과: build/web/
```

### 백엔드 배포
```bash
cd backend
# 프로덕션 서버에서
gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

### Docker 배포 (옵션)
```bash
# 전체 스택 배포
docker-compose up -d
```

## 📖 문서

상세한 문서는 [docs/](./docs/) 디렉토리에서 확인할 수 있습니다:

- **[아키텍처 가이드](./docs/ARCHITECTURE.md)** - 시스템 설계 및 구조
- **[디렉토리 구조](./docs/DIRECTORY_STRUCTURE.md)** - 프로젝트 파일 구조
- **[데이터 흐름](./docs/DATA_FLOW.md)** - 데이터 구조 및 흐름

## 💡 사용법

### 1. 팀 등록 및 로그인
1. 앱 실행 후 "구단 등록" 선택
2. 팀 정보 입력 (이름, 설명, 유형, 비밀번호)
3. 선택사항: 팀 로고 및 이미지 업로드
4. 등록 완료 후 자동 로그인

### 2. 선수 관리
1. 홈 화면에서 "선수 관리" 탭 선택
2. "+" 버튼으로 선수 추가
3. 이름, 등번호, 포지션 입력
4. 선수별 통계 자동 추적 (득점, 어시스트, MVP 횟수)

### 3. 경기 등록
1. "매치" 탭에서 "매치 추가하기" 선택
2. 4단계 등록 과정:
   - 1단계: 기본 정보 (날짜, 상대팀, 쿼터 수)
   - 2단계: 출전 선수 선택
   - 3단계: 쿼터별 점수 입력
   - 4단계: 골 기록 입력 (득점자, 어시스트)

### 4. 통계 확인
1. "구단" 탭에서 팀 전체 통계 확인
2. 선수 어워드 (득점왕, 도움왕, MVP) 확인
3. 최근 경기 결과 및 성과 분석

## 🔧 유지보수

### 코드 품질 관리
- 정기적인 `flutter analyze` 실행으로 코드 품질 점검
- 미사용 코드 자동 탐지 및 제거
- 타입 안정성 강화

### 성능 최적화
- 로컬 캐싱을 통한 오프라인 지원
- 불필요한 API 호출 최소화
- UI 반응성 개선

## 🤝 기여하기

1. 이 저장소를 Fork합니다
2. 새로운 기능 브랜치를 생성합니다 (`git checkout -b feature/NewFeature`)
3. 변경사항을 커밋합니다 (`git commit -m 'Add some NewFeature'`)
4. 브랜치에 Push합니다 (`git push origin feature/NewFeature`)
5. Pull Request를 생성합니다

### 개발 가이드라인
- 커밋 메시지는 명확하고 간결하게
- Pull Request에는 변경사항 설명 포함
- `flutter analyze` 통과 확인
- 미사용 코드 제거 및 코드 품질 유지

## 📄 라이센스

이 프로젝트는 [MIT 라이센스](LICENSE) 하에 배포됩니다.

## 👥 개발팀

**MyFC Team** - *Initial work*

## 🙏 감사의 말

- [Flutter](https://flutter.dev) - 크로스 플랫폼 UI 프레임워크
- [FastAPI](https://fastapi.tiangolo.com) - 현대적인 Python 웹 프레임워크
- [SQLite](https://www.sqlite.org) - 경량 데이터베이스

---

**⚽ 함께 만들어가는 축구 클럽 관리의 미래!**
