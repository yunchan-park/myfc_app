import pytest
from app.services.analytics_service import AnalyticsService
from app.models import Team, Player, Match
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.database import Base
import datetime

# 테스트용 DB 설정
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

@pytest.fixture
def db_session():
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()
        Base.metadata.drop_all(bind=engine)

@pytest.fixture
def test_team(db_session):
    team = Team(name="Test Team", description="Test Description", type="AMATEUR")
    db_session.add(team)
    db_session.commit()
    return team

@pytest.fixture
def test_players(db_session, test_team):
    players = [
        Player(name="Player 1", team_id=test_team.id, position="FW", number=10),
        Player(name="Player 2", team_id=test_team.id, position="MF", number=8),
        Player(name="Player 3", team_id=test_team.id, position="DF", number=4)
    ]
    for player in players:
        db_session.add(player)
    db_session.commit()
    return players

@pytest.fixture
def test_matches(db_session, test_team, test_players):
    matches = [
        Match(date=datetime.date(2024, 1, 1), opponent="Team A", score="2:1", team_id=test_team.id),
        Match(date=datetime.date(2024, 1, 8), opponent="Team B", score="1:1", team_id=test_team.id),
        Match(date=datetime.date(2024, 1, 15), opponent="Team C", score="3:0", team_id=test_team.id)
    ]
    for match in matches:
        db_session.add(match)
        # 각 경기에 선수들 추가
        for player in test_players:
            match.players.append(player)
    db_session.commit()
    return matches

def test_get_team_analytics_overview(db_session, test_team, test_matches):
    service = AnalyticsService(db_session)
    result = service.get_team_analytics_overview(test_team.id)
    
    assert result.total_matches == 3
    assert result.wins == 2
    assert result.draws == 1
    assert result.losses == 0
    assert result.win_rate == 66.7
    assert result.avg_goals_scored == 2.0
    assert result.avg_goals_conceded == 0.7

def test_get_goals_win_correlation(db_session, test_team, test_matches):
    service = AnalyticsService(db_session)
    result = service.get_goals_win_correlation(test_team.id)
    
    assert len(result.goal_ranges) > 0
    assert result.optimal_goals > 0
    assert result.avg_goals_for_win > 0

def test_get_conceded_loss_correlation(db_session, test_team, test_matches):
    service = AnalyticsService(db_session)
    result = service.get_conceded_loss_correlation(test_team.id)
    
    assert len(result.conceded_ranges) > 0
    assert result.danger_threshold > 0
    assert result.avg_conceded_for_loss >= 0

def test_get_player_contributions(db_session, test_team, test_players, test_matches):
    service = AnalyticsService(db_session)
    result = service.get_player_contributions(test_team.id)
    
    assert len(result.players) == 3
    assert result.top_contributor["name"] != ""
    assert result.most_reliable["name"] != ""
    assert result.most_reliable["win_rate"] != "0" 