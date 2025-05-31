from pydantic import BaseModel, EmailStr, ConfigDict
from typing import Optional, List, Dict
from datetime import datetime

# Team 스키마
class TeamBase(BaseModel):
    name: str
    description: str
    type: str

class TeamCreate(TeamBase):
    password: str

class TeamUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    type: Optional[str] = None
    password: Optional[str] = None

class Team(TeamBase):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    logo_url: Optional[str] = None
    image_url: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime] = None

# Player 스키마
class PlayerBase(BaseModel):
    name: str
    number: int
    position: str
    team_id: int

class PlayerCreate(PlayerBase):
    pass

class PlayerUpdate(BaseModel):
    name: Optional[str] = None
    number: Optional[int] = None
    position: Optional[str] = None
    goal_count: Optional[int] = None
    assist_count: Optional[int] = None
    mom_count: Optional[int] = None

class Player(PlayerBase):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    goal_count: int = 0
    assist_count: int = 0
    mom_count: int = 0
    created_at: datetime
    updated_at: Optional[datetime] = None

# Goal 스키마
class GoalBase(BaseModel):
    match_id: int
    player_id: int
    assist_player_id: Optional[int] = None
    quarter: int

class GoalCreate(GoalBase):
    pass

class Goal(GoalBase):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    # 응답에 선수 정보 포함
    player: Optional['Player'] = None
    assist_player: Optional['Player'] = None

# QuarterScore 스키마
class QuarterScoreBase(BaseModel):
    quarter: int
    our_score: int
    opponent_score: int

class QuarterScoreCreate(QuarterScoreBase):
    pass

class QuarterScore(QuarterScoreBase):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    match_id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

# Match 스키마
class MatchBase(BaseModel):
    date: datetime
    opponent: str
    score: str
    team_id: int

class MatchCreate(MatchBase):
    player_ids: List[int]
    quarter_scores: List[QuarterScoreBase]
    goals: List[GoalCreate] = []

class MatchUpdate(BaseModel):
    date: Optional[datetime] = None
    opponent: Optional[str] = None
    score: Optional[str] = None
    player_ids: Optional[List[int]] = None
    quarter_scores: Optional[List[QuarterScoreBase]] = None

class Match(MatchBase):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

# MatchDetail 스키마 (상세 정보를 위한 확장)
class MatchDetail(Match):
    model_config = ConfigDict(from_attributes=True)
    
    goals: List[Goal] = []
    quarter_scores: Dict[str, QuarterScore] = {}
    players: List[Player] = []

# 순환 참조 해결 (model_rebuild 사용)
Goal.model_rebuild()

# Analytics 스키마
class TeamAnalyticsOverview(BaseModel):
    total_matches: int
    wins: int
    draws: int
    losses: int
    win_rate: float
    avg_goals_scored: float
    avg_goals_conceded: float
    highest_scoring_match: Dict[str, int]
    most_conceded_match: Dict[str, int]

class GoalRangeData(BaseModel):
    goals: str
    matches: int
    wins: int
    win_rate: float

class GoalsWinCorrelation(BaseModel):
    goal_ranges: List[GoalRangeData]
    optimal_goals: int
    avg_goals_for_win: float

class ConcededRangeData(BaseModel):
    conceded: str
    matches: int
    losses: int
    loss_rate: float

class ConcededLossCorrelation(BaseModel):
    conceded_ranges: List[ConcededRangeData]
    danger_threshold: int
    avg_conceded_for_loss: float

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
    top_contributor: Dict[str, str]
    most_reliable: Dict[str, str]

# Token 스키마
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    team_id: Optional[int] = None 