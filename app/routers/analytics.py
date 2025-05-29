from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from app.database import get_db
from app.auth import get_current_team
from app.services.analytics_service import AnalyticsService
from app.schemas import (
    TeamAnalyticsOverview, GoalsWinCorrelation, ConcededLossCorrelation,
    PlayerContributionsResponse, Team
)

router = APIRouter(prefix="/analytics", tags=["analytics"])

@router.get("/team/{team_id}/overview", response_model=TeamAnalyticsOverview)
def get_team_analytics_overview(
    team_id: int,
    db: Session = Depends(get_db),
    current_team: Team = Depends(get_current_team)
):
    """
    팀 전체 통계 개요
    - 총 경기 수, 승/무/패
    - 평균 득점/실점
    - 최다 득점 경기, 최다 실점 경기
    """
    if current_team.id != team_id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    analytics_service = AnalyticsService(db)
    return analytics_service.get_team_analytics_overview(team_id)

@router.get("/team/{team_id}/goals-win-correlation", response_model=GoalsWinCorrelation)
def get_goals_win_correlation(
    team_id: int,
    db: Session = Depends(get_db),
    current_team: Team = Depends(get_current_team)
):
    """
    득점 수별 승률 분석
    """
    if current_team.id != team_id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    analytics_service = AnalyticsService(db)
    return analytics_service.get_goals_win_correlation(team_id)

@router.get("/team/{team_id}/conceded-loss-correlation", response_model=ConcededLossCorrelation)
def get_conceded_loss_correlation(
    team_id: int,
    db: Session = Depends(get_db),
    current_team: Team = Depends(get_current_team)
):
    """
    실점 수별 패배율 분석
    """
    if current_team.id != team_id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    analytics_service = AnalyticsService(db)
    return analytics_service.get_conceded_loss_correlation(team_id)

@router.get("/team/{team_id}/player-contributions", response_model=PlayerContributionsResponse)
def get_player_contributions(
    team_id: int,
    db: Session = Depends(get_db),
    current_team: Team = Depends(get_current_team)
):
    """
    선수별 승리 기여도 분석
    """
    if current_team.id != team_id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    analytics_service = AnalyticsService(db)
    return analytics_service.get_player_contributions(team_id) 