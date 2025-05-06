# API 문서

이 문서는 My FC App의 백엔드 API 엔드포인트에 대한 상세 정보를 제공합니다.

## 기본 정보

- **Base URL**: `http://localhost:8000`
- **인증 방식**: JWT Bearer 토큰
- **Content-Type**: `application/json`

## 인증

### 팀 로그인

```
POST /teams/login
```

팀 자격 증명을 사용하여 액세스 토큰을 가져옵니다.

**요청 본문**:
```json
{
  "name": "팀 이름",
  "password": "비밀번호",
  "description": "팀 설명",
  "type": "팀 유형"
}
```

**응답**:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

## 팀 관리 API

### 팀 생성

```
POST /teams/create
```

새로운 팀을 생성합니다.

**요청 본문**:
```json
{
  "name": "팀 이름",
  "description": "팀 설명",
  "type": "팀 유형",
  "password": "비밀번호"
}
```

**응답**:
```json
{
  "name": "팀 이름",
  "description": "팀 설명",
  "type": "팀 유형",
  "id": 1,
  "logo_url": null,
  "image_url": null,
  "created_at": "2025-05-06T13:21:52",
  "updated_at": null
}
```

### 팀 정보 조회

```
GET /teams/{team_id}
```

특정 팀의 정보를 조회합니다.

**응답**:
```json
{
  "name": "팀 이름",
  "description": "팀 설명",
  "type": "팀 유형",
  "id": 1,
  "logo_url": null,
  "image_url": null,
  "created_at": "2025-05-06T13:21:52",
  "updated_at": null
}
```

## 선수 관리 API

### 선수 생성

```
POST /players/create
```

**인증 필요**: Bearer 토큰

새로운 선수를 생성합니다.

**요청 본문**:
```json
{
  "name": "선수 이름",
  "number": 10,
  "position": "FW",
  "team_id": 1
}
```

**응답**:
```json
{
  "name": "선수 이름",
  "number": 10,
  "position": "FW",
  "team_id": 1,
  "id": 1,
  "goal_count": 0,
  "assist_count": 0,
  "mom_count": 0,
  "created_at": "2025-05-06T13:22:59",
  "updated_at": null
}
```

### 개별 선수 조회

```
GET /players/{player_id}
```

**인증 필요**: Bearer 토큰

특정 선수의 정보를 조회합니다.

**응답**:
```json
{
  "name": "선수 이름",
  "number": 10,
  "position": "FW",
  "team_id": 1,
  "id": 1,
  "goal_count": 0,
  "assist_count": 0,
  "mom_count": 0,
  "created_at": "2025-05-06T13:22:59",
  "updated_at": null
}
```

### 팀의 모든 선수 조회

```
GET /players/team/{team_id}
```

**인증 필요**: Bearer 토큰

특정 팀에 소속된 모든 선수를 조회합니다.

**응답**:
```json
[
  {
    "name": "선수 이름",
    "number": 10,
    "position": "FW",
    "team_id": 1,
    "id": 1,
    "goal_count": 0,
    "assist_count": 0,
    "mom_count": 0,
    "created_at": "2025-05-06T13:22:59",
    "updated_at": null
  }
]
```

### 선수 정보 업데이트

```
PUT /players/{player_id}
```

**인증 필요**: Bearer 토큰

선수 정보를 업데이트합니다.

**요청 본문**:
```json
{
  "name": "새 이름",
  "number": 7,
  "position": "MF"
}
```

**응답**:
```json
{
  "name": "새 이름",
  "number": 7,
  "position": "MF",
  "team_id": 1,
  "id": 1,
  "goal_count": 0,
  "assist_count": 0,
  "mom_count": 0,
  "created_at": "2025-05-06T13:22:59",
  "updated_at": "2025-05-06T13:25:00"
}
```

### 선수 삭제

```
DELETE /players/{player_id}
```

**인증 필요**: Bearer 토큰

선수를 삭제합니다.

**응답**:
```json
{
  "message": "Player deleted successfully"
}
```

## 경기 관리 API

### 경기 생성

```
POST /matches/create
```

**인증 필요**: Bearer 토큰

새로운 경기를 생성합니다.

**요청 본문**:
```json
{
  "date": "2025-05-06T21:00:00",
  "opponent": "상대팀 이름",
  "score": "2:1",
  "team_id": 1,
  "player_ids": [1, 2, 3],
  "quarter_scores": [
    {
      "quarter": 1,
      "our_score": 1,
      "opponent_score": 0
    },
    {
      "quarter": 2,
      "our_score": 1,
      "opponent_score": 1
    }
  ]
}
```

**응답**:
```json
{
  "date": "2025-05-06T21:00:00",
  "opponent": "상대팀 이름",
  "score": "2:1",
  "team_id": 1,
  "id": 1,
  "created_at": "2025-05-06T13:23:31",
  "updated_at": null
}
```

### 팀의 모든 경기 조회

```
GET /matches/team/{team_id}
```

**인증 필요**: Bearer 토큰

특정 팀의 모든 경기를 조회합니다.

**응답**:
```json
[
  {
    "date": "2025-05-06T21:00:00",
    "opponent": "상대팀 이름",
    "score": "2:1",
    "team_id": 1,
    "id": 1,
    "created_at": "2025-05-06T13:23:31",
    "updated_at": null
  }
]
```

### 경기 상세 정보 조회

```
GET /matches/{match_id}/detail
```

**인증 필요**: Bearer 토큰

경기의 상세 정보를 조회합니다.

**응답**:
```json
{
  "date": "2025-05-06T21:00:00",
  "opponent": "상대팀 이름",
  "score": "2:1",
  "team_id": 1,
  "id": 1,
  "created_at": "2025-05-06T13:23:31",
  "updated_at": null,
  "goals": [
    {
      "match_id": 1,
      "player_id": 1,
      "assist_player_id": 2,
      "quarter": 1,
      "id": 1,
      "created_at": "2025-05-06T13:23:53",
      "updated_at": null,
      "player": {
        "name": "선수 이름",
        "number": 10,
        "position": "FW",
        "team_id": 1,
        "id": 1,
        "goal_count": 1,
        "assist_count": 0,
        "mom_count": 0,
        "created_at": "2025-05-06T13:22:59",
        "updated_at": "2025-05-06T13:23:53"
      },
      "assist_player": {
        "name": "어시스트 선수",
        "number": 7,
        "position": "MF",
        "team_id": 1,
        "id": 2,
        "goal_count": 0,
        "assist_count": 1,
        "mom_count": 0,
        "created_at": "2025-05-06T13:22:59",
        "updated_at": "2025-05-06T13:23:53"
      }
    }
  ],
  "quarter_scores": {
    "1": {
      "quarter": 1,
      "our_score": 1,
      "opponent_score": 0,
      "id": 1,
      "match_id": 1,
      "created_at": "2025-05-06T13:23:31",
      "updated_at": null
    },
    "2": {
      "quarter": 2,
      "our_score": 1,
      "opponent_score": 1,
      "id": 2,
      "match_id": 1,
      "created_at": "2025-05-06T13:23:31",
      "updated_at": null
    }
  },
  "players": [
    {
      "name": "선수 이름",
      "number": 10,
      "position": "FW",
      "team_id": 1,
      "id": 1,
      "goal_count": 1,
      "assist_count": 0,
      "mom_count": 0,
      "created_at": "2025-05-06T13:22:59",
      "updated_at": "2025-05-06T13:23:53"
    },
    {
      "name": "어시스트 선수",
      "number": 7,
      "position": "MF",
      "team_id": 1,
      "id": 2,
      "goal_count": 0,
      "assist_count": 1,
      "mom_count": 0,
      "created_at": "2025-05-06T13:22:59",
      "updated_at": "2025-05-06T13:23:53"
    }
  ]
}
```

### 경기 정보 업데이트

```
PUT /matches/{match_id}
```

**인증 필요**: Bearer 토큰

경기 정보를 업데이트합니다.

**요청 본문**:
```json
{
  "date": "2025-05-07T19:00:00",
  "opponent": "새 상대팀",
  "score": "3:2"
}
```

**응답**:
```json
{
  "date": "2025-05-07T19:00:00",
  "opponent": "새 상대팀",
  "score": "3:2",
  "team_id": 1,
  "id": 1,
  "created_at": "2025-05-06T13:23:31",
  "updated_at": "2025-05-06T13:25:00"
}
```

### 경기 삭제

```
DELETE /matches/{match_id}
```

**인증 필요**: Bearer 토큰

경기를 삭제합니다.

**응답**:
```json
{
  "message": "Match deleted successfully with updated player stats"
}
```

### 득점 추가

```
POST /matches/{match_id}/goals
```

**인증 필요**: Bearer 토큰

경기에 득점 정보를 추가합니다.

**요청 본문**:
```json
{
  "player_id": 1,
  "match_id": 1,
  "quarter": 2,
  "assist_player_id": 2
}
```

**응답**:
```json
{
  "match_id": 1,
  "player_id": 1,
  "assist_player_id": 2,
  "quarter": 2,
  "id": 2,
  "created_at": "2025-05-06T13:24:10",
  "updated_at": null,
  "player": {
    "name": "선수 이름",
    "number": 10,
    "position": "FW",
    "team_id": 1,
    "id": 1,
    "goal_count": 2,
    "assist_count": 0,
    "mom_count": 1,
    "created_at": "2025-05-06T13:22:59",
    "updated_at": "2025-05-06T13:24:10"
  },
  "assist_player": {
    "name": "어시스트 선수",
    "number": 7,
    "position": "MF",
    "team_id": 1,
    "id": 2,
    "goal_count": 0,
    "assist_count": 2,
    "mom_count": 0,
    "created_at": "2025-05-06T13:22:59",
    "updated_at": "2025-05-06T13:24:10"
  }
}
```

## 에러 응답

### 인증 실패

```
401 Unauthorized
```

```json
{
  "detail": "Could not validate credentials"
}
```

### 리소스 찾을 수 없음

```
404 Not Found
```

```json
{
  "detail": "Match with ID 999 not found"
}
```

### 권한 없음

```
403 Forbidden
```

```json
{
  "detail": "Not authorized to view player with ID 5 (belongs to team ID 2)"
}
```

### 유효성 검사 실패

```
400 Bad Request
```

```json
{
  "detail": [
    {
      "type": "missing",
      "loc": ["body", "name"],
      "msg": "Field required",
      "input": {}
    }
  ]
}
``` 