from app import models, schemas
from sqlalchemy.orm import Session
from fastapi import HTTPException
from typing import List

class PlayerService:
    def __init__(self, db: Session):
        self.db = db

    def create_player(self, player: schemas.PlayerCreate, current_team: models.Team):
        if current_team.id != player.team_id:
            raise HTTPException(status_code=403, detail="Not authorized to create player for this team")
        
        db_player = models.Player(**player.dict())
        self.db.add(db_player)
        self.db.commit()
        self.db.refresh(db_player)
        return db_player

    def get_team_players(self, team_id: int, current_team: models.Team):
        if current_team.id != team_id:
            raise HTTPException(status_code=403, detail="Not authorized to view this team's players")
        
        players = self.db.query(models.Player).filter(models.Player.team_id == team_id).all()
        return players

    def update_player(self, player_id: int, player_update: schemas.PlayerUpdate, current_team: models.Team):
        db_player = self.db.query(models.Player).filter(models.Player.id == player_id).first()
        if db_player is None:
            raise HTTPException(status_code=404, detail="Player not found")
        
        if db_player.team_id != current_team.id:
            raise HTTPException(status_code=403, detail="Not authorized to update this player")
        
        update_data = player_update.dict(exclude_unset=True)
        for key, value in update_data.items():
            setattr(db_player, key, value)
        
        self.db.commit()
        self.db.refresh(db_player)
        return db_player

    def update_player_stats(self, player_id: int, player_stats: schemas.PlayerUpdate, current_team: models.Team):
        db_player = self.db.query(models.Player).filter(models.Player.id == player_id).first()
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
        
        self.db.commit()
        self.db.refresh(db_player)
        return db_player

    def delete_player(self, player_id: int, current_team: models.Team):
        db_player = self.db.query(models.Player).filter(models.Player.id == player_id).first()
        if db_player is None:
            raise HTTPException(status_code=404, detail="Player not found")
        
        if db_player.team_id != current_team.id:
            raise HTTPException(status_code=403, detail="Not authorized to delete this player")
        
        self.db.delete(db_player)
        self.db.commit()
        return {"message": "Player deleted successfully"}

    def get_player(self, player_id: int, current_team: models.Team):
        db_player = self.db.query(models.Player).filter(models.Player.id == player_id).first()
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

    # 기타 player 관련 메소드 추가 