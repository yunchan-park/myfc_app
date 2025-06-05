import pytest
from app.services.team_service import TeamService
from app.models import Team
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.database import Base
import os
import tempfile
from app.schemas import TeamCreate
from fastapi import HTTPException

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
def test_team_data():
    return {
        "name": "Test Team",
        "description": "Test Description",
        "type": "AMATEUR",
        "password": "test123"
    }

@pytest.mark.asyncio
async def test_create_team(db_session, test_team_data):
    service = TeamService(db_session)
    
    # 팀 생성
    team = await service.create_team(TeamCreate(**test_team_data))
    
    assert team.name == "Test Team"
    assert team.description == "Test Description"
    assert team.type == "AMATEUR"
    assert team.password != "test123"  # 비밀번호는 해시되어야 함

@pytest.mark.asyncio
async def test_create_duplicate_team(db_session, test_team_data):
    service = TeamService(db_session)
    
    # 첫 번째 팀 생성
    await service.create_team(TeamCreate(**test_team_data))
    
    # 동일한 이름의 팀 생성 시도
    with pytest.raises(HTTPException) as exc_info:
        await service.create_team(TeamCreate(**test_team_data))
    
    assert exc_info.value.detail == "Team name already registered"

@pytest.fixture
async def test_team(db_session, test_team_data):
    service = TeamService(db_session)
    return await service.create_team(TeamCreate(**test_team_data)) 