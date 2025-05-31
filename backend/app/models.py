from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Table
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .database import Base

# Association table for Match-Player relationship
match_player = Table(
    'match_player',
    Base.metadata,
    Column('match_id', Integer, ForeignKey('matches.id')),
    Column('player_id', Integer, ForeignKey('players.id'))
)

class Team(Base):
    __tablename__ = "teams"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True)
    description = Column(String)
    type = Column(String)
    password = Column(String)
    logo_url = Column(String, nullable=True)
    image_url = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    players = relationship("Player", back_populates="team")
    matches = relationship("Match", back_populates="team")

class Player(Base):
    __tablename__ = "players"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    number = Column(Integer)
    position = Column(String)
    team_id = Column(Integer, ForeignKey("teams.id"))
    goal_count = Column(Integer, default=0)
    assist_count = Column(Integer, default=0)
    mom_count = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    team = relationship("Team", back_populates="players")
    matches = relationship("Match", secondary=match_player, back_populates="players")
    goals = relationship("Goal", foreign_keys="[Goal.player_id]", back_populates="player")
    assists = relationship("Goal", foreign_keys="[Goal.assist_player_id]", back_populates="assist_player")

class Match(Base):
    __tablename__ = "matches"

    id = Column(Integer, primary_key=True, index=True)
    date = Column(DateTime(timezone=True))
    opponent = Column(String)
    score = Column(String)
    team_id = Column(Integer, ForeignKey("teams.id"))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    team = relationship("Team", back_populates="matches")
    players = relationship("Player", secondary=match_player, back_populates="matches")
    goals = relationship("Goal", back_populates="match")
    quarter_scores = relationship("QuarterScore", back_populates="match", cascade="all, delete-orphan")

class Goal(Base):
    __tablename__ = "goals"

    id = Column(Integer, primary_key=True, index=True)
    match_id = Column(Integer, ForeignKey("matches.id"))
    player_id = Column(Integer, ForeignKey("players.id"))
    assist_player_id = Column(Integer, ForeignKey("players.id"), nullable=True)
    quarter = Column(Integer)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    scorer_name = Column(String, nullable=True)
    assist_name = Column(String, nullable=True)

    match = relationship("Match", back_populates="goals")
    player = relationship("Player", foreign_keys=[player_id], back_populates="goals")
    assist_player = relationship("Player", foreign_keys=[assist_player_id], back_populates="assists")

class QuarterScore(Base):
    __tablename__ = "quarter_scores"
    
    id = Column(Integer, primary_key=True, index=True)
    match_id = Column(Integer, ForeignKey("matches.id"))
    quarter = Column(Integer)
    our_score = Column(Integer)
    opponent_score = Column(Integer)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    match = relationship("Match", back_populates="quarter_scores") 