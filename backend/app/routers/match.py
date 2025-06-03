from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload
from typing import List
from .. import models, schemas, auth
from ..database import get_db
from app.services.match_service import MatchService

router = APIRouter(
    prefix="/matches",
    tags=["matches"]
)

def get_match_service(
    db: Session = Depends(get_db),
    current_team: models.Team = Depends(auth.get_current_team)
) -> MatchService:
    return MatchService(db, current_team)

@router.post("/create", response_model=schemas.Match)
def create_match(
    match: schemas.MatchCreate,
    match_service: MatchService = Depends(get_match_service)
):
    return match_service.create_match(match, match_service.current_team)

@router.get("/team/{team_id}", response_model=List[schemas.Match])
def get_team_matches(
    team_id: int,
    match_service: MatchService = Depends(get_match_service)
):
    return match_service.get_team_matches(team_id, match_service.current_team)

@router.put("/{match_id}", response_model=schemas.Match)
def update_match(
    match_id: int,
    match_update: schemas.MatchUpdate,
    match_service: MatchService = Depends(get_match_service)
):
    return match_service.update_match(match_id, match_update, match_service.current_team)

@router.delete("/{match_id}")
def delete_match(
    match_id: int,
    match_service: MatchService = Depends(get_match_service)
):
    return match_service.delete_match(match_id, match_service.current_team)

@router.get("/{match_id}/detail", response_model=schemas.MatchDetail)
async def get_match_detail(
    match_id: int,
    match_service: MatchService = Depends(get_match_service)
):
    """Get detailed match information including players and goals"""
    return match_service.get_match_detail(match_id)

@router.post("/{match_id}/goals", response_model=schemas.Goal)
def add_goal(
    match_id: int,
    goal: schemas.GoalCreate,
    match_service: MatchService = Depends(get_match_service)
):
    return match_service.add_goal(match_id, goal, match_service.current_team)

@router.get("/team/{team_id}/recent", response_model=List[schemas.Match])
def get_recent_matches(
    team_id: int,
    match_service: MatchService = Depends(get_match_service)
):
    return match_service.get_recent_matches(team_id, match_service.current_team) 