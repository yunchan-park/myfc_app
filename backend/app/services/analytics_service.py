from sqlalchemy.orm import Session
from sqlalchemy import func, case, cast, Integer
from typing import List, Dict, Any
from app.models import Team, Player, Match, Goal, QuarterScore
from app.schemas import (
    TeamAnalyticsOverview, GoalsWinCorrelation, GoalRangeData,
    ConcededLossCorrelation, ConcededRangeData,
    PlayerContributionsResponse, PlayerContribution
)

class AnalyticsService:
    def __init__(self, db: Session):
        self.db = db
    
    def _parse_score(self, score: str) -> tuple:
        """스코어 문자열을 파싱하여 우리팀 점수와 상대팀 점수를 반환"""
        try:
            our_score, opponent_score = map(int, score.split(':'))
            return our_score, opponent_score
        except:
            return 0, 0
    
    def _get_match_result(self, score: str) -> str:
        """경기 결과 계산 (WIN/DRAW/LOSE)"""
        our_score, opponent_score = self._parse_score(score)
        if our_score > opponent_score:
            return 'WIN'
        elif our_score < opponent_score:
            return 'LOSE'
        else:
            return 'DRAW'
    
    def get_team_analytics_overview(self, team_id: int) -> TeamAnalyticsOverview:
        """팀 전체 통계 개요"""
        # 전체 경기 조회
        matches = self.db.query(Match).filter(Match.team_id == team_id).all()
        
        if not matches:
            return TeamAnalyticsOverview(
                total_matches=0, wins=0, draws=0, losses=0, win_rate=0.0,
                avg_goals_scored=0.0, avg_goals_conceded=0.0,
                highest_scoring_match={"match_id": 0, "goals": 0},
                most_conceded_match={"match_id": 0, "goals": 0}
            )
        
        total_matches = len(matches)
        wins = draws = losses = 0
        total_goals_scored = total_goals_conceded = 0
        highest_scoring = {"match_id": 0, "goals": 0}
        most_conceded = {"match_id": 0, "goals": 0}
        
        for match in matches:
            our_score, opponent_score = self._parse_score(match.score)
            result = self._get_match_result(match.score)
            
            if result == 'WIN':
                wins += 1
            elif result == 'DRAW':
                draws += 1
            else:
                losses += 1
            
            total_goals_scored += our_score
            total_goals_conceded += opponent_score
            
            if our_score > highest_scoring["goals"]:
                highest_scoring = {"match_id": match.id, "goals": our_score}
            
            if opponent_score > most_conceded["goals"]:
                most_conceded = {"match_id": match.id, "goals": opponent_score}
        
        win_rate = (wins / total_matches * 100) if total_matches > 0 else 0.0
        avg_goals_scored = total_goals_scored / total_matches if total_matches > 0 else 0.0
        avg_goals_conceded = total_goals_conceded / total_matches if total_matches > 0 else 0.0
        
        return TeamAnalyticsOverview(
            total_matches=total_matches,
            wins=wins,
            draws=draws,
            losses=losses,
            win_rate=round(win_rate, 1),
            avg_goals_scored=round(avg_goals_scored, 1),
            avg_goals_conceded=round(avg_goals_conceded, 1),
            highest_scoring_match=highest_scoring,
            most_conceded_match=most_conceded
        )
    
    def get_goals_win_correlation(self, team_id: int) -> GoalsWinCorrelation:
        """득점 수별 승률 분석"""
        matches = self.db.query(Match).filter(Match.team_id == team_id).all()
        
        # 득점별 그룹화
        goal_groups = {"0": [], "1": [], "2": [], "3+": []}
        
        for match in matches:
            our_score, _ = self._parse_score(match.score)
            result = self._get_match_result(match.score)
            
            if our_score == 0:
                goal_groups["0"].append(result)
            elif our_score == 1:
                goal_groups["1"].append(result)
            elif our_score == 2:
                goal_groups["2"].append(result)
            else:
                goal_groups["3+"].append(result)
        
        goal_ranges = []
        total_wins = 0
        total_goals_for_wins = 0
        
        for goals, results in goal_groups.items():
            if results:
                matches_count = len(results)
                wins_count = results.count('WIN')
                win_rate = (wins_count / matches_count * 100) if matches_count > 0 else 0.0
                
                goal_ranges.append(GoalRangeData(
                    goals=goals,
                    matches=matches_count,
                    wins=wins_count,
                    win_rate=round(win_rate, 1)
                ))
                
                total_wins += wins_count
                if goals == "3+":
                    total_goals_for_wins += wins_count * 3  # 평균 3골로 계산
                else:
                    total_goals_for_wins += wins_count * int(goals) if goals.isdigit() else 0
        
        # 최적 득점 수 계산 (승률이 가장 높은 구간)
        optimal_goals = 0
        highest_win_rate = 0
        for range_data in goal_ranges:
            if range_data.win_rate > highest_win_rate:
                highest_win_rate = range_data.win_rate
                optimal_goals = 3 if range_data.goals == "3+" else int(range_data.goals)
        
        avg_goals_for_win = (total_goals_for_wins / total_wins) if total_wins > 0 else 0.0
        
        return GoalsWinCorrelation(
            goal_ranges=goal_ranges,
            optimal_goals=optimal_goals,
            avg_goals_for_win=round(avg_goals_for_win, 1)
        )
    
    def get_conceded_loss_correlation(self, team_id: int) -> ConcededLossCorrelation:
        """실점 수별 패배율 분석"""
        matches = self.db.query(Match).filter(Match.team_id == team_id).all()
        
        # 실점별 그룹화
        conceded_groups = {"0": [], "1": [], "2": [], "3+": []}
        
        for match in matches:
            _, opponent_score = self._parse_score(match.score)
            result = self._get_match_result(match.score)
            
            if opponent_score == 0:
                conceded_groups["0"].append(result)
            elif opponent_score == 1:
                conceded_groups["1"].append(result)
            elif opponent_score == 2:
                conceded_groups["2"].append(result)
            else:
                conceded_groups["3+"].append(result)
        
        conceded_ranges = []
        total_losses = 0
        total_conceded_for_losses = 0
        
        for conceded, results in conceded_groups.items():
            if results:
                matches_count = len(results)
                losses_count = results.count('LOSE')
                loss_rate = (losses_count / matches_count * 100) if matches_count > 0 else 0.0
                
                conceded_ranges.append(ConcededRangeData(
                    conceded=conceded,
                    matches=matches_count,
                    losses=losses_count,
                    loss_rate=round(loss_rate, 1)
                ))
                
                total_losses += losses_count
                if conceded == "3+":
                    total_conceded_for_losses += losses_count * 3
                else:
                    total_conceded_for_losses += losses_count * int(conceded) if conceded.isdigit() else 0
        
        # 위험 임계점 계산 (패배율이 50% 이상인 최소 실점)
        danger_threshold = 3
        for range_data in conceded_ranges:
            if range_data.loss_rate >= 50.0:
                danger_threshold = 3 if range_data.conceded == "3+" else int(range_data.conceded)
                break
        
        avg_conceded_for_loss = (total_conceded_for_losses / total_losses) if total_losses > 0 else 0.0
        
        return ConcededLossCorrelation(
            conceded_ranges=conceded_ranges,
            danger_threshold=danger_threshold,
            avg_conceded_for_loss=round(avg_conceded_for_loss, 1)
        )
    
    def get_player_contributions(self, team_id: int) -> PlayerContributionsResponse:
        """선수별 승리 기여도 분석"""
        # 선수 및 출전 경기 정보 조회
        players_data = self.db.query(Player).filter(Player.team_id == team_id).all()
        
        player_contributions = []
        
        for player in players_data:
            # 출전 경기 조회 (match_player 테이블을 통해)
            matches_played = self.db.query(Match).join(
                Match.players
            ).filter(
                Match.team_id == team_id,
                Player.id == player.id
            ).all()
            
            matches_count = len(matches_played)
            if matches_count == 0:
                continue
            
            # 승리한 경기 수 계산
            wins = sum(1 for match in matches_played if self._get_match_result(match.score) == 'WIN')
            win_rate = (wins / matches_count * 100) if matches_count > 0 else 0.0
            
            # 기여도 점수 계산 (승률 * (골*4 + 어시스트*2) * (MOM+1))
            contribution_score = (win_rate / 100) * (player.goal_count * 4 + 
                                                   player.assist_count * 2) * (player.mom_count + 1)
            # 소수점 두자리 이하 버림
            contribution_score = int(contribution_score * 100) / 100
            
            avg_goals_per_match = player.goal_count / matches_count if matches_count > 0 else 0.0
            
            player_contributions.append(PlayerContribution(
                id=player.id,
                name=player.name,
                matches_played=matches_count,
                wins=wins,
                win_rate=round(win_rate, 1),
                goals=player.goal_count,
                assists=player.assist_count,
                mom_count=player.mom_count,
                contribution_score=contribution_score,
                avg_goals_per_match=round(avg_goals_per_match, 2)
            ))
        
        # 상위 기여자와 가장 신뢰할 수 있는 선수 찾기
        top_contributor = {"name": "", "score": "0"}
        most_reliable = {"name": "", "win_rate": "0"}
        
        if player_contributions:
            # 기여도 점수가 가장 높은 선수
            top_player = max(player_contributions, key=lambda p: p.contribution_score)
            top_contributor = {"name": top_player.name, "score": str(top_player.contribution_score)}
            
            # 승률이 가장 높은 선수 (최소 3경기 이상 출전)
            reliable_players = [p for p in player_contributions if p.matches_played >= 3]
            if reliable_players:
                reliable_player = max(reliable_players, key=lambda p: p.win_rate)
                most_reliable = {"name": reliable_player.name, "win_rate": str(reliable_player.win_rate)}
        
        return PlayerContributionsResponse(
            players=sorted(player_contributions, key=lambda p: p.contribution_score, reverse=True),
            top_contributor=top_contributor,
            most_reliable=most_reliable
        ) 