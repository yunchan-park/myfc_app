from app import models, schemas, auth
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from datetime import timedelta
import time

class TeamService:
    def __init__(self, db: Session):
        self.db = db

    async def create_team(self, team: schemas.TeamCreate):
        # start_time = time.time()
        # 중복 검사
        db_team = self.db.query(models.Team).filter(models.Team.name == team.name).first()
        if db_team:
            raise HTTPException(status_code=400, detail="Team name already registered")
        try:
            # 비밀번호 해싱
            hashed_password = await auth.get_password_hash_async(team.password)
            # 팀 객체 생성
            db_team = models.Team(
                name=team.name,
                description=team.description,
                type=team.type,
                password=hashed_password
            )
            # 데이터베이스 작업
            self.db.add(db_team)
            self.db.commit()
            self.db.refresh(db_team)
            # elapsed = time.time() - start_time
            return db_team
        except Exception as e:
            self.db.rollback()
            raise HTTPException(status_code=500, detail=f"Failed to create team: {str(e)}")

    async def login_team(self, team: schemas.TeamCreate):
        # start_time = time.time()
        db_team = self.db.query(models.Team).filter(models.Team.name == team.name).first()
        if not db_team:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect team name or password",
                headers={"WWW-Authenticate": "Bearer"},
            )
        if not auth.verify_password(team.password, db_team.password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect team name or password",
                headers={"WWW-Authenticate": "Bearer"},
            )
        access_token_expires = timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = auth.create_access_token(
            data={"sub": str(db_team.id)}, expires_delta=access_token_expires
        )
        # elapsed = time.time() - start_time
        return {"access_token": access_token, "token_type": "bearer"}

    def get_team(self, team_id: int):
        db_team = self.db.query(models.Team).filter(models.Team.id == team_id).first()
        if db_team is None:
            raise HTTPException(status_code=404, detail="Team not found")
        return db_team

    def update_team(self, team_id: int, team_update: schemas.TeamUpdate, current_team: models.Team):
        if current_team.id != team_id:
            raise HTTPException(status_code=403, detail="Not authorized to update this team")
        
        db_team = self.db.query(models.Team).filter(models.Team.id == team_id).first()
        if db_team is None:
            raise HTTPException(status_code=404, detail="Team not found")
        
        update_data = team_update.dict(exclude_unset=True)
        if "password" in update_data:
            update_data["password"] = auth.get_password_hash(update_data["password"])
        
        for key, value in update_data.items():
            setattr(db_team, key, value)
        
        self.db.commit()
        self.db.refresh(db_team)
        return db_team

    def delete_team(self, team_id: int, current_team: models.Team):
        if current_team.id != team_id:
            raise HTTPException(status_code=403, detail="Not authorized to delete this team")
        
        db_team = self.db.query(models.Team).filter(models.Team.id == team_id).first()
        if db_team is None:
            raise HTTPException(status_code=404, detail="Team not found")
        
        # Delete associated files
        if db_team.logo_url:
            from ..utils.file_handler import delete_file
            delete_file(db_team.logo_url.lstrip("/"))
        if db_team.image_url:
            delete_file(db_team.image_url.lstrip("/"))
        
        self.db.delete(db_team)
        self.db.commit()
        return {"message": "Team deleted successfully"}

    async def upload_logo(self, team_id: int, file, current_team: models.Team):
        if current_team.id != team_id:
            raise HTTPException(status_code=403, detail="Not authorized to upload for this team")
        
        db_team = self.db.query(models.Team).filter(models.Team.id == team_id).first()
        if db_team is None:
            raise HTTPException(status_code=404, detail="Team not found")
        
        # Delete old logo if exists
        if db_team.logo_url:
            from ..utils.file_handler import delete_file
            delete_file(db_team.logo_url.lstrip("/"))
        
        from ..utils.file_handler import save_upload_file
        file_path = await save_upload_file(file, team_id, "logo")
        db_team.logo_url = file_path
        self.db.commit()
        return {"message": "Logo uploaded successfully", "file_path": file_path}

    async def upload_image(self, team_id: int, file, current_team: models.Team):
        if current_team.id != team_id:
            raise HTTPException(status_code=403, detail="Not authorized to upload for this team")
        
        db_team = self.db.query(models.Team).filter(models.Team.id == team_id).first()
        if db_team is None:
            raise HTTPException(status_code=404, detail="Team not found")
        
        # Delete old image if exists
        if db_team.image_url:
            from ..utils.file_handler import delete_file
            delete_file(db_team.image_url.lstrip("/"))
        
        from ..utils.file_handler import save_upload_file
        file_path = await save_upload_file(file, team_id, "image")
        db_team.image_url = file_path
        self.db.commit()
        return {"message": "Image uploaded successfully", "file_path": file_path}

    # 기타 team 관련 메소드 추가 