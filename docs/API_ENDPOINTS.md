# API_ENDPOINTS.md

## 목적
이 문서는 MyFC의 모든 API 엔드포인트를 정리합니다.

## 구조
- 팀 관리 API (/teams)
- 선수 관리 API (/players)
- 매치 관리 API (/matches)
- 통계 분석 API (/analytics)

## 사용법
### 팀 관리 API (`/teams`)

### 팀 생성 및 인증
```
POST /teams/
- 새로운 팀 생성
- Request: { name, description, type, password }
- Response: Team object

POST /teams/login
- 팀 로그인
- Request: { name, password }
- Response: { access_token, token_type }
```

### 팀 정보 관리
```
GET /teams/{team_id}
- 팀 정보 조회
- Response: Team object

PUT /teams/{team_id}
- 팀 정보 수정
- Request: { name?, description?, type? }
- Response: Team object

DELETE /teams/{team_id}
- 팀 삭제
- Response: { message }
```

### 선수 관리 API (`/players`)

### 선수 등록 및 조회
```
POST /players/
- 새로운 선수 등록
- Request: { name, position, number, team_id }
- Response: Player object

GET /players/{player_id}
- 개별 선수 정보 조회
- Response: Player object
```

### 선수 정보 관리
```
PUT /players/{player_id}
- 선수 정보 수정
- Request: { name?, position?, number? }
- Response: Player object

DELETE /players/{player_id}
- 선수 삭제
- Response: { message }
```

### 매치 관리 API (`/matches`)

### 매치 등록 및 조회
```
POST /matches/
- 새로운 매치 등록
- Request: { date, opponent, score, team_id, player_ids[] }
- Response: Match object

GET /matches/{match_id}
- 매치 상세 정보 조회
- Response: MatchDetail object

GET /matches/team/{team_id}
- 팀 매치 목록 조회
- Response: Match[] array
```

### 매치 관리
```
PUT /matches/{match_id}/goals
- 골 기록 추가
- Request: { player_id, assist_player_id?, quarter }
- Response: Goal object
```

### 통계 분석 API (`/analytics`)

### 팀 통계
```
GET /analytics/team/{team_id}
- 팀 전체 통계
- Response: {
    total_matches,
    wins,
    draws,
    losses,
    goals_scored,
    goals_conceded
  }

GET /analytics/player/{player_id}
- 선수 통계
- Response: {
    goals,
    assists,
    matches_played
  }

GET /analytics/matches/{team_id}
- 경기 분석
- Response: {
    recent_matches,
    performance_trend
  }
```

## 응답 형식

### 성공 응답
```json
{
  "status": "success",
  "data": { ... }
}
```

### 에러 응답
```json
{
  "status": "error",
  "message": "에러 메시지",
  "detail": "상세 에러 정보"
}
```

## 인증

모든 API 요청(팀 생성, 로그인 제외)은 다음 헤더를 포함해야 합니다:
```
Authorization: Bearer <access_token>
```

## 에러 코드

- 400: 잘못된 요청
- 401: 인증 실패
- 403: 권한 없음
- 404: 리소스 없음
- 500: 서버 에러

## 관련 문서
- PROJECT_DOCS_GUIDE.md
- DATA_FLOW.md
- BACKEND_GUIDE.md 