# MyFC API 엔드포인트 문서 📚

## 개요
MyFC의 모든 API 엔드포인트를 정리한 문서입니다. 모든 엔드포인트는 JWT 토큰 기반 인증을 사용합니다.

## 팀 관리 API (`/teams`)

### 팀 생성 및 인증
```
POST /teams/create
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

DELETE /teams/{team_id}
- 팀 삭제
- Response: { message }

POST /teams/upload-logo
- 팀 로고 업로드
- Request: multipart/form-data
- Response: { message, file_path }

POST /teams/upload-image
- 팀 이미지 업로드
- Request: multipart/form-data
- Response: { message, file_path }
```

## 선수 관리 API (`/players`)

### 선수 등록 및 조회
```
POST /players/create
- 새로운 선수 등록
- Request: { name, position, number, team_id }
- Response: Player object

GET /players/team/{team_id}
- 팀 선수 목록 조회
- Response: Player[] array

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

PUT /players/{player_id}/stats
- 선수 통계 업데이트
- Request: { goal_count?, assist_count?, mom_count? }
- Response: Player object

DELETE /players/{player_id}
- 선수 삭제
- Response: { message }
```

## 매치 관리 API (`/matches`)

### 매치 등록 및 조회
```
POST /matches/create
- 새로운 매치 등록
- Request: { date, opponent, score, team_id, player_ids[], quarter_scores[] }
- Response: Match object

GET /matches/team/{team_id}
- 팀 매치 목록 조회
- Response: Match[] array

GET /matches/{match_id}/detail
- 매치 상세 정보 조회
- Response: MatchDetail object
```

### 매치 관리
```
PUT /matches/{match_id}
- 매치 정보 수정
- Request: { date?, opponent?, score?, player_ids[]? }
- Response: Match object

POST /matches/{match_id}/goals
- 골 기록 추가
- Request: { player_id, assist_player_id?, quarter }
- Response: Goal object

DELETE /matches/{match_id}
- 매치 삭제
- Response: { message }
```

## 통계 분석 API (`/analytics`)

### 팀 통계
```
GET /analytics/team/{team_id}/overview
- 팀 전체 통계 개요
- Response: {
    total_matches,
    wins,
    draws,
    losses,
    avg_goals_scored,
    avg_goals_conceded,
    highest_scoring_match,
    highest_conceding_match
  }

GET /analytics/team/{team_id}/goals-win-correlation
- 득점-승률 상관관계 분석
- Response: {
    goals_per_match: [number],
    win_rate: [number],
    correlation_coefficient
  }

GET /analytics/team/{team_id}/conceded-loss-correlation
- 실점-패배율 상관관계 분석
- Response: {
    conceded_per_match: [number],
    loss_rate: [number],
    correlation_coefficient
  }

GET /analytics/team/{team_id}/player-contributions
- 선수별 승리 기여도 분석
- Response: {
    player_contributions: [{
      player_id,
      name,
      goals,
      assists,
      win_contribution_score
    }]
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

## 페이지네이션

목록 조회 API는 다음 쿼리 파라미터를 지원합니다:
```
?page=1&per_page=20
``` 