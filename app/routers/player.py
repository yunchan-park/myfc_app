from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from .. import models, schemas, auth
from ..database import get_db

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
    if current_team.id != player.team_id:
        raise HTTPException(status_code=403, detail="Not authorized to create player for this team")
    
    db_player = models.Player(**player.dict())
    db.add(db_player)
    db.commit()
    db.refresh(db_player)
    return db_player

@router.get("/team/{team_id}", response_model=List[schemas.Player])
def get_team_players(
    team_id: int,
    db: Session = Depends(get_db),
    current_team: models.Team = Depends(auth.get_current_team)
):
    if current_team.id != team_id:
        raise HTTPException(status_code=403, detail="Not authorized to view this team's players")
    
    players = db.query(models.Player).filter(models.Player.team_id == team_id).all()
    return players

@router.put("/{player_id}", response_model=schemas.Player)
def update_player(
    player_id: int,
    player_update: schemas.PlayerUpdate,
    db: Session = Depends(get_db),
    current_team: models.Team = Depends(auth.get_current_team)
):
    db_player = db.query(models.Player).filter(models.Player.id == player_id).first()
    if db_player is None:
        raise HTTPException(status_code=404, detail="Player not found")
    
    if db_player.team_id != current_team.id:
        raise HTTPException(status_code=403, detail="Not authorized to update this player")
    
    update_data = player_update.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_player, key, value)
    
    db.commit()
    db.refresh(db_player)
    return db_player

@router.put("/{player_id}/stats", response_model=schemas.Player)
def update_player_stats(
    player_id: int,
    player_stats: schemas.PlayerUpdate,
    db: Session = Depends(get_db),
    current_team: models.Team = Depends(auth.get_current_team)
):
    db_player = db.query(models.Player).filter(models.Player.id == player_id).first()
    if db_player is None:
        raise HTTPException(status_code=404, detail="Player not found")
    
    if db_player.team_id != current_team.id:
        raise HTTPException(status_code=403, detail="Not authorized to update this player's stats")
    
    # 통계 필드 업데이트
    stats_update = player_stats.dict(exclude_unset=True)
    
    # 적어도 하나의 통계 필드가 포함되어 있는지 확인
    has_stats = any(key in stats_update for key in ['goal_count', 'assist_count', 'mom_count'])
    if not has_stats:
        raise HTTPException(status_code=400, detail="At least one stat field must be provided")
    
    # 통계 필드만 업데이트
    stats_fields = {
        key: stats_update[key] 
        for key in ['goal_count', 'assist_count', 'mom_count'] 
        if key in stats_update
    }
    
    for key, value in stats_fields.items():
        setattr(db_player, key, value)
    
    db.commit()
    db.refresh(db_player)
    return db_player

@router.delete("/{player_id}")
def delete_player(
    player_id: int,
    db: Session = Depends(get_db),
    current_team: models.Team = Depends(auth.get_current_team)
):
    db_player = db.query(models.Player).filter(models.Player.id == player_id).first()
    if db_player is None:
        raise HTTPException(status_code=404, detail="Player not found")
    
    if db_player.team_id != current_team.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this player")
    
    db.delete(db_player)
    db.commit()
    return {"message": "Player deleted successfully"}

@router.get("/{player_id}", response_model=schemas.Player)
def get_player(
    player_id: int,
    db: Session = Depends(get_db),
    current_team: models.Team = Depends(auth.get_current_team)
):
    db_player = db.query(models.Player).filter(models.Player.id == player_id).first()
    if db_player is None:
        raise HTTPException(
            status_code=404, 
            detail=f"Player with ID {player_id} not found"
        )
    
    if db_player.team_id != current_team.id:
        raise HTTPException(
            status_code=403, 
            detail=f"Not authorized to view player with ID {player_id} (belongs to team ID {db_player.team_id})"
        )
    
    return db_player 