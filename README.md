# MyFC App

축구 구단 관리 애플리케이션의 백엔드 API 서버입니다.

## 기술 스택

- FastAPI
- SQLite
- SQLAlchemy
- JWT Authentication
- Python 3.8+

## 설치 및 실행

1. 가상환경 생성 및 활성화:
```bash
python -m venv venv
source venv/bin/activate  # Linux/Mac
# or
.\venv\Scripts\activate  # Windows
```

2. 의존성 설치:
```bash
pip install -r requirements.txt
```

3. 서버 실행:
```bash
uvicorn app.main:app --reload
```

## API 문서

서버가 실행되면 다음 URL에서 API 문서를 확인할 수 있습니다:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## 주요 기능

### 팀 관리
- 구단 생성 및 로그인
- 구단 정보 조회/수정/삭제
- 구단 로고 및 이미지 업로드

### 선수 관리
- 선수 등록
- 팀별 선수 목록 조회
- 선수 정보 수정/삭제

### 경기 관리
- 경기 등록
- 팀별 경기 목록 조회
- 경기 정보 수정/삭제
- 경기 상세 정보 조회
- 득점 정보 추가

## 보안

- JWT 토큰 기반 인증
- 비밀번호 해싱
- 파일 업로드 보안 검증

## 라이선스

MIT License
