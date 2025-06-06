# MyFC 클라이언트-서버 데이터 관리 및 연동 구조 (상세 버전)

---

## 1. 클라이언트(Flutter)가 관리하는 정보

### 1.1 관리 정보 종류 (구체적 변수/데이터)
- **UI 상태**
  - 현재 화면(route, 예: `/home`, `/match/step1`)
  - 선택된 탭 인덱스(int selectedTabIndex)
  - 로딩 상태(bool isLoading, bool isSubmitting)
  - 에러 메시지(String? errorMessage)
  - 다이얼로그/모달 표시(bool showDialog, bool showModal)
  - Snackbar/Toast 메시지(String? snackbarMessage)
- **입력값**
  - 팀명(String teamName)
  - 팀 설명(String teamDescription)
  - 팀 타입(String teamType)
  - 비밀번호(String password)
  - 선수명(String playerName)
  - 선수 포지션(String playerPosition)
  - 선수 등번호(int playerNumber)
  - 경기 일자(DateTime matchDate)
  - 상대팀(String opponent)
  - 쿼터별 점수(List<int> quarterScores)
  - 골 득점자(int goalPlayerId)
  - 어시스트 선수(int assistPlayerId)
- **인증 정보**
  - JWT 토큰(String? _token)
  - 로그인 상태(bool isLoggedIn)
  - 현재 로그인 팀 ID(int? teamId)
- **임시 데이터**
  - 경기 등록 단계별 임시 데이터(Map<String, dynamic> matchStepData)
  - 미제출 폼 데이터(Map<String, dynamic> unsavedFormData)
- **로컬 저장소**
  - SharedPreferences에 저장된 JWT 토큰(String? token)
  - 최근 로그인 팀 ID(int? lastTeamId)
  - 최근 접속 시간(DateTime? lastLoginAt)
- **도메인 모델**
  - Player (id, name, position, number, teamId, goalCount, assistCount, momCount)
  - Team (id, name, description, type, passwordHash, logoUrl, imageUrl, createdAt)
  - Match (id, date, opponent, score, teamId, quarterScores, createdAt)
  - Goal (id, quarter, playerId, assistPlayerId, matchId)

### 1.2 관리 구조 및 상태관리 방식
- **setState**:  
  - 각 StatefulWidget에서 입력값, 로딩/에러 상태, 화면 내 임시 변수 관리  
  - 예: `setState(() { isLoading = true; })`
- **Provider/ChangeNotifier**:  
  - 인증 상태(AuthService, AuthProvider)
  - 팀/선수/경기 목록(TeamProvider, PlayerProvider, MatchProvider)
  - 전역적으로 필요한 상태(예: 로그인, 토큰, 전체 선수 리스트)
- **SharedPreferences**:  
  - JWT 토큰, 최근 로그인 팀 ID, 최근 접속 시간 등 영속적 데이터 저장/불러오기

### 1.3 주요 변수명, 클래스명, 관리 위치 (구체적)
- **lib/screens/**
  - HomeScreen (홈 화면, 탭/네비게이션/로그아웃 등)
  - MatchStep1Screen (경기 등록 1단계: 상대팀, 일자 입력)
  - MatchStep2Screen (경기 등록 2단계: 선수 선택, 쿼터별 점수)
  - MatchSummaryScreen (경기 결과 요약)
  - TeamProfileScreen (팀 정보/수정)
  - PlayerManagementScreen (선수 목록/등록/수정/삭제)
  - AnalyticsScreen (분석 데이터 표시)
- **lib/models/**
  - player.dart (Player 클래스)
  - team.dart (Team 클래스)
  - match.dart (Match 클래스)
  - goal.dart (Goal 클래스)
- **lib/services/**
  - api_service.dart (API 통신, http 요청/응답)
  - auth_service.dart (로그인, 토큰 관리, 인증 상태)
  - storage_service.dart (SharedPreferences 연동)
  - match_service.dart (경기 등록/조회/수정)
  - player_service.dart (선수 등록/조회/수정/삭제)
  - team_service.dart (팀 등록/조회/수정)
- **lib/widgets/**
  - common/app_button.dart (공통 버튼)
  - common/app_input.dart (공통 입력 필드)
  - common/app_card.dart (카드 UI)
  - common/loading_widget.dart (로딩 인디케이터)
  - quarter_score_widget.dart (쿼터별 점수 입력/표시)
  - goal_list_widget.dart (골 목록 표시)
- **상태관리 예시**
  - AuthService (ChangeNotifier, Provider로 주입)
  - PlayerProvider (ChangeNotifier, 선수 목록/상태 관리)
  - MatchProvider (ChangeNotifier, 경기 목록/상태 관리)

### 1.4 구조 흐름도/위젯 계층 (구체적 예시)
```
HomeScreen
  └─ MatchStep1Screen (상대팀, 일자 입력)
        └─ MatchStep2Screen (선수 선택, 쿼터별 점수 입력)
              └─ MatchService.createMatch() (API 호출)
                    └─ 서버 응답
                          └─ MatchSummaryScreen (결과/요약)
```
- 각 단계별로 Provider/ChangeNotifier에서 상태를 관리하며, 최종적으로 MatchService를 통해 서버와 통신

---

## 2. 서버(DB 포함)가 관리하는 정보

### 2.1 도메인 정보 클래스 정의/필드/타입 (models.py 기준)
- **Team**
  - id: Integer, Primary Key
  - name: String, Unique
  - description: String
  - type: String
  - password_hash: String
  - logo_url: String
  - image_url: String
  - created_at: DateTime
- **Player**
  - id: Integer, Primary Key
  - name: String
  - position: String
  - number: Integer
  - team_id: Integer, ForeignKey(teams.id)
  - goal_count: Integer
  - assist_count: Integer
  - mom_count: Integer
- **Match**
  - id: Integer, Primary Key
  - date: String
  - opponent: String
  - score: String
  - team_id: Integer, ForeignKey(teams.id)
  - quarter_scores: JSON
  - created_at: DateTime
- **Goal**
  - id: Integer, Primary Key
  - quarter: Integer
  - player_id: Integer, ForeignKey(players.id)
  - assist_player_id: Integer, ForeignKey(players.id)
  - match_id: Integer, ForeignKey(matches.id)

### 2.2 테이블 관계/ForeignKey (구체적)
- Team (1) ──< (N) Player (team_id)
- Team (1) ──< (N) Match (team_id)
- Match (1) ──< (N) Goal (match_id)
- Player (1) ──< (N) Goal (player_id, assist_player_id)
- ForeignKey는 SQLAlchemy의 ForeignKey 필드로 명시

### 2.3 FastAPI 요청 흐름 (구체적)
- **router** (예: routers/player.py)
  - API 엔드포인트 정의 (예: @router.post("/players/create"))
- **schema** (schemas.py)
  - 요청/응답 데이터 구조 정의 (Pydantic BaseModel)
- **service** (services/player_service.py)
  - 실제 비즈니스 로직 (DB 저장/조회/수정/삭제)
- **model** (models.py)
  - SQLAlchemy ORM 모델 (테이블/필드/관계)
- **예시 흐름**
  - POST /players/create → routers/player.py (엔드포인트) → schemas.PlayerCreate (요청 데이터) → services/player_service.py (로직) → models.Player (DB 저장)

### 2.4 코드 위치별 역할 (구체적)
- **routers/**: API 엔드포인트(팀, 선수, 경기, 분석 등)
- **models.py**: SQLAlchemy ORM 모델(Team, Player, Match, Goal)
- **schemas.py**: Pydantic 데이터 구조(PlayerCreate, TeamCreate, MatchCreate 등)
- **services/**: 비즈니스 로직(선수/팀/경기 등록, 수정, 삭제, 조회 등)

### 2.5 Entity-Relationship Diagram (ERD)
```
[Team] 1 ──< N [Player]
[Team] 1 ──< N [Match] 1 ──< N [Goal]
[Player] 1 ──< N [Goal] (득점자/어시스트)
```
- Team.id → Player.team_id
- Match.id → Goal.match_id
- Player.id → Goal.player_id, Goal.assist_player_id

---

## 3. 클라이언트-서버 송수신 정보 (RESTful API)

### 3.1 API 전체 목록 (메서드, URL, 실제 코드 기준)
- **팀**
  - POST   /teams/create (팀 생성)
  - POST   /teams/login (로그인, JWT 발급)
  - GET    /teams/{team_id} (팀 정보 조회)
  - PUT    /teams/{team_id} (팀 정보 수정)
  - POST   /teams/{team_id}/logo (팀 로고 업로드)
  - POST   /teams/{team_id}/image (팀 이미지 업로드)
- **선수**
  - POST   /players/create (선수 등록)
  - GET    /players/team/{team_id} (팀별 선수 목록)
  - PUT    /players/{player_id} (선수 정보 수정)
  - DELETE /players/{player_id} (선수 삭제)
- **경기**
  - POST   /matches/create (경기 등록)
  - GET    /matches/team/{team_id} (팀별 경기 목록)
  - GET    /matches/{match_id}/detail (경기 상세)
  - POST   /matches/{match_id}/goals (골 기록)
  - DELETE /matches/{match_id} (경기 삭제)
- **분석**
  - GET    /analytics/team/{team_id}/overview (팀 요약)
  - GET    /analytics/team/{team_id}/goals-win-correlation (득점-승리 상관분석)
  - GET    /analytics/team/{team_id}/conceded-loss-correlation (실점-패배 상관분석)
  - GET    /analytics/team/{team_id}/player-contributions (선수별 기여도)

### 3.2 요청/응답 JSON 예시 (구체적)
- **요청 예시 (선수 등록)**
```json
{
  "name": "홍길동",
  "position": "FW",
  "number": 10,
  "team_id": 1
}
```
- **응답 예시 (선수 목록)**
```json
{
  "status": "success",
  "data": [
    {
      "id": 1,
      "name": "홍길동",
      "position": "FW",
      "number": 10,
      "team_id": 1,
      "goal_count": 5,
      "assist_count": 2,
      "mom_count": 1
    },
    {
      "id": 2,
      "name": "이영표",
      "position": "DF",
      "number": 3,
      "team_id": 1,
      "goal_count": 0,
      "assist_count": 1,
      "mom_count": 0
    }
  ]
}
```
- **요청 예시 (경기 등록)**
```json
{
  "date": "2024-06-01",
  "opponent": "FC Example",
  "score": "2-1",
  "team_id": 1,
  "quarter_scores": [1, 1, 0, 0]
}
```
- **응답 예시 (경기 상세)**
```json
{
  "status": "success",
  "data": {
    "id": 10,
    "date": "2024-06-01",
    "opponent": "FC Example",
    "score": "2-1",
    "team_id": 1,
    "quarter_scores": [1, 1, 0, 0],
    "created_at": "2024-06-01T12:00:00"
  }
}
```

### 3.3 API 호출 흐름(시퀀스, 구체적)
```
MatchStep1Screen (상대팀, 일자 입력)
  → MatchStep2Screen (선수 선택, 쿼터별 점수 입력)
    → MatchService.createMatch() (POST /matches/create, JSON body)
      → FastAPI Router (matches.py, @router.post('/matches/create'))
        → MatchService (services/match_service.py, DB 저장)
          → models.Match (DB 테이블 저장)
            → 응답 반환 (schemas.MatchResponse)
              → MatchSummaryScreen (결과/요약 표시)
```

### 3.4 인증 처리 구조 (구체적)
- **요청 헤더**
  - Authorization: Bearer {JWT}
  - Content-Type: application/json
- **JWT 발급**
  - /teams/login 성공 시 서버에서 JWT 토큰 반환
- **클라이언트 저장**
  - SharedPreferences.setString('token', token)
  - AuthService._token = token
- **API 호출 시**
  - http 요청 헤더에 Authorization: Bearer {token} 포함
- **서버 검증**
  - FastAPI Depends(get_current_team)에서 JWT 디코딩 및 유효성 검증
  - 유효하지 않으면 401 Unauthorized 반환

### 3.5 시퀀스 다이어그램 예시 (구체적)
```
User
  ↓ (입력)
App(Flutter)
  ↓ (POST /matches/create, JWT 포함)
FastAPI Router (matches.py)
  ↓ (서비스 호출)
MatchService (DB 저장)
  ↓ (ORM)
SQLite DB
  ↑ (저장 결과)
MatchService
  ↑ (응답 데이터)
FastAPI Router
  ↑ (JSON 응답)
App(Flutter)
  ↑ (결과 표시)
User
```

---

이 문서는 myfc_app 프로젝트의 실제 코드, 변수, 구조, 데이터, API, 인증, 흐름을 모두 구체적으로 빠짐없이 명시한 버전입니다.  
이제 이 내용을 그대로 문서화하면, 생략 없이 완전한 시스템 구조/데이터/연동 문서가 완성됩니다.  
(더 필요한 세부 예시나 특정 API/모델/화면의 상세 정보가 필요하면 추가로 요청해 주세요!) 