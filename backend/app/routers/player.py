from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from .. import models, schemas, auth
from ..database import get_db
from ..services.player_service import PlayerService

router = APIRouter(
    prefix="/players",
    tags=["players"]
)

@router.post("/create", response_model=schemas.Player)
def create_player(
    player: schemas.PlayerCreate,
    db: Session = Depends(get_db),
    current_team: models.Team = Depends(auth.get_current_team)
):
    player_service = PlayerService(db)
    return player_service.create_player(player, current_team)

@router.get("/team/{team_id}", response_model=List[schemas.Player])
def get_team_players(
    team_id: int,
    db: Session = Depends(get_db),
    current_team: models.Team = Depends(auth.get_current_team)
):
    player_service = PlayerService(db)
    return player_service.get_team_players(team_id, current_team)

@router.put("/{player_id}", response_model=schemas.Player)
def update_player(
    player_id: int,
    player_update: schemas.PlayerUpdate,
    db: Session = Depends(get_db),
    current_team: models.Team = Depends(auth.get_current_team)
):
    player_service = PlayerService(db)
    return player_service.update_player(player_id, player_update, current_team)

@router.put("/{player_id}/stats", response_model=schemas.Player)
def update_player_stats(
    player_id: int,
    player_stats: schemas.PlayerUpdate,
    db: Session = Depends(get_db),
    current_team: models.Team = Depends(auth.get_current_team)
):
    player_service = PlayerService(db)
    return player_service.update_player_stats(player_id, player_stats, current_team)

@router.delete("/{player_id}")
def delete_player(
    player_id: int,
    db: Session = Depends(get_db),
    current_team: models.Team = Depends(auth.get_current_team)
):
    player_service = PlayerService(db)
    return player_service.delete_player(player_id, current_team)

@router.get("/{player_id}", response_model=schemas.Player)
def get_player(
    player_id: int,
    db: Session = Depends(get_db),
    current_team: models.Team = Depends(auth.get_current_team)
):
    player_service = PlayerService(db)
    return player_service.get_player(player_id, current_team) 