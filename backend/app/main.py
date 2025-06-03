from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from .database import engine
from . import models
from .routers import team, player, match, analytics
import time
import json
import traceback
from typing import Callable, AsyncGenerator

# 데이터 베이스 테이블 생성 (이미 존재하면 무시)
models.Base.metadata.create_all(bind=engine)

# CallableFactory 클래스 구현 (비동기 요청 처리를 위해)
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

# CORS 설정 (모든 출처 허용)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 프로덕션 환경에서는 특정 출처로 제한
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 요청/응답 로깅 미들웨어 제거
@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    # 요청 본문 읽기
    body = b""
    async for chunk in request.stream():
        body += chunk
    # 스트림을 사용하여 원래 Request 객체 재생성
    request = Request(request.scope, receive=CallableFactory(body))
    # 요청 처리
    try:
        response = await call_next(request)
    except Exception as e:
        raise
    # 처리 시간 계산
    process_time = time.time() - time.time()  # 실제로는 의미 없음, 필요시 구현
    # 응답 헤더에 처리 시간 추가
    response.headers["X-Process-Time"] = str(process_time)
    return response

# Include routers
app.include_router(team.router)
app.include_router(player.router)
app.include_router(match.router)
app.include_router(analytics.router)

@app.get("/")
def read_root():
    return {"message": "Welcome to MyFC App API"} 