from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.orm import Session
from typing import List
from .. import models, schemas, auth
from ..database import get_db
from ..services.team_service import TeamService

router = APIRouter(
    prefix="/teams",
    tags=["teams"]
)

@router.post("/create", response_model=schemas.Team)
async def create_team(team: schemas.TeamCreate, db: Session = Depends(get_db)):
    team_service = TeamService(db)
    return await team_service.create_team(team)

@router.post("/login", response_model=schemas.Token)
async def login_team(team: schemas.TeamCreate, db: Session = Depends(get_db)):
    team_service = TeamService(db)
    return await team_service.login_team(team)

@router.get("/{team_id}", response_model=schemas.Team)
def get_team(team_id: int, db: Session = Depends(get_db)):
    team_service = TeamService(db)
    return team_service.get_team(team_id)

@router.put("/{team_id}", response_model=schemas.Team)
def update_team(
    team_id: int,
    team_update: schemas.TeamUpdate,
    db: Session = Depends(get_db),
    current_team: models.Team = Depends(auth.get_current_team)
):
    team_service = TeamService(db)
    return team_service.update_team(team_id, team_update, current_team)

@router.delete("/{team_id}")
def delete_team(
    team_id: int,
    db: Session = Depends(get_db),
    current_team: models.Team = Depends(auth.get_current_team)
):
    team_service = TeamService(db)
    return team_service.delete_team(team_id, current_team)

@router.post("/upload-logo")
async def upload_logo(
    team_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_team: models.Team = Depends(auth.get_current_team)
):
    team_service = TeamService(db)
    return await team_service.upload_logo(team_id, file, current_team)

@router.post("/upload-image")
async def upload_image(
    team_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_team: models.Team = Depends(auth.get_current_team)
):
    team_service = TeamService(db)
    return await team_service.upload_image(team_id, file, current_team) 