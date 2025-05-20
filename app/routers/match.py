from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload
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
        raise HTTPException(
            status_code=403, 
            detail=f"Not authorized to create match for team ID {match.team_id} (your team ID: {current_team.id})"
        )
    
    # Verify all players belong to the team
    for player_id in match.player_ids:
        player = db.query(models.Player).filter(models.Player.id == player_id).first()
        if not player:
            raise HTTPException(
                status_code=400, 
                detail=f"Player with ID {player_id} not found"
            )
        if player.team_id != match.team_id:
            raise HTTPException(
                status_code=400, 
                detail=f"Player with ID {player_id} belongs to team {player.team_id}, not to team {match.team_id}"
            )
    
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
    
    # Add quarter scores
    for quarter_score in match.quarter_scores:
        db_quarter_score = models.QuarterScore(
            match_id=db_match.id,
            quarter=quarter_score.quarter,
            our_score=quarter_score.our_score,
            opponent_score=quarter_score.opponent_score
        )
        db.add(db_quarter_score)
    
    # ------------------ MOM 자동 선정 로직 추가 ------------------
    # 골 정보 집계 (goals가 match.goals로 전달된다고 가정)
    goal_scorers = {}  # player_id -> goal_count
    assist_providers = {}  # player_id -> assist_count
    goals = getattr(match, 'goals', None)
    if goals:
        for goal in goals:
            pid = goal.player_id if hasattr(goal, 'player_id') else goal['player_id']
            apid = None
            if hasattr(goal, 'assist_player_id'):
                apid = goal.assist_player_id
            elif 'assist_player_id' in goal:
                apid = goal['assist_player_id']
            scorer = db.query(models.Player).filter(models.Player.id == pid).first()
            assist_player = db.query(models.Player).filter(models.Player.id == apid).first() if apid else None
            db_goal = models.Goal(
                match_id=db_match.id,
                player_id=pid,
                assist_player_id=apid,
                quarter=goal.quarter if hasattr(goal, 'quarter') else goal['quarter'],
                scorer_name=scorer.name if scorer else None,
                assist_name=assist_player.name if assist_player else None
            )
            db.add(db_goal)
            goal_scorers[pid] = goal_scorers.get(pid, 0) + 1
            if apid:
                assist_providers[apid] = assist_providers.get(apid, 0) + 1

        # 점수 계산
        player_scores = {}
        for pid, gcount in goal_scorers.items():
            player_scores[pid] = gcount * 2
        for pid, acount in assist_providers.items():
            player_scores[pid] = player_scores.get(pid, 0) + acount

        # 최고 점수 플레이어 선정
        mom_player_id = None
        max_score = -1
        for pid, score in player_scores.items():
            if score > max_score:
                max_score = score
                mom_player_id = pid

        # MOM 선수 mom_count 증가
        if mom_player_id:
            mom_player = db.query(models.Player).filter(models.Player.id == mom_player_id).first()
            if mom_player:
                mom_player.mom_count += 1

    db.commit()
    db.refresh(db_match)
    
    return db_match

@router.get("/team/{team_id}", response_model=List[schemas.Match])
def get_team_matches(
    team_id: int,
    db: Session = Depends(get_db),
    current_team: models.Team = Depends(auth.get_current_team)
):
    if current_team.id != team_id:
        raise HTTPException(
            status_code=403, 
            detail=f"Not authorized to view matches for team ID {team_id} (your team ID: {current_team.id})"
        )
    
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
        raise HTTPException(
            status_code=404, 
            detail=f"Match with ID {match_id} not found"
        )
    
    if db_match.team_id != current_team.id:
        raise HTTPException(
            status_code=403, 
            detail=f"Not authorized to update match with ID {match_id} (belongs to team ID {db_match.team_id}, your team ID: {current_team.id})"
        )
    
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
        raise HTTPException(
            status_code=404, 
            detail=f"Match with ID {match_id} not found"
        )
    
    if db_match.team_id != current_team.id:
        raise HTTPException(
            status_code=403, 
            detail=f"Not authorized to delete match with ID {match_id} (belongs to team ID {db_match.team_id}, your team ID: {current_team.id})"
        )
    
    # 매치와 연관된 골 정보 조회
    goals = db.query(models.Goal).filter(models.Goal.match_id == match_id).all()
    
    # 통계 롤백을 위한 득점자/어시스트 정보 수집
    goal_scorers = {}  # player_id -> goal_count
    assist_providers = {}  # player_id -> assist_count
    
    for goal in goals:
        # 득점자 통계 기록
        if goal.player_id not in goal_scorers:
            goal_scorers[goal.player_id] = 0
        goal_scorers[goal.player_id] += 1
        
        # 어시스트 통계 기록
        if goal.assist_player_id:
            if goal.assist_player_id not in assist_providers:
                assist_providers[goal.assist_player_id] = 0
            assist_providers[goal.assist_player_id] += 1
    
    # MOM 선수 찾기 (득점 2점, 어시스트 1점으로 계산)
    player_scores = {}
    for player_id, goal_count in goal_scorers.items():
        player_scores[player_id] = goal_count * 2  # 득점은 2점
    
    for player_id, assist_count in assist_providers.items():
        if player_id not in player_scores:
            player_scores[player_id] = 0
        player_scores[player_id] += assist_count  # 어시스트는 1점
    
    # 최고 점수 플레이어를 MOM으로 선정
    mom_player_id = None
    max_score = 0
    
    for player_id, score in player_scores.items():
        if score > max_score:
            max_score = score
            mom_player_id = player_id
    
    # 선수 통계 업데이트
    for player_id, goal_count in goal_scorers.items():
        player = db.query(models.Player).filter(models.Player.id == player_id).first()
        if player:
            player.goal_count = max(0, player.goal_count - goal_count)
    
    for player_id, assist_count in assist_providers.items():
        player = db.query(models.Player).filter(models.Player.id == player_id).first()
        if player:
            player.assist_count = max(0, player.assist_count - assist_count)
    
    if mom_player_id:
        player = db.query(models.Player).filter(models.Player.id == mom_player_id).first()
        if player and player.mom_count > 0:
            player.mom_count -= 1
    
    # 매치 삭제 (관련 골 정보는 cascade 설정으로 자동 삭제됨)
    db.delete(db_match)
    db.commit()
    
    return {"message": "Match deleted successfully with updated player stats"}

@router.get("/{match_id}/detail", response_model=schemas.MatchDetail)
def get_match_detail(
    match_id: int,
    db: Session = Depends(get_db),
    current_team: models.Team = Depends(auth.get_current_team)
):
    # 매치 정보 조회 - 한번에 관련 선수 정보를 함께 로드(N+1 쿼리 문제 방지)
    db_match = db.query(models.Match).options(
        joinedload(models.Match.players)
    ).filter(models.Match.id == match_id).first()
    
    if db_match is None:
        raise HTTPException(
            status_code=404, 
            detail=f"Match with ID {match_id} not found"
        )
    
    if db_match.team_id != current_team.id:
        raise HTTPException(
            status_code=403, 
            detail=f"Not authorized to view match with ID {match_id} (belongs to team ID {db_match.team_id}, your team ID: {current_team.id})"
        )
    
    # 골 정보 조회 - 한번에 관련 선수 정보를 함께 로드
    goals = db.query(models.Goal).options(
        joinedload(models.Goal.player),
        joinedload(models.Goal.assist_player)
    ).filter(models.Goal.match_id == match_id).all()

    # player_id가 None인 골은 제외
    goals = [g for g in goals if g.player_id is not None]
    
    # 쿼터별 스코어 조회
    db_quarter_scores = db.query(models.QuarterScore).filter(
        models.QuarterScore.match_id == match_id
    ).all()
    
    # 쿼터 스코어가 없는 경우 계산해서 생성
    quarter_scores = {}
    if db_quarter_scores:
        for qs in db_quarter_scores:
            quarter_scores[str(qs.quarter)] = {
                "id": qs.id,
                "match_id": qs.match_id,
                "quarter": qs.quarter,
                "our_score": qs.our_score,
                "opponent_score": qs.opponent_score,
                "created_at": qs.created_at,
                "updated_at": qs.updated_at
            }
    else:
        # 쿼터 스코어가 없는 경우 계산
        quarter_scores = calculate_quarter_scores(db_match, goals)
        
        # 계산된 쿼터 스코어를 DB에 저장 (벌크 인서트 사용)
        quarter_score_objects = []
        for quarter, score in quarter_scores.items():
            quarter_num = int(quarter)
            quarter_score_objects.append(
                models.QuarterScore(
                    match_id=match_id,
                    quarter=quarter_num,
                    our_score=score["our_score"],
                    opponent_score=score["opponent_score"]
                )
            )
        
        if quarter_score_objects:
            db.add_all(quarter_score_objects)
            db.commit()
    
    # 응답을 위한 데이터 구성
    response_data = {
        "id": db_match.id,
        "date": db_match.date,
        "opponent": db_match.opponent,
        "score": db_match.score,
        "team_id": db_match.team_id,
        "created_at": db_match.created_at,
        "updated_at": db_match.updated_at,
        "goals": goals,
        "quarter_scores": quarter_scores,
        "players": db_match.players
    }
    
    return response_data

# 쿼터별 스코어 계산 함수
def calculate_quarter_scores(match, goals):
    # 최종 스코어에서 총점 계산
    score_parts = match.score.split(":")
    total_our_score = int(score_parts[0]) if len(score_parts) > 0 and score_parts[0].isdigit() else 0
    total_opponent_score = int(score_parts[1]) if len(score_parts) > 1 and score_parts[1].isdigit() else 0
    
    # 쿼터별 스코어 계산을 위한 초기화
    quarter_scores = {}
    
    # 골 정보로부터 쿼터별 골 수 집계
    quarter_goals = {}
    for goal in goals:
        quarter = goal.quarter
        if quarter not in quarter_goals:
            quarter_goals[quarter] = 0
        quarter_goals[quarter] += 1
    
    # 쿼터 수 결정 (기본 4쿼터)
    quarters = max(4, max(quarter_goals.keys()) if quarter_goals else 0)
    
    # 총 골 수
    total_goals = sum(quarter_goals.values())
    
    # 상대팀 골 수 계산
    opponent_goals = total_opponent_score
    
    # 쿼터별 스코어 할당 - 우리팀
    remaining_our_score = total_our_score
    remaining_opponent_score = opponent_goals
    
    for quarter in range(1, quarters + 1):
        our_quarter_score = quarter_goals.get(quarter, 0)
        
        # 상대팀 쿼터별 점수 배분 (균등하게 또는 우리팀 점수와 비슷한 패턴으로)
        opponent_quarter_score = 0
        if remaining_opponent_score > 0:
            # 간단한 배분: 남은 점수를 남은 쿼터에 고르게 분배
            opponent_quarter_score = 1 if remaining_opponent_score > (quarters - quarter) else 0
            if quarter == quarters:  # 마지막 쿼터
                opponent_quarter_score = remaining_opponent_score
            remaining_opponent_score -= opponent_quarter_score
        
        quarter_scores[str(quarter)] = {
            "our_score": our_quarter_score,
            "opponent_score": opponent_quarter_score
        }
        
        remaining_our_score -= our_quarter_score
    
    return quarter_scores

@router.post("/{match_id}/goals", response_model=schemas.Goal)
def add_goal(
    match_id: int,
    goal: schemas.GoalCreate,
    db: Session = Depends(get_db),
    current_team: models.Team = Depends(auth.get_current_team)
):
    db_match = db.query(models.Match).filter(models.Match.id == match_id).first()
    if db_match is None:
        raise HTTPException(
            status_code=404, 
            detail=f"Match with ID {match_id} not found"
        )
    
    if db_match.team_id != current_team.id:
        raise HTTPException(
            status_code=403, 
            detail=f"Not authorized to add goal to match with ID {match_id} (belongs to team ID {db_match.team_id}, your team ID: {current_team.id})"
        )
    
    # Verify scorer belongs to the team
    scorer = db.query(models.Player).filter(models.Player.id == goal.player_id).first()
    if not scorer:
        raise HTTPException(
            status_code=400, 
            detail=f"Player with ID {goal.player_id} not found"
        )
    
    if scorer.team_id != current_team.id:
        raise HTTPException(
            status_code=400, 
            detail=f"Player with ID {goal.player_id} belongs to team ID {scorer.team_id}, not to your team (ID: {current_team.id})"
        )
    
    # Verify assist player if provided
    assist_player = None
    if goal.assist_player_id:
        assist_player = db.query(models.Player).filter(models.Player.id == goal.assist_player_id).first()
        if not assist_player:
            raise HTTPException(
                status_code=400, 
                detail=f"Assist player with ID {goal.assist_player_id} not found"
            )
        
        if assist_player.team_id != current_team.id:
            raise HTTPException(
                status_code=400, 
                detail=f"Assist player with ID {goal.assist_player_id} belongs to team ID {assist_player.team_id}, not to your team (ID: {current_team.id})"
            )
    
    db_goal = models.Goal(
        **goal.dict(),
        scorer_name=scorer.name if scorer else None,
        assist_name=assist_player.name if assist_player else None
    )
    db.add(db_goal)
    
    # 골 스코어러의 골 수 증가
    scorer.goal_count += 1
    
    # 어시스트 제공자의 어시스트 수 증가
    if assist_player:
        assist_player.assist_count += 1
    
    # MOM 선정 로직 추가
    # 현재 매치의 모든 골 가져오기 (방금 추가한 골 포함) - 쿼리 최적화
    all_goals = db.query(models.Goal).filter(models.Goal.match_id == match_id).all()
    
    # 득점과 어시스트 집계
    player_goal_counts = {}
    player_assist_counts = {}
    
    for g in all_goals:
        if g.player_id not in player_goal_counts:
            player_goal_counts[g.player_id] = 0
        player_goal_counts[g.player_id] += 1
        
        if g.assist_player_id:
            if g.assist_player_id not in player_assist_counts:
                player_assist_counts[g.assist_player_id] = 0
            player_assist_counts[g.assist_player_id] += 1
    
    # 득점(2점) + 어시스트(1점)로 총점 계산
    player_scores = {}
    
    for player_id, goal_count in player_goal_counts.items():
        player_scores[player_id] = goal_count * 2  # 득점 2점
    
    for player_id, assist_count in player_assist_counts.items():
        if player_id not in player_scores:
            player_scores[player_id] = 0
        player_scores[player_id] += assist_count  # 어시스트 1점
    
    # 최고 점수 선수 찾기
    current_mom_id = None
    highest_score = 0
    
    for player_id, score in player_scores.items():
        if score > highest_score:
            highest_score = score
            current_mom_id = player_id
    
    # 기존 MOM 선수의 MOM 카운트 초기화 (한번에 효율적으로 조회)
    match_players = db.query(models.Player).filter(
        models.Player.matches.any(id=match_id),
        models.Player.mom_count > 0,
        models.Player.id != current_mom_id
    ).all()
    
    for player in match_players:
        player.mom_count -= 1
    
    # 새로운 MOM 선수 업데이트
    if current_mom_id:
        new_mom_player = db.query(models.Player).filter(models.Player.id == current_mom_id).first()
        if new_mom_player:
            new_mom_player.mom_count += 1
    
    db.commit()
    db.refresh(db_goal)
    return db_goal 