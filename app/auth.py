from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
import asyncio
from concurrent.futures import ThreadPoolExecutor
import logging
from . import models, schemas
from .database import get_db
import time

# 로깅 설정
logger = logging.getLogger(__name__)

# Security configuration
SECRET_KEY = "your-secret-key-here"  # In production, use environment variable
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

# bcrypt 해싱 최적화: 라운드 수를 4로 더 낮춤 (개발 환경용, 프로덕션에서는 더 높은 값 사용)
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto", bcrypt__rounds=4)
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="teams/login")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    try:
        start_time = time.time()
        result = pwd_context.verify(plain_password, hashed_password)
        elapsed = time.time() - start_time
        if elapsed > 1.0:
            logger.warning(f"비밀번호 검증에 {elapsed:.3f}초가 소요되었습니다")
        return result
    except Exception as e:
        logger.error(f"비밀번호 검증 중 오류: {str(e)}")
        return False

def get_password_hash(password: str) -> str:
    try:
        start_time = time.time()
        hashed_password = pwd_context.hash(password)
        elapsed = time.time() - start_time
        if elapsed > 1.0:
            logger.warning(f"비밀번호 해싱에 {elapsed:.3f}초가 소요되었습니다")
        return hashed_password
    except Exception as e:
        logger.error(f"비밀번호 해싱 중 오류: {str(e)}")
        raise

# 비동기 버전의 비밀번호 해싱 (별도 스레드에서 실행)
async def get_password_hash_async(password: str) -> str:
    with ThreadPoolExecutor() as executor:
        return await asyncio.get_event_loop().run_in_executor(
            executor, get_password_hash, password
        )

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

async def get_current_team(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        team_id: str = payload.get("sub")
        if team_id is None:
            raise credentials_exception
        token_data = schemas.TokenData(team_id=team_id)
    except JWTError:
        raise credentials_exception
    
    team = db.query(models.Team).filter(models.Team.id == token_data.team_id).first()
    if team is None:
        raise credentials_exception
    return team 