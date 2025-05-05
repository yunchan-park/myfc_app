from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime

# Team schemas
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
    id: int
    logo_url: Optional[str] = None
    image_url: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

# Player schemas
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

class Player(PlayerBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

# Match schemas
class MatchBase(BaseModel):
    date: datetime
    opponent: str
    score: str
    team_id: int

class MatchCreate(MatchBase):
    player_ids: List[int]

class MatchUpdate(BaseModel):
    date: Optional[datetime] = None
    opponent: Optional[str] = None
    score: Optional[str] = None
    player_ids: Optional[List[int]] = None

class Match(MatchBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

# Goal schemas
class GoalBase(BaseModel):
    match_id: int
    player_id: int
    assist_player_id: Optional[int] = None
    quarter: int

class GoalCreate(GoalBase):
    pass

class Goal(GoalBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

# Token schemas
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    team_id: Optional[int] = None 