from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from .. import models, schemas, auth
from ..database import get_db

router = APIRouter(
    prefix="/matches",
    tags=["matches"]
)

@router.post("/create", response_model=schemas.Match)
def create_match(
    match: schemas.MatchCreate,
    db: Session = Depends(get_db),
    current_team: models.Team = Depends(auth.get_current_team)
):
    if current_team.id != match.team_id:
        raise HTTPException(status_code=403, detail="Not authorized to create match for this team")
    
    # Verify all players belong to the team
    for player_id in match.player_ids:
        player = db.query(models.Player).filter(models.Player.id == player_id).first()
        if not player or player.team_id != match.team_id:
            raise HTTPException(status_code=400, detail=f"Player {player_id} not found or not in team")
    
    # Create match
    db_match = models.Match(
        date=match.date,
        opponent=match.opponent,
        score=match.score,
        team_id=match.team_id
    )
    db.add(db_match)
    db.commit()
    db.refresh(db_match)
    
    # Add players to match
    for player_id in match.player_ids:
        db_match.players.append(db.query(models.Player).get(player_id))
    db.commit()
    
    return db_match

@router.get("/team/{team_id}", response_model=List[schemas.Match])
def get_team_matches(
    team_id: int,
    db: Session = Depends(get_db),
    current_team: models.Team = Depends(auth.get_current_team)
):
    if current_team.id != team_id:
        raise HTTPException(status_code=403, detail="Not authorized to view this team's matches")
    
    matches = db.query(models.Match).filter(models.Match.team_id == team_id).all()
    return matches

@router.put("/{match_id}", response_model=schemas.Match)
def update_match(
    match_id: int,
    match_update: schemas.MatchUpdate,
    db: Session = Depends(get_db),
    current_team: models.Team = Depends(auth.get_current_team)
):
    db_match = db.query(models.Match).filter(models.Match.id == match_id).first()
    if db_match is None:
        raise HTTPException(status_code=404, detail="Match not found")
    
    if db_match.team_id != current_team.id:
        raise HTTPException(status_code=403, detail="Not authorized to update this match")
    
    update_data = match_update.dict(exclude_unset=True)
    
    # Handle player updates if provided
    if "player_ids" in update_data:
        player_ids = update_data.pop("player_ids")
        # Verify all players belong to the team
        for player_id in player_ids:
            player = db.query(models.Player).filter(models.Player.id == player_id).first()
            if not player or player.team_id != current_team.id:
                raise HTTPException(status_code=400, detail=f"Player {player_id} not found or not in team")
        
        # Update match players
        db_match.players = [db.query(models.Player).get(player_id) for player_id in player_ids]
    
    # Update other fields
    for key, value in update_data.items():
        setattr(db_match, key, value)
    
    db.commit()
    db.refresh(db_match)
    return db_match

@router.delete("/{match_id}")
def delete_match(
    match_id: int,
    db: Session = Depends(get_db),
    current_team: models.Team = Depends(auth.get_current_team)
):
    db_match = db.query(models.Match).filter(models.Match.id == match_id).first()
    if db_match is None:
        raise HTTPException(status_code=404, detail="Match not found")
    
    if db_match.team_id != current_team.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this match")
    
    db.delete(db_match)
    db.commit()
    return {"message": "Match deleted successfully"}

@router.get("/{match_id}/detail", response_model=schemas.Match)
def get_match_detail(
    match_id: int,
    db: Session = Depends(get_db),
    current_team: models.Team = Depends(auth.get_current_team)
):
    db_match = db.query(models.Match).filter(models.Match.id == match_id).first()
    if db_match is None:
        raise HTTPException(status_code=404, detail="Match not found")
    
    if db_match.team_id != current_team.id:
        raise HTTPException(status_code=403, detail="Not authorized to view this match")
    
    return db_match

@router.post("/{match_id}/goals", response_model=schemas.Goal)
def add_goal(
    match_id: int,
    goal: schemas.GoalCreate,
    db: Session = Depends(get_db),
    current_team: models.Team = Depends(auth.get_current_team)
):
    db_match = db.query(models.Match).filter(models.Match.id == match_id).first()
    if db_match is None:
        raise HTTPException(status_code=404, detail="Match not found")
    
    if db_match.team_id != current_team.id:
        raise HTTPException(status_code=403, detail="Not authorized to add goal to this match")
    
    # Verify scorer belongs to the team
    scorer = db.query(models.Player).filter(models.Player.id == goal.player_id).first()
    if not scorer or scorer.team_id != current_team.id:
        raise HTTPException(status_code=400, detail="Scorer not found or not in team")
    
    # Verify assist player if provided
    if goal.assist_player_id:
        assist_player = db.query(models.Player).filter(models.Player.id == goal.assist_player_id).first()
        if not assist_player or assist_player.team_id != current_team.id:
            raise HTTPException(status_code=400, detail="Assist player not found or not in team")
    
    db_goal = models.Goal(**goal.dict())
    db.add(db_goal)
    db.commit()
    db.refresh(db_goal)
    return db_goal 