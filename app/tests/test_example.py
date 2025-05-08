import pytest
from app.models import Team

def test_team_model():
    team = Team(name="Test", description="desc", type="Soccer", password="pw")
    assert team.name == "Test"
    assert team.type == "Soccer" 