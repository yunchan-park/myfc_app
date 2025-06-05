import pytest
from app.services.player_service import PlayerService
from app.models import Team, Player
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.database import Base
from app.schemas import PlayerCreate, PlayerUpdate

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

def test_create_player(db_session, test_team):
    service = PlayerService(db_session)
    
    # 테스트용 선수 데이터
    player_data = {
        "name": "Test Player",
        "position": "FW",
        "number": 10,
        "team_id": test_team.id
    }
    
    # 선수 생성
    player = service.create_player(PlayerCreate(**player_data), test_team)
    
    assert player.name == "Test Player"
    assert player.position == "FW"
    assert player.number == 10
    assert player.team_id == test_team.id

def test_get_team_players(db_session, test_team):
    service = PlayerService(db_session)
    
    # 여러 선수 생성
    players_data = [
        {"name": "Player 1", "position": "FW", "number": 10, "team_id": test_team.id},
        {"name": "Player 2", "position": "MF", "number": 8, "team_id": test_team.id},
        {"name": "Player 3", "position": "DF", "number": 4, "team_id": test_team.id}
    ]
    
    for data in players_data:
        service.create_player(PlayerCreate(**data), test_team)
    
    # 팀 선수 목록 조회
    players = service.get_team_players(test_team.id, test_team)
    
    assert len(players) == 3
    assert players[0].name == "Player 1"
    assert players[1].name == "Player 2"
    assert players[2].name == "Player 3"

def test_update_player(db_session, test_team):
    service = PlayerService(db_session)
    
    # 선수 생성
    player_data = {
        "name": "Test Player",
        "position": "FW",
        "number": 10,
        "team_id": test_team.id
    }
    player = service.create_player(PlayerCreate(**player_data), test_team)
    
    # 선수 정보 업데이트
    update_data = {
        "name": "Updated Player",
        "position": "MF",
        "number": 8
    }
    updated_player = service.update_player(player.id, PlayerUpdate(**update_data), test_team)
    
    assert updated_player.name == "Updated Player"
    assert updated_player.position == "MF"
    assert updated_player.number == 8

def test_update_player_stats(db_session, test_team):
    service = PlayerService(db_session)
    
    # 선수 생성
    player_data = {
        "name": "Test Player",
        "position": "FW",
        "number": 10,
        "team_id": test_team.id
    }
    player = service.create_player(PlayerCreate(**player_data), test_team)
    
    # 선수 통계 업데이트
    stats_data = {
        "goal_count": 5,
        "assist_count": 3,
        "mom_count": 2
    }
    updated_player = service.update_player_stats(player.id, PlayerUpdate(**stats_data), test_team)
    
    assert updated_player.goal_count == 5
    assert updated_player.assist_count == 3
    assert updated_player.mom_count == 2

def test_delete_player(db_session, test_team):
    service = PlayerService(db_session)
    
    # 선수 생성
    player_data = {
        "name": "Test Player",
        "position": "FW",
        "number": 10,
        "team_id": test_team.id
    }
    player = service.create_player(PlayerCreate(**player_data), test_team)
    
    # 선수 삭제
    result = service.delete_player(player.id, test_team)
    
    assert result["message"] == "Player deleted successfully"
    
    # 삭제 확인
    players = service.get_team_players(test_team.id, test_team)
    assert len(players) == 0 