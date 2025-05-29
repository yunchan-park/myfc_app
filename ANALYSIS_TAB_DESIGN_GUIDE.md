# 🏆 MyFC 앱 분석 탭 설계 가이드

## 📊 1. 현재 데이터 모델 구조

### 1.1 핵심 테이블 및 관계

```
Team (팀)
├── id: Integer (PK)
├── name: String (팀명)
├── description: String (팀 설명)
├── type: String (팀 타입)
└── 관계: One-to-Many → Player, Match

Player (선수)
├── id: Integer (PK)
├── name: String (선수명)
├── number: Integer (등번호)
├── position: String (포지션)
├── team_id: Integer (FK → Team)
├── goal_count: Integer (총 득점)
├── assist_count: Integer (총 어시스트)
├── mom_count: Integer (MOM 횟수)
└── 관계: Many-to-Many → Match (match_player 테이블)

Match (경기)
├── id: Integer (PK)
├── date: DateTime (경기 날짜)
├── opponent: String (상대팀)
├── score: String (스코어, 예: "3:2")
├── team_id: Integer (FK → Team)
└── 관계: One-to-Many → Goal, QuarterScore

Goal (골)
├── id: Integer (PK)
├── match_id: Integer (FK → Match)
├── player_id: Integer (FK → Player, 득점자)
├── assist_player_id: Integer (FK → Player, 어시스트, nullable)
├── quarter: Integer (쿼터)
├── scorer_name: String (득점자명)
└── assist_name: String (어시스트명)

QuarterScore (쿼터별 점수)
├── id: Integer (PK)
├── match_id: Integer (FK → Match)
├── quarter: Integer (쿼터 번호)
├── our_score: Integer (우리팀 점수)
└── opponent_score: Integer (상대팀 점수)
```

### 1.2 현재 데이터 현황
- **총 경기 수**: 17경기
- **총 선수 수**: 35명
- **총 골 수**: 35골
- **주요 선수**: 지가은(4골 2어시스트), 박윤찬(4골 3어시스트)

## 🎯 2. 분석 탭 요구사항 및 데이터 소스

### 2.1 평균 득점 시 승률 분석
**목표**: 평균 몇 골을 넣었을 때 이겼는지 분석

**필요 데이터**:
```sql
-- 경기별 득점과 승부 결과
SELECT 
    m.id,
    m.score,
    COUNT(g.id) as goals_scored,
    CASE 
        WHEN CAST(SUBSTR(m.score, 1, INSTR(m.score, ':')-1) AS INTEGER) > 
             CAST(SUBSTR(m.score, INSTR(m.score, ':')+1) AS INTEGER) 
        THEN 'WIN'
        WHEN CAST(SUBSTR(m.score, 1, INSTR(m.score, ':')-1) AS INTEGER) < 
             CAST(SUBSTR(m.score, INSTR(m.score, ':')+1) AS INTEGER) 
        THEN 'LOSE'
        ELSE 'DRAW'
    END as result
FROM matches m
LEFT JOIN goals g ON m.id = g.match_id
GROUP BY m.id
```

### 2.2 평균 실점 시 패배율 분석
**목표**: 평균 몇 실점했을 때 졌는지 분석

**필요 데이터**:
```sql
-- 경기별 실점과 승부 결과
SELECT 
    m.id,
    m.score,
    CAST(SUBSTR(m.score, INSTR(m.score, ':')+1) AS INTEGER) as goals_conceded,
    -- 승부 결과 계산 로직 동일
FROM matches m
```

### 2.3 선수별 승리 기여도 분석
**목표**: 출전 시 승률, MOM 횟수 등 선수별 기여도 분석

**필요 데이터**:
```sql
-- 선수별 출전 경기와 승률
SELECT 
    p.id,
    p.name,
    p.goal_count,
    p.assist_count,
    p.mom_count,
    COUNT(DISTINCT mp.match_id) as matches_played,
    COUNT(CASE WHEN result = 'WIN' THEN 1 END) as wins,
    ROUND(COUNT(CASE WHEN result = 'WIN' THEN 1 END) * 100.0 / COUNT(DISTINCT mp.match_id), 2) as win_rate
FROM players p
LEFT JOIN match_player mp ON p.id = mp.player_id
LEFT JOIN matches m ON mp.match_id = m.id
-- 승부 결과 조인 필요
GROUP BY p.id
```

## 🚀 3. 새로운 분석 API 설계

### 3.1 추천 API 엔드포인트

#### 3.1.1 팀 전체 통계 API
```python
@router.get("/analytics/team/{team_id}/overview")
def get_team_analytics_overview(team_id: int):
    """
    팀 전체 통계 개요
    - 총 경기 수, 승/무/패
    - 평균 득점/실점
    - 최다 득점 경기, 최다 실점 경기
    """
    return {
        "total_matches": 17,
        "wins": 8,
        "draws": 2,
        "losses": 7,
        "win_rate": 47.1,
        "avg_goals_scored": 2.1,
        "avg_goals_conceded": 1.8,
        "highest_scoring_match": {"match_id": 4, "goals": 5},
        "most_conceded_match": {"match_id": 3, "goals": 4}
    }
```

#### 3.1.2 득점별 승률 분석 API
```python
@router.get("/analytics/team/{team_id}/goals-win-correlation")
def get_goals_win_correlation(team_id: int):
    """
    득점 수별 승률 분석
    """
    return {
        "goal_ranges": [
            {"goals": "0", "matches": 2, "wins": 0, "win_rate": 0.0},
            {"goals": "1", "matches": 4, "wins": 1, "win_rate": 25.0},
            {"goals": "2", "matches": 6, "wins": 3, "win_rate": 50.0},
            {"goals": "3+", "matches": 5, "wins": 4, "win_rate": 80.0}
        ],
        "optimal_goals": 3,
        "avg_goals_for_win": 2.8
    }
```

#### 3.1.3 실점별 패배율 분석 API
```python
@router.get("/analytics/team/{team_id}/conceded-loss-correlation")
def get_conceded_loss_correlation(team_id: int):
    """
    실점 수별 패배율 분석
    """
    return {
        "conceded_ranges": [
            {"conceded": "0", "matches": 3, "losses": 0, "loss_rate": 0.0},
            {"conceded": "1", "matches": 5, "losses": 1, "loss_rate": 20.0},
            {"conceded": "2", "matches": 6, "losses": 3, "loss_rate": 50.0},
            {"conceded": "3+", "matches": 3, "losses": 3, "loss_rate": 100.0}
        ],
        "danger_threshold": 3,
        "avg_conceded_for_loss": 2.4
    }
```

#### 3.1.4 선수별 기여도 분석 API
```python
@router.get("/analytics/team/{team_id}/player-contributions")
def get_player_contributions(team_id: int):
    """
    선수별 승리 기여도 분석
    """
    return {
        "players": [
            {
                "id": 1,
                "name": "지가은",
                "matches_played": 6,
                "wins": 4,
                "win_rate": 66.7,
                "goals": 4,
                "assists": 2,
                "mom_count": 0,
                "contribution_score": 8.5,  # 골*2 + 어시스트 + MOM*3
                "avg_goals_per_match": 0.67
            },
            {
                "id": 2,
                "name": "박윤찬",
                "matches_played": 6,
                "wins": 4,
                "win_rate": 66.7,
                "goals": 4,
                "assists": 3,
                "mom_count": 0,
                "contribution_score": 11.0,
                "avg_goals_per_match": 0.67
            }
        ],
        "top_contributor": {"name": "박윤찬", "score": 11.0},
        "most_reliable": {"name": "지가은", "win_rate": 66.7}
    }
```

#### 3.1.5 경기 패턴 분석 API
```python
@router.get("/analytics/team/{team_id}/match-patterns")
def get_match_patterns(team_id: int):
    """
    경기 패턴 분석 (쿼터별, 시간대별)
    """
    return {
        "quarter_performance": [
            {"quarter": 1, "avg_goals": 0.8, "avg_conceded": 0.6},
            {"quarter": 2, "avg_goals": 0.9, "avg_conceded": 0.7},
            {"quarter": 3, "avg_goals": 0.7, "avg_conceded": 0.8},
            {"quarter": 4, "avg_goals": 0.6, "avg_conceded": 0.5}
        ],
        "strongest_quarter": 2,
        "weakest_quarter": 4,
        "comeback_matches": 3,  # 뒤지다가 이긴 경기 수
        "blown_leads": 2  # 앞서다가 진 경기 수
    }
```

### 3.2 새로운 스키마 정의

```python
# app/schemas.py에 추가할 스키마들

class TeamAnalyticsOverview(BaseModel):
    total_matches: int
    wins: int
    draws: int
    losses: int
    win_rate: float
    avg_goals_scored: float
    avg_goals_conceded: float
    highest_scoring_match: Dict[str, Any]
    most_conceded_match: Dict[str, Any]

class GoalsWinCorrelation(BaseModel):
    goal_ranges: List[Dict[str, Any]]
    optimal_goals: int
    avg_goals_for_win: float

class PlayerContribution(BaseModel):
    id: int
    name: str
    matches_played: int
    wins: int
    win_rate: float
    goals: int
    assists: int
    mom_count: int
    contribution_score: float
    avg_goals_per_match: float

class PlayerContributionsResponse(BaseModel):
    players: List[PlayerContribution]
    top_contributor: Dict[str, Any]
    most_reliable: Dict[str, Any]

class MatchPatterns(BaseModel):
    quarter_performance: List[Dict[str, Any]]
    strongest_quarter: int
    weakest_quarter: int
    comeback_matches: int
    blown_leads: int
```

## 🛠️ 4. 구현 가이드

### 4.1 백엔드 구현 단계

1. **새로운 라우터 생성**: `app/routers/analytics.py`
2. **분석 서비스 로직**: `app/services/analytics_service.py`
3. **스키마 확장**: `app/schemas.py`에 분석 관련 스키마 추가
4. **메인 앱에 라우터 등록**: `app/main.py`

### 4.2 프론트엔드 구현 단계

1. **분석 탭 화면**: `lib/screens/analytics_screen.dart`
2. **분석 서비스**: `lib/services/analytics_service.dart`
3. **분석 모델**: `lib/models/analytics.dart`
4. **차트 위젯**: `lib/widgets/analytics/`
5. **네비게이션 업데이트**: 기존 탭 바에 분석 탭 추가

### 4.3 추천 차트 라이브러리
- **Flutter**: `fl_chart` 패키지 (이미 사용 중인지 확인 필요)
- **차트 타입**: 
  - 바 차트: 득점별 승률, 실점별 패배율
  - 파이 차트: 승/무/패 비율
  - 라인 차트: 쿼터별 성과 추이
  - 레이더 차트: 선수별 종합 능력

## 📈 5. 데이터 시각화 제안

### 5.1 메인 대시보드
```
┌─────────────────┬─────────────────┐
│   팀 전체 통계   │   최근 5경기    │
│  승률: 47.1%    │   W-L-W-W-L    │
│ 평균득점: 2.1골  │                │
│ 평균실점: 1.8골  │                │
└─────────────────┴─────────────────┘
```

### 5.2 득점-승률 상관관계
```
득점별 승률 (바 차트)
100% ┤     ████
 80% ┤     ████
 60% ┤     ████
 40% ┤ ██  ████
 20% ┤ ██  ████
  0% ┤ ██  ████
     └─────────────
      0  1  2  3+ 골
```

### 5.3 선수별 기여도 
선수별 기여도는 숫자로만 계산하여 테이블 형태로 보여주기
(등번호, 이름, 선수별 기여도 점수)

## 🔧 6. 구현 우선순위

### Phase 1 (핵심 기능)
1. 팀 전체 통계 API
2. 득점별 승률 분석 API
3. 기본 분석 화면 구현

### Phase 2 (고급 분석)
1. 선수별 기여도 분석 API
2. 경기 패턴 분석 API
3. 고급 차트 구현

### Phase 3 (추가 기능)
1. 시즌별 비교 분석
2. 상대팀별 전적 분석
3. 예측 모델 (승률 예측)

## 📝 7. 다음 단계

1. **analytics.py 라우터 생성**
2. **analytics_service.py 서비스 로직 구현**
3. **Flutter 분석 화면 구현**
4. **차트 라이브러리 통합**
5. **테스트 및 최적화**

이 가이드를 바탕으로 단계별로 분석 탭을 구현하시면 됩니다. 각 단계별로 구체적인 코드 구현이 필요하시면 말씀해 주세요! 