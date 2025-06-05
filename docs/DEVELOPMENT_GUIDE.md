# MyFC 개발 가이드 📚

## 📖 개요
이 문서는 MyFC 애플리케이션의 개발 가이드라인을 제공합니다.

## 🎯 개발 환경 설정

### 프론트엔드 (Flutter)
```bash
# Flutter SDK 설치
# https://flutter.dev/docs/get-started/install

# 프로젝트 설정
cd frontend
flutter pub get
flutter run -d chrome --web-port 3000
```

### 백엔드 (FastAPI)
```bash
# Python 가상환경 설정
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 의존성 설치
pip install -r requirements.txt

# 서버 실행
uvicorn app.main:app --reload --port 8000
```

## 💻 백엔드 개발 가이드

### 1. 코드 구조
```
backend/app/
├── main.py                     # 서버 엔트리 포인트
├── database.py                 # DB 설정
├── models.py                   # DB 모델
├── schemas.py                  # API 스키마
├── auth.py                     # 인증 로직
├── routers/                    # API 라우터
└── services/                   # 비즈니스 로직
```

### 2. API 개발
- FastAPI 라우터 사용
- Pydantic 모델로 요청/응답 검증
- 의존성 주입 활용
- 비동기 함수 사용

### 3. 데이터베이스
- SQLAlchemy ORM 사용
- 마이그레이션 관리
- 트랜잭션 처리
- 관계 설정

### 4. 인증
- JWT 토큰 기반
- 비밀번호 해싱
- 토큰 검증
- 권한 관리

## 📱 프론트엔드 개발 가이드

### 1. 코드 구조
```
frontend/lib/
├── main.dart                    # 앱 엔트리 포인트
├── config/                      # 설정 관리
├── models/                      # 데이터 모델
├── services/                    # 비즈니스 로직
├── screens/                     # UI 화면
├── widgets/                     # 재사용 컴포넌트
├── utils/                       # 유틸리티
└── routers/                     # 라우팅
```

### 2. UI 개발
- Material Design 사용
- 반응형 레이아웃
- 재사용 가능한 위젯
- 상태 관리

### 3. API 통신
- http 패키지 사용
- 에러 처리
- 로딩 상태 관리
- 캐싱

### 4. 로컬 저장소
- shared_preferences 사용
- 보안 데이터 관리
- 캐시 관리

## 🧪 테스트 가이드

### 1. 백엔드 테스트
```bash
# 테스트 실행
PYTHONPATH=backend pytest backend/tests

# 커버리지 리포트
pytest --cov=app tests/
```

### 2. 프론트엔드 테스트
```bash
# 테스트 실행
flutter test

# 커버리지 리포트
flutter test --coverage
```

## 📝 코드 컨벤션

### 1. Python
- PEP 8 스타일 가이드
- 타입 힌트 사용
- 문서화 문자열
- 예외 처리

### 2. Dart
- Effective Dart 가이드
- null safety 사용
- 비동기 처리
- 위젯 분리

## 📚 문서화 가이드

### 1. 코드 문서화
- 함수/클래스 설명
- 매개변수 설명
- 반환값 설명
- 예외 설명

### 2. API 문서화
- 엔드포인트 설명
- 요청/응답 예시
- 에러 코드
- 인증 요구사항

## 🔄 개발 워크플로우

### 1. 기능 개발
1. 이슈 생성
2. 브랜치 생성
3. 코드 작성
4. 테스트 작성
5. PR 생성

### 2. 코드 리뷰
1. 코드 스타일 검토
2. 기능 검증
3. 테스트 커버리지
4. 문서화 확인

### 3. 배포
1. 버전 태그
2. 변경사항 문서화
3. 배포 스크립트 실행
4. 모니터링 