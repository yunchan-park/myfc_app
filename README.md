# My FC App

축구팀 관리를 위한 풀스택 모바일 애플리케이션입니다. 팀, 선수, 경기를 관리하고 통계를 추적할 수 있습니다.

## 기술 스택

### 백엔드
- **FastAPI**: 고성능 웹 프레임워크
- **SQLAlchemy**: ORM(Object-Relational Mapping)
- **SQLite**: 데이터베이스
- **Pydantic**: 데이터 검증 및 설정 관리
- **JWT**: 인증 관리

### 프론트엔드
- **Flutter**: 크로스 플랫폼 UI 프레임워크
- **Provider**: 상태 관리
- **Dio**: HTTP 클라이언트
- **Flutter Secure Storage**: 안전한 데이터 저장

## 설치 방법

### 사전 요구사항
- Python 3.8 이상
- Flutter SDK
- Git

### 백엔드 설정
```bash
# 저장소 클론
git clone https://github.com/yunchan-park/myfc_app.git
cd myfc_app

# 가상 환경 설정
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 의존성 설치
pip install -r requirements.txt

# 서버 실행
uvicorn app.main:app --reload
```

### 프론트엔드 설정
```bash
# 의존성 설치
flutter pub get

# 앱 실행
flutter run
```

## 주요 기능

### 팀 관리
- 팀 생성 및 설정
- 팀 프로필 관리

### 선수 관리
- 선수 등록 및 정보 관리
- 선수별 통계 추적 (골, 어시스트, MOM)

### 경기 관리
- 경기 일정 관리
- 경기 결과 및 세부 정보 기록
- 쿼터별 스코어 추적
- 골 및 어시스트 기록

### 통계
- 팀 통계 분석
- 선수별 성과 분석

## API 문서

API 문서는 서버 실행 후 다음 URL에서 확인할 수 있습니다:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## 라이센스

이 프로젝트는 MIT 라이센스에 따라 라이센스가 부여됩니다.
