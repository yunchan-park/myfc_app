from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .database import engine
from . import models
from .routers import team, player, match

# Create database tables
models.Base.metadata.create_all(bind=engine)

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

# Include routers
app.include_router(team.router)
app.include_router(player.router)
app.include_router(match.router)

@app.get("/")
def read_root():
    return {"message": "Welcome to MyFC App API"} 