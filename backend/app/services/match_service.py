from app import models, schemas
from sqlalchemy.orm import Session

class MatchService:
    def __init__(self, db: Session):
        self.db = db

    def create_match(self, match: schemas.MatchCreate, current_team: models.Team):
        # 기존 create_match 라우터의 핵심 로직을 이곳으로 이동
        # ... (생략, 실제 라우터에서 호출)
        pass

    def get_match_detail(self, match_id: int, current_team: models.Team):
        # 기존 get_match_detail 라우터의 핵심 로직을 이곳으로 이동
        # ...
        pass

    # 기타 match 관련 메소드 추가 