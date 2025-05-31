from sqlalchemy import create_engine, event
from sqlalchemy.orm import declarative_base, sessionmaker
from sqlalchemy.engine import Engine
import logging
import time

# 로깅 설정
logger = logging.getLogger(__name__)

SQLALCHEMY_DATABASE_URL = "sqlite:///./myfc.db"

# SQLite 전용 연결 설정 - 최적화
engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={
        "check_same_thread": False,
        "timeout": 10  # 타임아웃 시간 10초로 감소
    },
    pool_pre_ping=True,  # 연결 유효성 검사 추가
    pool_recycle=3600    # 연결 재활용 시간 설정
)

# 세션 설정 최적화
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
    expire_on_commit=False  # 커밋 후 객체 만료 비활성화로 성능 향상
)

# SQLAlchemy 2.0 호환 방식
Base = declarative_base()

# 쿼리 실행 시간 추적을 위한 이벤트 리스너
@event.listens_for(Engine, "before_cursor_execute")
def before_cursor_execute(conn, cursor, statement, parameters, context, executemany):
    conn.info.setdefault('query_start_time', []).append(time.time())
    logger.debug("Execute query: %s", statement)
    logger.debug("Parameters: %s", parameters)

@event.listens_for(Engine, "after_cursor_execute")
def after_cursor_execute(conn, cursor, statement, parameters, context, executemany):
    total = time.time() - conn.info['query_start_time'].pop()
    logger.debug("Query completed in %.3f seconds", total)
    if total > 1.0:  # 1초 이상 걸리는 쿼리 경고
        logger.warning("Slow query detected (%.3f sec): %s", total, statement)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close() 