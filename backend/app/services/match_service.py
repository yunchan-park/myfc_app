from app import models, schemas
from sqlalchemy.orm import Session, joinedload
from fastapi import HTTPException
from typing import List, Dict, Any
from datetime import datetime

class MatchService:
    def __init__(self, db: Session, current_team: models.Team = None):
        self.db = db
        self.current_team = current_team

    def create_match(self, match: schemas.MatchCreate, current_team: models.Team):
        if current_team.id != match.team_id:
            raise HTTPException(
                status_code=403, 
                detail=f"Not authorized to create match for team ID {match.team_id} (your team ID: {current_team.id})"
            )
        
        # Verify all players belong to the team
        for player_id in match.player_ids:
            player = self.db.query(models.Player).filter(models.Player.id == player_id).first()
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
        self.db.add(db_match)
        self.db.commit()
        self.db.refresh(db_match)
        
        # Add players to match
        for player_id in match.player_ids:
            db_match.players.append(self.db.query(models.Player).get(player_id))
        
        # Add quarter scores
        for quarter_score in match.quarter_scores:
            db_quarter_score = models.QuarterScore(
                match_id=db_match.id,
                quarter=quarter_score.quarter,
                our_score=quarter_score.our_score,
                opponent_score=quarter_score.opponent_score
            )
            self.db.add(db_quarter_score)
        
        # MOM 자동 선정 로직
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
                scorer = self.db.query(models.Player).filter(models.Player.id == pid).first()
                assist_player = self.db.query(models.Player).filter(models.Player.id == apid).first() if apid else None
                db_goal = models.Goal(
                    match_id=db_match.id,
                    player_id=pid,
                    assist_player_id=apid,
                    quarter=goal.quarter if hasattr(goal, 'quarter') else goal['quarter'],
                    scorer_name=scorer.name if scorer else None,
                    assist_name=assist_player.name if assist_player else None
                )
                self.db.add(db_goal)
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
                mom_player = self.db.query(models.Player).filter(models.Player.id == mom_player_id).first()
                if mom_player:
                    mom_player.mom_count += 1

        self.db.commit()
        self.db.refresh(db_match)
        
        return db_match

    def get_team_matches(self, team_id: int, current_team: models.Team):
        if current_team.id != team_id:
            raise HTTPException(
                status_code=403, 
                detail=f"Not authorized to view matches for team ID {team_id} (your team ID: {current_team.id})"
            )
        
        matches = self.db.query(models.Match).filter(models.Match.team_id == team_id).all()
        return matches

    def update_match(self, match_id: int, match_update: schemas.MatchUpdate, current_team: models.Team):
        db_match = self.db.query(models.Match).filter(models.Match.id == match_id).first()
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
                player = self.db.query(models.Player).filter(models.Player.id == player_id).first()
                if not player or player.team_id != current_team.id:
                    raise HTTPException(status_code=400, detail=f"Player {player_id} not found or not in team")
            
            # Update match players
            db_match.players = [self.db.query(models.Player).get(player_id) for player_id in player_ids]
        
        # Update other fields
        for key, value in update_data.items():
            setattr(db_match, key, value)
        
        self.db.commit()
        self.db.refresh(db_match)
        return db_match

    def delete_match(self, match_id: int, current_team: models.Team):
        db_match = self.db.query(models.Match).filter(models.Match.id == match_id).first()
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
        goals = self.db.query(models.Goal).filter(models.Goal.match_id == match_id).all()
        
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
            player = self.db.query(models.Player).filter(models.Player.id == player_id).first()
            if player:
                player.goal_count = max(0, player.goal_count - goal_count)
        
        for player_id, assist_count in assist_providers.items():
            player = self.db.query(models.Player).filter(models.Player.id == player_id).first()
            if player:
                player.assist_count = max(0, player.assist_count - assist_count)
        
        if mom_player_id:
            player = self.db.query(models.Player).filter(models.Player.id == mom_player_id).first()
            if player and player.mom_count > 0:
                player.mom_count -= 1
        
        # 매치 삭제 (관련 골 정보는 cascade 설정으로 자동 삭제됨)
        self.db.delete(db_match)
        self.db.commit()
        return {"message": "Match deleted successfully"}

    def get_match_detail(self, match_id: int) -> Dict:
        """Get detailed match information including players and goals"""
        match = self.db.query(models.Match).filter(models.Match.id == match_id).first()
        if not match:
            raise HTTPException(status_code=404, detail="Match not found")
            
        # Check if current team is authorized to view this match
        if match.team_id != self.current_team.id:
            raise HTTPException(status_code=403, detail="Not authorized to view this match")
            
        # Get match players directly from the relationship
        players = match.players
        player_data = [
            {
                "id": p.id,
                "name": p.name,
                "position": p.position,
                "number": p.number,
                "team_id": p.team_id,
                "created_at": p.created_at
            }
            for p in players
        ]
        
        # Get goals with all required fields
        goals = self.db.query(models.Goal).filter(models.Goal.match_id == match_id).all()
        goal_data = [
            {
                "id": g.id,
                "match_id": g.match_id,
                "quarter": g.quarter,
                "player_id": g.player_id,
                "assist_player_id": g.assist_player_id,
                "scorer_name": g.scorer_name,
                "assist_name": g.assist_name,
                "created_at": g.created_at
            }
            for g in goals
        ]
        
        # Get quarter scores and convert to dictionary format
        quarter_scores = self.db.query(models.QuarterScore).filter(models.QuarterScore.match_id == match_id).all()
        quarter_score_dict = {
            str(qs.quarter): {
                "quarter": qs.quarter,
                "our_score": qs.our_score,
                "opponent_score": qs.opponent_score
            }
            for qs in quarter_scores
        }
        
        return {
            "id": match.id,
            "date": match.date,
            "opponent": match.opponent,
            "score": match.score,
            "team_id": match.team_id,
            "created_at": match.created_at,
            "players": player_data,
            "goals": goal_data,
            "quarter_scores": quarter_score_dict
        }

    def calculate_quarter_scores(self, match, goals):
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

    def add_goal(self, match_id: int, goal: schemas.GoalCreate, current_team: models.Team):
        db_match = self.db.query(models.Match).filter(models.Match.id == match_id).first()
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
        
        # 선수 검증
        scorer = self.db.query(models.Player).filter(models.Player.id == goal.player_id).first()
        if not scorer or scorer.team_id != current_team.id:
            raise HTTPException(
                status_code=400, 
                detail=f"Scorer with ID {goal.player_id} not found or not in team"
            )
        
        if goal.assist_player_id:
            assist_player = self.db.query(models.Player).filter(models.Player.id == goal.assist_player_id).first()
            if not assist_player or assist_player.team_id != current_team.id:
                raise HTTPException(
                    status_code=400, 
                    detail=f"Assist player with ID {goal.assist_player_id} not found or not in team"
                )
        
        # 골 생성
        db_goal = models.Goal(
            match_id=match_id,
            player_id=goal.player_id,
            assist_player_id=goal.assist_player_id,
            quarter=goal.quarter,
            scorer_name=scorer.name,
            assist_name=assist_player.name if goal.assist_player_id else None
        )
        self.db.add(db_goal)
        
        # 선수 통계 업데이트
        scorer.goal_count += 1
        if goal.assist_player_id:
            assist_player.assist_count += 1
        
        # MOM 자동 선정 로직
        goals = self.db.query(models.Goal).filter(models.Goal.match_id == match_id).all()
        goal_scorers = {}  # player_id -> goal_count
        assist_providers = {}  # player_id -> assist_count
        
        for g in goals:
            if g.player_id not in goal_scorers:
                goal_scorers[g.player_id] = 0
            goal_scorers[g.player_id] += 1
            
            if g.assist_player_id:
                if g.assist_player_id not in assist_providers:
                    assist_providers[g.assist_player_id] = 0
                assist_providers[g.assist_player_id] += 1
        
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
            mom_player = self.db.query(models.Player).filter(models.Player.id == mom_player_id).first()
            if mom_player:
                mom_player.mom_count += 1
        
        self.db.commit()
        self.db.refresh(db_goal)
        return db_goal

    def get_recent_matches(self, team_id: int, current_team: models.Team, limit: int = 5):
        if current_team.id != team_id:
            raise HTTPException(status_code=403, detail="Not authorized")
        today = datetime.now().date()
        # 미래 경기 우선, 부족하면 과거 경기 추가
        future_matches = (
            self.db.query(models.Match)
            .filter(models.Match.team_id == team_id, models.Match.date >= today)
            .order_by(models.Match.date.asc())
            .limit(limit)
            .all()
        )
        if len(future_matches) < limit:
            past_matches = (
                self.db.query(models.Match)
                .filter(models.Match.team_id == team_id, models.Match.date < today)
                .order_by(models.Match.date.desc())
                .limit(limit - len(future_matches))
                .all()
            )
            # 과거 경기는 최신순이므로 역순으로 붙여줌
            return future_matches + past_matches[::-1]
        return future_matches