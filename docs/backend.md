# 백엔드 문서

이 문서는 My FC App 백엔드 시스템의 아키텍처, 코드 구조, 주요 구성 요소에 대한 정보를 제공합니다.

## 시스템 아키텍처

My FC App의 백엔드는 FastAPI를 기반으로 구축되었으며, 다음과 같은 계층적 구조로 설계되었습니다:

1. **API 레이어**: 클라이언트의 요청을 받아 처리하는 라우터 모듈
2. **서비스 레이어**: 비즈니스 로직을 처리하는 핵심 모듈
3. **데이터 레이어**: 데이터베이스와의 상호작용을 담당하는 모델과 스키마

## 코드 구조

```
app/
├── __init__.py
├── main.py               # 애플리케이션 진입점
├── database.py           # 데이터베이스 연결 설정
├── models.py             # SQLAlchemy 모델 정의
├── schemas.py            # Pydantic 스키마 정의
├── auth.py               # 인증 관련 기능
├── routers/              # API 라우터 모듈
│   ├── __init__.py
│   ├── team.py           # 팀 관련 API
│   ├── player.py         # 선수 관련 API
│   └── match.py          # 경기 관련 API
└── utils/                # 유틸리티 함수
    └── file_handler.py   # 파일 처리 유틸리티
```

## 주요 구성 요소

### 1. 데이터베이스 (database.py)

SQLite 데이터베이스를 사용하며, SQLAlchemy ORM을 통해 객체 지향적인 방식으로 데이터베이스를 다룹니다.

```python
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

SQLALCHEMY_DATABASE_URL = "sqlite:///./myfc.db"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```

### 2. 모델 (models.py)

데이터베이스 테이블을 정의하는 SQLAlchemy 모델 클래스들이 포함되어 있습니다.

주요 모델:
- `Team`: 팀 정보 모델
- `Player`: 선수 정보 모델
- `Match`: 경기 정보 모델
- `Goal`: 득점 정보 모델
- `QuarterScore`: 쿼터별 점수 모델

### 3. 스키마 (schemas.py)

API 요청 및 응답에 사용되는 Pydantic 스키마 클래스들이 포함되어 있습니다.

주요 스키마:
- `TeamBase`, `TeamCreate`, `Team`: 팀 관련 스키마
- `PlayerBase`, `PlayerCreate`, `Player`: 선수 관련 스키마
- `MatchBase`, `MatchCreate`, `Match`: 경기 관련 스키마
- `GoalCreate`, `Goal`: 득점 관련 스키마
- `QuarterScoreBase`, `QuarterScore`: 쿼터 점수 관련 스키마

### 4. 인증 시스템 (auth.py)

JWT(JSON Web Token)를 사용한 인증 시스템이 구현되어 있습니다.

주요 기능:
- 비밀번호 해싱 및 검증
- 액세스 토큰 생성
- 토큰 검증 및 현재 팀 정보 조회

### 5. 라우터 (routers/)

각 도메인별로 분리된 API 엔드포인트들이 구현되어 있습니다.

#### 팀 관련 API (team.py)
- 팀 생성
- 팀 로그인
- 팀 정보 조회/수정/삭제

#### 선수 관련 API (player.py)
- 선수 생성
- 개별 선수 정보 조회
- 팀별 선수 목록 조회
- 선수 정보 수정/삭제
- 선수 통계 업데이트

#### 경기 관련 API (match.py)
- 경기 생성
- 팀별 경기 목록 조회
- 경기 정보 수정/삭제
- 경기 상세 정보 조회
- 득점 정보 추가

## 비즈니스 로직

### MOM(Man of the Match) 선정 로직

경기에서 최고의 활약을 보인 선수를 자동으로 선정하는 로직이 구현되어 있습니다.

- 득점: 2점
- 어시스트: 1점
- 가장 높은 점수를 받은 선수가 MOM으로 선정됩니다.

### 쿼터별 점수 계산 로직

경기의 쿼터별 점수를 관리하고, 정보가 없는 경우 자동으로 계산하는 로직이 구현되어 있습니다.

### 통계 롤백 로직

경기가 삭제되면 해당 경기와 관련된 모든 통계(득점, 어시스트, MOM)가 자동으로 롤백됩니다.

## 성능 최적화

- `joinedload`를 사용하여 N+1 쿼리 문제 해결
- 벌크 삽입 및 업데이트 활용
- 효율적인 데이터베이스 쿼리 구현

## 에러 처리

상세한 에러 메시지를 제공하여 디버깅과 문제 해결을 용이하게 합니다.

- 존재하지 않는 리소스에 대한 명확한 에러 메시지
- 권한 오류에 대한 상세한 설명
- 유효성 검사 실패에 대한 구체적인 정보 