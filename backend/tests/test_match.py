import pytest
from app.services.match_service import MatchService
from app.models import Team, Player, Match, Goal
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.database import Base
from datetime import date
from app.schemas import MatchCreate, GoalCreate

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

def test_create_match(db_session, test_team, test_players):
    service = MatchService(db_session, test_team)
    
    # 테스트용 경기 데이터
    match_data = {
        "date": date(2024, 1, 1),
        "opponent": "Team A",
        "score": "2:1",
        "team_id": test_team.id,
        "player_ids": [p.id for p in test_players],
        "quarter_scores": [
            {"quarter": 1, "our_score": 1, "opponent_score": 0},
            {"quarter": 2, "our_score": 1, "opponent_score": 1}
        ]
    }
    
    # 경기 생성
    match = service.create_match(MatchCreate(**match_data), test_team)
    
    assert match.date.date() == date(2024, 1, 1)
    assert match.opponent == "Team A"
    assert match.score == "2:1"
    assert match.team_id == test_team.id
    assert len(match.players) == 3

def test_add_goal(db_session, test_team, test_players):
    service = MatchService(db_session, test_team)
    
    # 먼저 경기 생성
    match_data = {
        "date": date(2024, 1, 1),
        "opponent": "Team A",
        "score": "2:1",
        "team_id": test_team.id,
        "player_ids": [p.id for p in test_players],
        "quarter_scores": [
            {"quarter": 1, "our_score": 1, "opponent_score": 0},
            {"quarter": 2, "our_score": 1, "opponent_score": 1}
        ]
    }
    match = service.create_match(MatchCreate(**match_data), test_team)
    
    # 골 추가
    goal_data = {
        "player_id": test_players[0].id,
        "assist_player_id": test_players[1].id,
        "quarter": 1,
        "match_id": match.id
    }
    goal = service.add_goal(match.id, GoalCreate(**goal_data), test_team)
    
    assert goal.match_id == match.id
    assert goal.player_id == test_players[0].id
    assert goal.assist_player_id == test_players[1].id
    assert goal.quarter == 1

def test_get_match_detail(db_session, test_team, test_players):
    service = MatchService(db_session, test_team)
    
    # 경기 생성
    match_data = {
        "date": date(2024, 1, 1),
        "opponent": "Team A",
        "score": "2:1",
        "team_id": test_team.id,
        "player_ids": [p.id for p in test_players],
        "quarter_scores": [
            {"quarter": 1, "our_score": 1, "opponent_score": 0},
            {"quarter": 2, "our_score": 1, "opponent_score": 1}
        ]
    }
    match = service.create_match(MatchCreate(**match_data), test_team)
    
    # 골 추가
    goal_data = {
        "player_id": test_players[0].id,
        "assist_player_id": test_players[1].id,
        "quarter": 1,
        "match_id": match.id
    }
    service.add_goal(match.id, GoalCreate(**goal_data), test_team)
    
    # 경기 상세 정보 조회
    match_detail = service.get_match_detail(match.id)
    
    assert match_detail["id"] == match.id
    assert match_detail["date"].date() == date(2024, 1, 1)
    assert match_detail["opponent"] == "Team A"
    assert match_detail["score"] == "2:1"
    assert len(match_detail["players"]) == 3
    assert len(match_detail["goals"]) == 1

def test_get_recent_matches(db_session, test_team, test_players):
    service = MatchService(db_session, test_team)
    
    # 여러 경기 생성
    dates = [date(2024, 1, 1), date(2024, 1, 8), date(2024, 1, 15), date(2024, 1, 22), date(2024, 1, 29)]
    for d in dates:
        match_data = {
            "date": d,
            "opponent": f"Team {d}",
            "score": "2:1",
            "team_id": test_team.id,
            "player_ids": [p.id for p in test_players],
            "quarter_scores": [
                {"quarter": 1, "our_score": 1, "opponent_score": 0},
                {"quarter": 2, "our_score": 1, "opponent_score": 1}
            ]
        }
        service.create_match(MatchCreate(**match_data), test_team)
    
    # 최근 경기 조회
    recent_matches = service.get_recent_matches(test_team.id, test_team, limit=3)
    
    # 날짜를 모두 .date()로 변환해서 비교
    recent_dates = [m.date.date() for m in recent_matches]
    # 생성한 날짜 중 3개가 recent_dates에 포함되어 있는지 확인
    assert set(recent_dates).issubset(set(dates))
    assert len(recent_dates) == 3 