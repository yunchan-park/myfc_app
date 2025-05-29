from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from .database import engine
from . import models
from .routers import team, player, match, analytics
import logging
import time
import json
import traceback
from typing import Callable, AsyncGenerator

# 로깅 설정 개선
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Create database tables
models.Base.metadata.create_all(bind=engine)

# CallableFactory 클래스 구현
class CallableFactory:
    def __init__(self, body: bytes):
        self.body = body
    
    async def __call__(self) -> dict:
        return {"type": "http.request", "body": self.body, "more_body": False}

app = FastAPI(
    title="MyFC App API",
    description="API for managing football teams, players, and matches",
    version="1.0.0"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 요청/응답 로깅 미들웨어 개선
@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    request_id = str(int(time.time() * 1000))
    logger.info(f"\n{'='*50}")
    logger.info(f"[req_{request_id}] Request: {request.method} {request.url}")
    logger.info(f"[req_{request_id}] Headers: {dict(request.headers)}")
    
    # 요청 본문 읽기
    body = b""
    async for chunk in request.stream():
        body += chunk
    
    # 요청 본문 기록
    if body:
        try:
            body_text = body.decode()
            logger.info(f"[req_{request_id}] Request Body: {body_text}")
        except UnicodeDecodeError:
            logger.info(f"[req_{request_id}] Request Body: (binary data)")
    
    # 요청 처리 시작 시간 기록
    start_time = time.time()
    logger.debug(f"[req_{request_id}] Starting response processing at {0:.4f}s", 0)
    
    # 스트림을 사용하여 원래 Request 객체 재생성
    request = Request(request.scope, receive=CallableFactory(body))
    
    # 요청 처리
    try:
        response = await call_next(request)
    except Exception as e:
        logger.error(f"[req_{request_id}] Error during request processing: {str(e)}")
        logger.error(traceback.format_exc())
        raise
    
    # 처리 시간 계산
    process_time = time.time() - start_time
    logger.debug(f"[req_{request_id}] Response processing completed at {process_time:.4f}s")
    
    # 응답 상태 기록
    logger.info(f"[req_{request_id}] Response Status: {response.status_code}")
    logger.info(f"[req_{request_id}] Process Time: {process_time:.4f}s")
    
    # 느린 응답 경고
    if process_time > 1.0:
        logger.warning(f"[req_{request_id}] SLOW RESPONSE: {request.method} {request.url} took {process_time:.4f}s")
    
    # 응답 헤더에 처리 시간 추가
    response.headers["X-Process-Time"] = str(process_time)
    logger.info(f"{'='*50}\n")
    
    return response

# Include routers
app.include_router(team.router)
app.include_router(player.router)
app.include_router(match.router)
app.include_router(analytics.router)

@app.get("/")
def read_root():
    return {"message": "Welcome to MyFC App API"} 