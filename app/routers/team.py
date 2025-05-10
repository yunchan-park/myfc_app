from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, BackgroundTasks
from sqlalchemy.orm import Session
from typing import List
import logging
import time
import asyncio
from .. import models, schemas, auth
from ..database import get_db
from ..utils.file_handler import save_upload_file, delete_file
from datetime import timedelta

# 로깅 설정
logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/teams",
    tags=["teams"]
)

@router.post("/create", response_model=schemas.Team)
async def create_team(team: schemas.TeamCreate, db: Session = Depends(get_db)):
    # 요청 시작 시간 기록
    start_time = time.time()
    
    logger.debug(f"팀 생성 시작: {team.name}")
    
    # 중복 검사 최적화 (인덱스 활용)
    db_team = db.query(models.Team).filter(models.Team.name == team.name).first()
    if db_team:
        logger.warning(f"중복된 팀 이름: {team.name}")
        raise HTTPException(status_code=400, detail="Team name already registered")
    
    try:
        # 비밀번호 해싱을 비동기로 처리
        hashed_password = await auth.get_password_hash_async(team.password)
        
        # 팀 객체 생성
        db_team = models.Team(
            name=team.name,
            description=team.description,
            type=team.type,
            password=hashed_password
        )
        
        # 데이터베이스 작업
        db.add(db_team)
        db.commit()
        db.refresh(db_team)
        
        # 처리 시간 기록
        elapsed = time.time() - start_time
        logger.info(f"팀 생성 완료: {team.name}, 소요 시간: {elapsed:.3f}초")
        
        return db_team
    except Exception as e:
        db.rollback()
        logger.error(f"팀 생성 중 오류: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to create team: {str(e)}")

@router.post("/login", response_model=schemas.Token)
async def login_team(team: schemas.TeamCreate, db: Session = Depends(get_db)):
    # 요청 시작 시간 기록
    start_time = time.time()
    
    logger.debug(f"팀 로그인 시도: {team.name}")
    
    db_team = db.query(models.Team).filter(models.Team.name == team.name).first()
    if not db_team:
        logger.warning(f"존재하지 않는 팀 로그인 시도: {team.name}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect team name or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # 비밀번호 검증
    if not auth.verify_password(team.password, db_team.password):
        logger.warning(f"잘못된 비밀번호 입력: {team.name}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect team name or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token_expires = timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = auth.create_access_token(
        data={"sub": str(db_team.id)}, expires_delta=access_token_expires
    )
    
    # 처리 시간 기록
    elapsed = time.time() - start_time
    logger.info(f"팀 로그인 성공: {team.name}, 소요 시간: {elapsed:.3f}초")
    
    return {"access_token": access_token, "token_type": "bearer"}

@router.get("/{team_id}", response_model=schemas.Team)
def get_team(team_id: int, db: Session = Depends(get_db)):
    db_team = db.query(models.Team).filter(models.Team.id == team_id).first()
    if db_team is None:
        raise HTTPException(status_code=404, detail="Team not found")
    return db_team

@router.put("/{team_id}", response_model=schemas.Team)
def update_team(
    team_id: int,
    team_update: schemas.TeamUpdate,
    db: Session = Depends(get_db),
    current_team: models.Team = Depends(auth.get_current_team)
):
    if current_team.id != team_id:
        raise HTTPException(status_code=403, detail="Not authorized to update this team")
    
    db_team = db.query(models.Team).filter(models.Team.id == team_id).first()
    if db_team is None:
        raise HTTPException(status_code=404, detail="Team not found")
    
    update_data = team_update.dict(exclude_unset=True)
    if "password" in update_data:
        update_data["password"] = auth.get_password_hash(update_data["password"])
    
    for key, value in update_data.items():
        setattr(db_team, key, value)
    
    db.commit()
    db.refresh(db_team)
    return db_team

@router.delete("/{team_id}")
def delete_team(
    team_id: int,
    db: Session = Depends(get_db),
    current_team: models.Team = Depends(auth.get_current_team)
):
    if current_team.id != team_id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this team")
    
    db_team = db.query(models.Team).filter(models.Team.id == team_id).first()
    if db_team is None:
        raise HTTPException(status_code=404, detail="Team not found")
    
    # Delete associated files
    if db_team.logo_url:
        delete_file(db_team.logo_url.lstrip("/"))
    if db_team.image_url:
        delete_file(db_team.image_url.lstrip("/"))
    
    db.delete(db_team)
    db.commit()
    return {"message": "Team deleted successfully"}

@router.post("/upload-logo")
async def upload_logo(
    team_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_team: models.Team = Depends(auth.get_current_team)
):
    if current_team.id != team_id:
        raise HTTPException(status_code=403, detail="Not authorized to upload for this team")
    
    db_team = db.query(models.Team).filter(models.Team.id == team_id).first()
    if db_team is None:
        raise HTTPException(status_code=404, detail="Team not found")
    
    # Delete old logo if exists
    if db_team.logo_url:
        delete_file(db_team.logo_url.lstrip("/"))
    
    file_path = await save_upload_file(file, team_id, "logo")
    db_team.logo_url = file_path
    db.commit()
    return {"message": "Logo uploaded successfully", "file_path": file_path}

@router.post("/upload-image")
async def upload_image(
    team_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_team: models.Team = Depends(auth.get_current_team)
):
    if current_team.id != team_id:
        raise HTTPException(status_code=403, detail="Not authorized to upload for this team")
    
    db_team = db.query(models.Team).filter(models.Team.id == team_id).first()
    if db_team is None:
        raise HTTPException(status_code=404, detail="Team not found")
    
    # Delete old image if exists
    if db_team.image_url:
        delete_file(db_team.image_url.lstrip("/"))
    
    file_path = await save_upload_file(file, team_id, "image")
    db_team.image_url = file_path
    db.commit()
    return {"message": "Image uploaded successfully", "file_path": file_path} 