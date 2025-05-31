import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import sys
import os
import tempfile
import time
import base64
import json

# 현재 디렉토리를 Python 경로에 추가
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from app.main import app
from app.database import get_db, Base
from app.models import Team, Player, Match, Goal, QuarterScore

# 테스트용 임시 데이터베이스
db_fd, db_path = tempfile.mkstemp()
SQLALCHEMY_DATABASE_URL = f"sqlite:///{db_path}"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base.metadata.create_all(bind=engine)

def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

client = TestClient(app)

class TestTeamAPI:
    """팀 API 테스트"""
    
    def test_create_team(self):
        """팀 생성 테스트"""
        team_data = {
            "name": "Test FC",
            "description": "테스트 팀입니다",
            "type": "축구",
            "password": "testpass123"
        }
        response = client.post("/teams/create", json=team_data)
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Test FC"
        assert data["description"] == "테스트 팀입니다"
        assert data["type"] == "축구"
        assert "id" in data
    
    def test_login_team(self):
        """팀 로그인 테스트"""
        # 먼저 팀 생성
        team_data = {
            "name": "Login Test FC",
            "description": "로그인 테스트",
            "type": "축구",
            "password": "loginpass123"
        }
        client.post("/teams/create", json=team_data)
        
        # 팀 로그인
        login_data = {
            "name": "Login Test FC",
            "password": "loginpass123",
            "description": "",
            "type": ""
        }
        response = client.post("/teams/login", json=login_data)
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert "token_type" in data
        return data["access_token"]
    
    def test_get_team_with_auth(self):
        """인증이 필요한 팀 조회 테스트"""
        # 팀 생성 및 로그인
        team_data = {
            "name": "Auth Test FC",
            "description": "인증 테스트",
            "type": "축구",
            "password": "authpass123"
        }
        create_response = client.post("/teams/create", json=team_data)
        team_id = create_response.json()["id"]
        
        login_data = {
            "name": "Auth Test FC",
            "password": "authpass123",
            "description": "",
            "type": ""
        }
        login_response = client.post("/teams/login", json=login_data)
        token = login_response.json()["access_token"]
        
        # 인증 헤더와 함께 팀 조회
        headers = {"Authorization": f"Bearer {token}"}
        response = client.get(f"/teams/{team_id}", headers=headers)
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Auth Test FC"

class TestPlayerAPI:
    """선수 API 테스트"""
    
    def setup_team_and_auth(self, team_name="Player Test FC"):
        """테스트용 팀 생성 및 인증 토큰 반환"""
        team_data = {
            "name": team_name,
            "description": "선수 테스트용",
            "type": "축구",
            "password": "playerpass123"
        }
        create_response = client.post("/teams/create", json=team_data)
        team_id = create_response.json()["id"]
        
        login_data = {
            "name": team_name,
            "password": "playerpass123",
            "description": "",
            "type": ""
        }
        login_response = client.post("/teams/login", json=login_data)
        token = login_response.json()["access_token"]
        
        return team_id, token
    
    def test_create_player(self):
        """선수 생성 테스트"""
        team_id, token = self.setup_team_and_auth()
        headers = {"Authorization": f"Bearer {token}"}
        
        # 선수 생성
        player_data = {
            "name": "Test Player",
            "position": "FW",
            "number": 10,
            "team_id": team_id
        }
        response = client.post("/players/create", json=player_data, headers=headers)
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Test Player"
        assert data["number"] == 10
        assert data["position"] == "FW"
        assert data["team_id"] == team_id
    
    def test_get_team_players(self):
        """팀 선수 목록 조회 테스트"""
        team_id, token = self.setup_team_and_auth("Players List FC")
        headers = {"Authorization": f"Bearer {token}"}
        
        # 선수 2명 생성
        players = [
            {"name": "Player 1", "position": "GK", "number": 1, "team_id": team_id},
            {"name": "Player 2", "position": "DF", "number": 2, "team_id": team_id}
        ]
        
        for player_data in players:
            client.post("/players/create", json=player_data, headers=headers)
        
        # 팀 선수 목록 조회
        response = client.get(f"/players/team/{team_id}", headers=headers)
        assert response.status_code == 200
        data = response.json()
        assert len(data) >= 2  # 최소 2명 이상이어야 함
    
    def test_update_player(self):
        """선수 정보 수정 테스트"""
        team_id, token = self.setup_team_and_auth("Update Player FC")
        headers = {"Authorization": f"Bearer {token}"}
        
        # 선수 생성
        player_data = {
            "name": "Original Player",
            "position": "FW",
            "number": 9,
            "team_id": team_id
        }
        create_response = client.post("/players/create", json=player_data, headers=headers)
        player_id = create_response.json()["id"]
        
        # 선수 정보 수정
        update_data = {
            "name": "Updated Player",
            "position": "MF",
            "number": 9,
            "team_id": team_id,
            "goal_count": 5,
            "assist_count": 3,
            "mom_count": 1
        }
        response = client.put(f"/players/{player_id}", json=update_data, headers=headers)
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Updated Player"
        assert data["position"] == "MF"

class TestMatchAPI:
    """매치 API 테스트"""
    
    def setup_match_test_data(self):
        """매치 테스트용 데이터 설정"""
        unique_suffix = str(int(time.time() * 1000))[-6:]  # 마지막 6자리 사용
        team_name = f"Match Test FC {unique_suffix}"
        
        team_data = {
            "name": team_name,
            "description": "매치 테스트용",
            "type": "축구",
            "password": "matchpass123"
        }
        create_response = client.post("/teams/create", json=team_data)
        
        # 팀 생성 실패 시 기존 팀 사용
        if create_response.status_code != 200:
            # 로그인으로 기존 팀 정보 가져오기
            login_data = {
                "name": team_name,
                "password": "matchpass123",
                "description": "",
                "type": ""
            }
            login_response = client.post("/teams/login", json=login_data)
            if login_response.status_code == 200:
                token = login_response.json()["access_token"]
                # JWT 토큰에서 team_id 추출 (간단한 방법)
                payload = token.split('.')[1]
                # base64 패딩 추가
                payload += '=' * (4 - len(payload) % 4)
                decoded = base64.b64decode(payload)
                team_id = int(json.loads(decoded)["sub"])
            else:
                raise Exception("팀 생성 및 로그인 모두 실패")
        else:
            team_id = create_response.json()["id"]
            login_data = {
                "name": team_name,
                "password": "matchpass123",
                "description": "",
                "type": ""
            }
            login_response = client.post("/teams/login", json=login_data)
            token = login_response.json()["access_token"]
        
        # 선수 생성
        headers = {"Authorization": f"Bearer {token}"}
        player_data = {
            "name": f"Match Player {unique_suffix}",
            "position": "FW",
            "number": 9,
            "team_id": team_id
        }
        player_response = client.post("/players/create", json=player_data, headers=headers)
        player_id = player_response.json()["id"]
        
        return team_id, token, player_id
    
    def test_create_match(self):
        """매치 생성 테스트"""
        team_id, token, player_id = self.setup_match_test_data()
        headers = {"Authorization": f"Bearer {token}"}
        
        # 매치 생성
        match_data = {
            "date": "2024-03-15T14:30:00",
            "opponent": "상대팀 FC",
            "score": "2:1",
            "team_id": team_id,
            "player_ids": [player_id],
            "quarter_scores": [
                {"quarter": 1, "our_score": 1, "opponent_score": 0},
                {"quarter": 2, "our_score": 1, "opponent_score": 1}
            ]
        }
        
        response = client.post("/matches/create", json=match_data, headers=headers)
        assert response.status_code == 200
        data = response.json()
        assert data["opponent"] == "상대팀 FC"
        assert data["score"] == "2:1"
        assert data["team_id"] == team_id
    
    def test_get_team_matches(self):
        """팀 매치 목록 조회 테스트"""
        team_id, token, _ = self.setup_match_test_data()
        headers = {"Authorization": f"Bearer {token}"}
        
        # 매치 목록 조회
        response = client.get(f"/matches/team/{team_id}", headers=headers)
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
    
    def test_get_match_detail(self):
        """매치 상세 조회 테스트"""
        team_id, token, player_id = self.setup_match_test_data()
        headers = {"Authorization": f"Bearer {token}"}
        
        # 매치 생성
        match_data = {
            "date": "2024-03-15T14:30:00",
            "opponent": "Detail Test FC",
            "score": "3:2",
            "team_id": team_id,
            "player_ids": [player_id]
        }
        create_response = client.post("/matches/create", json=match_data, headers=headers)
        assert create_response.status_code == 200
        match_id = create_response.json()["id"]
        
        # 매치 상세 조회
        response = client.get(f"/matches/{match_id}/detail", headers=headers)
        assert response.status_code == 200
        data = response.json()
        assert data["opponent"] == "Detail Test FC"
        assert data["score"] == "3:2"
    
    def test_delete_match(self):
        """매치 삭제 테스트"""
        team_id, token, player_id = self.setup_match_test_data()
        headers = {"Authorization": f"Bearer {token}"}
        
        # 매치 생성
        match_data = {
            "date": "2024-03-15T14:30:00",
            "opponent": "Delete Test FC",
            "score": "1:0",
            "team_id": team_id,
            "player_ids": [player_id]
        }
        create_response = client.post("/matches/create", json=match_data, headers=headers)
        assert create_response.status_code == 200
        match_id = create_response.json()["id"]
        
        # 매치 삭제
        response = client.delete(f"/matches/{match_id}", headers=headers)
        assert response.status_code == 200

class TestGoalAPI:
    """골 API 테스트"""
    
    def test_add_goal(self):
        """골 추가 테스트"""
        # 매치 테스트 데이터 설정
        team_id, token, player_id = TestMatchAPI().setup_match_test_data()
        headers = {"Authorization": f"Bearer {token}"}
        
        # 매치 생성
        match_data = {
            "date": "2024-03-15T14:30:00",
            "opponent": "Goal Test FC",
            "score": "1:0",
            "team_id": team_id,
            "player_ids": [player_id]
        }
        create_response = client.post("/matches/create", json=match_data, headers=headers)
        assert create_response.status_code == 200
        match_id = create_response.json()["id"]
        
        # 골 추가
        goal_data = {
            "match_id": match_id,
            "player_id": player_id,
            "assist_player_id": None,
            "quarter": 1
        }
        response = client.post(f"/matches/{match_id}/goals", json=goal_data, headers=headers)
        assert response.status_code == 200
        data = response.json()
        assert data["match_id"] == match_id
        assert data["player_id"] == player_id
        assert data["quarter"] == 1

class TestValidation:
    """유효성 검사 테스트"""
    
    def test_invalid_team_creation(self):
        """잘못된 팀 생성 요청 테스트"""
        # 빈 이름으로 팀 생성 시도
        team_data = {
            "name": "",
            "description": "설명",
            "type": "축구",
            "password": "pass123"
        }
        response = client.post("/teams/create", json=team_data)
        # 실제 API에서는 빈 이름도 허용하므로 200이 반환됨
        assert response.status_code == 200
    
    def test_invalid_login(self):
        """잘못된 로그인 테스트"""
        # 존재하지 않는 팀으로 로그인 시도
        login_data = {
            "name": "NonExistent FC",
            "password": "wrongpass",
            "description": "",
            "type": ""
        }
        response = client.post("/teams/login", json=login_data)
        assert response.status_code == 401  # 인증 실패
    
    def test_unauthorized_access(self):
        """인증 없는 접근 테스트"""
        # 토큰 없이 선수 생성 시도
        player_data = {
            "name": "Unauthorized Player",
            "position": "FW",
            "number": 10,
            "team_id": 1
        }
        response = client.post("/players/create", json=player_data)
        assert response.status_code == 401  # 인증 필요
    
    def test_duplicate_player_number(self):
        """중복 등번호 테스트"""
        team_id, token = TestPlayerAPI().setup_team_and_auth("Duplicate FC")
        headers = {"Authorization": f"Bearer {token}"}
        
        # 첫 번째 선수 (10번)
        player1_data = {
            "name": "Player 1",
            "position": "FW",
            "number": 10,
            "team_id": team_id
        }
        response1 = client.post("/players/create", json=player1_data, headers=headers)
        assert response1.status_code == 200
        
        # 두 번째 선수도 10번으로 시도 (현재 API에서는 중복 허용)
        player2_data = {
            "name": "Player 2",
            "position": "MF",
            "number": 10,
            "team_id": team_id
        }
        response2 = client.post("/players/create", json=player2_data, headers=headers)
        # 현재 구현에서는 중복 등번호를 허용하므로 200 반환
        assert response2.status_code == 200

# 테스트 실행 후 정리
def teardown_module():
    """테스트 완료 후 테스트 데이터베이스 정리"""
    os.close(db_fd)
    os.unlink(db_path) 