# MyFC 백엔드 서버 가이드 🖥️

## 📖 개요

MyFC 백엔드는 FastAPI 기반의 RESTful API 서버로, 축구 클럽 관리에 필요한 모든 데이터와 비즈니스 로직을 처리합니다. JWT 인증, SQLAlchemy ORM, SQLite 데이터베이스를 사용하여 안전하고 효율적인 데이터 관리를 제공합니다.

## 🏗️ 디렉토리 구조

```
backend/
├── app/                         # FastAPI 애플리케이션
│   ├── main.py                 # 서버 엔트리 포인트
│   ├── database.py             # 데이터베이스 설정
│   ├── models.py               # SQLAlchemy 데이터 모델
│   ├── schemas.py              # Pydantic 요청/응답 스키마
│   ├── auth.py                 # JWT 인증 로직
│   ├── routers/                # API 라우터 모듈
│   │   ├── __init__.py
│   │   ├── team.py            # 팀 관리 API
│   │   ├── player.py          # 선수 관리 API
│   │   ├── match.py           # 매치 관리 API
│   │   └── analytics.py       # 통계 분석 API
│   ├── services/               # 비즈니스 로직 서비스
│   ├── utils/                  # 유틸리티 함수
│   └── tests/                  # API 테스트
│       └── test_api.py
├── requirements.txt            # Python 의존성
├── pytest.ini                 # pytest 설정
├── run_tests.py               # 테스트 실행 스크립트
├── venv/                      # Python 가상환경
└── myfc.db                    # SQLite 데이터베이스
```

## 📄 핵심 파일 설명

### 🚀 `main.py` - 서버 엔트리 포인트

```python
# 주요 역할
- FastAPI 앱 인스턴스 생성
- 라우터 등록 (team, player, match, analytics)
- CORS 설정 (프론트엔드와의 통신 허용)
- 데이터베이스 테이블 자동 생성
- 서버 시작 및 설정 관리

# 주요 구성 요소
app = FastAPI(title="MyFC API", version="1.0.0")
app.include_router(team.router, prefix="/teams", tags=["teams"])
app.include_router(player.router, prefix="/players", tags=["players"])
app.include_router(match.router, prefix="/matches", tags=["matches"])
app.include_router(analytics.router, prefix="/analytics", tags=["analytics"])
```

### 🗄️ `database.py` - 데이터베이스 설정

```python
# 주요 역할
- SQLAlchemy 엔진 및 세션 설정
- SQLite 데이터베이스 연결 관리
- 데이터베이스 의존성 주입 함수 제공

# 핵심 구성
SQLALCHEMY_DATABASE_URL = "sqlite:///./myfc.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```

### 📊 `models.py` - 데이터 모델

```python
# 정의된 모델들
class Team(Base):
    """팀 모델 - 축구팀 정보"""
    id, name, description, type, password_hash, created_at

class Player(Base):
    """선수 모델 - 선수 개인 정보 및 통계"""
    id, name, position, number, team_id
    goal_count, assist_count, mom_count

class Match(Base):
    """매치 모델 - 경기 정보"""
    id, date, opponent, score, team_id, created_at

class Goal(Base):
    """골 모델 - 골 기록"""
    id, quarter, player_id, assist_player_id, match_id

class QuarterScore(Base):
    """쿼터 점수 모델 - 쿼터별 득점"""
    id, quarter, our_score, opponent_score, match_id
```

### 📋 `schemas.py` - API 스키마

```python
# 요청/응답 데이터 구조 정의
- TeamCreate, TeamResponse: 팀 생성/조회
- PlayerCreate, PlayerResponse: 선수 등록/조회  
- MatchCreate, MatchResponse: 매치 등록/조회
- GoalCreate, GoalResponse: 골 기록
- QuarterScoreCreate: 쿼터 점수

# Pydantic 모델로 자동 검증 및 문서화 제공
```

### 🔐 `auth.py` - 인증 시스템

```python
# JWT 토큰 기반 인증
- create_access_token(): JWT 토큰 생성
- verify_token(): 토큰 검증
- get_current_team(): 현재 인증된 팀 정보 추출
- hash_password(): bcrypt로 비밀번호 해싱
- verify_password(): 비밀번호 검증

# 보안 설정
SECRET_KEY = "your-secret-key"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_HOURS = 24
```

## 🛣️ API 라우터 상세

### 👥 `routers/team.py` - 팀 관리

```python
# 엔드포인트
POST   /teams/create     # 팀 생성
POST   /teams/login      # 팀 로그인 (JWT 토큰 발급)
GET    /teams/{team_id}  # 팀 정보 조회
PUT    /teams/{team_id}  # 팀 정보 수정

# 주요 기능
- 팀 생성 시 비밀번호 해싱
- 로그인 시 JWT 토큰 발급
- 인증된 팀만 정보 수정 가능
```

### ⚽ `routers/player.py` - 선수 관리

```python
# 엔드포인트
POST   /players/create          # 선수 등록
GET    /players/team/{team_id}  # 팀 선수 목록 조회
PUT    /players/{player_id}     # 선수 정보 수정
DELETE /players/{player_id}     # 선수 삭제

# 주요 기능
- 등번호 중복 검사 (같은 팀 내)
- 포지션 유효성 검증 (GK, DF, MF, FW)
- 팀 소속 확인 후 수정/삭제 허용
```

### 🏆 `routers/match.py` - 매치 관리

```python
# 엔드포인트
POST   /matches/create             # 매치 등록
GET    /matches/team/{team_id}     # 팀 매치 목록
GET    /matches/{match_id}/detail  # 매치 상세 정보
POST   /matches/{match_id}/goals   # 골 기록 추가
DELETE /matches/{match_id}         # 매치 삭제

# 주요 기능
- 4단계 매치 등록 프로세스 지원
- 쿼터별 점수 관리
- 골 기록 및 어시스트 관리
- 선수 통계 자동 업데이트
```

### 📈 `routers/analytics.py` - 통계 분석

```python
# 엔드포인트
GET /analytics/team/{team_id}       # 팀 통계
GET /analytics/player/{player_id}   # 개별 선수 통계
GET /analytics/goals/{team_id}      # 팀 득점 분석

# 제공 통계
- 승/무/패 기록
- 총 득점/실점
- 선수별 골/어시스트/MOM 횟수
- 최근 경기 성과
```

## 🔧 주요 기능 및 특징

### 1. **인증 시스템**
```python
# JWT 기반 토큰 인증
@router.post("/login")
async def login_team(team_data: TeamLogin, db: Session = Depends(get_db)):
    # 1. 팀 존재 확인
    # 2. 비밀번호 검증
    # 3. JWT 토큰 발급
    # 4. 토큰 반환
```

### 2. **데이터 검증**
```python
# Pydantic 모델로 자동 검증
class PlayerCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=20)
    position: str = Field(..., regex="^(GK|DF|MF|FW)$")
    number: int = Field(..., ge=1, le=99)
```

### 3. **에러 처리**
```python
# 표준화된 HTTP 예외 처리
if not team:
    raise HTTPException(
        status_code=404, 
        detail="팀을 찾을 수 없습니다"
    )
```

### 4. **관계형 데이터 관리**
```python
# SQLAlchemy 관계 설정
class Player(Base):
    team = relationship("Team", back_populates="players")
    
class Team(Base):
    players = relationship("Player", back_populates="team")
```

## 🧪 테스트 구조

### `tests/test_api.py`
```python
# 테스트 카테고리
- TestTeamAPI: 팀 생성, 로그인, 조회
- TestPlayerAPI: 선수 CRUD 작업
- TestMatchAPI: 매치 등록 및 관리
- TestGoalAPI: 골 기록 기능
- TestValidation: 데이터 유효성 검증

# 테스트 환경
- 임시 SQLite 데이터베이스 사용
- 각 테스트 독립 실행
- JWT 토큰 기반 인증 테스트
```

## 🚀 실행 및 개발

### 개발 서버 실행
```bash
cd backend
source venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### API 문서 확인
```bash
# Swagger UI
http://localhost:8000/docs

# ReDoc
http://localhost:8000/redoc
```

### 테스트 실행
```bash
# 전체 테스트
python run_tests.py

# 특정 테스트
pytest app/tests/test_api.py::TestTeamAPI -v
```

## 📦 의존성 관리

### `requirements.txt`
```
fastapi==0.104.1          # 웹 프레임워크
uvicorn==0.24.0           # ASGI 서버
sqlalchemy==2.0.23        # ORM
pydantic==2.5.2           # 데이터 검증
python-jose[cryptography]  # JWT 토큰
passlib[bcrypt]           # 비밀번호 해싱
pytest==7.4.3            # 테스트 프레임워크
httpx==0.25.2             # HTTP 클라이언트 (테스트용)
```

## 🔒 보안 고려사항

1. **비밀번호 보안**: bcrypt 해싱 사용
2. **JWT 토큰**: 24시간 만료, SECRET_KEY 보호
3. **SQL Injection 방지**: SQLAlchemy ORM 사용
4. **CORS 설정**: 허용된 도메인만 접근
5. **입력 검증**: Pydantic 모델로 모든 입력 검증

## 📈 성능 최적화

1. **데이터베이스 인덱싱**: 주요 검색 필드에 인덱스 적용
2. **쿼리 최적화**: SQLAlchemy의 lazy loading 활용
3. **비동기 처리**: FastAPI의 async/await 지원
4. **응답 캐싱**: 정적 데이터의 캐싱 전략

---

**이 백엔드 구조는 확장 가능하고 유지보수가 용이하며, 축구 클럽 관리의 모든 요구사항을 안전하고 효율적으로 처리할 수 있도록 설계되었습니다.** 