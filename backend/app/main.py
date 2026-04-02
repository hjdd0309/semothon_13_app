from fastapi import FastAPI,APIRouter
from app.database import test_db_connection
from .schemas import DBCheckResponse
from fastapi.middleware.cors import CORSMiddleware

from app.routers import auth, files, rooms, profile, schedules, task, ai, chat

app = FastAPI()

app.add_middleware( 
    CORSMiddleware,
    allow_origins=["*"],  # 모든 도메인 허용
    allow_credentials=True,
    allow_methods=["*"],  # 모든 HTTP 메소드 허용
    allow_headers=["*"],  # 모든 헤더 허용
)

app.include_router(auth.router)
app.include_router(files.router)
app.include_router(rooms.router)
app.include_router(profile.router)
app.include_router(schedules.router)
app.include_router(task.router)
app.include_router(ai.router)
app.include_router(chat.router)


@app.get("/")
def root():
    return {"message": "FastAPI server is running"}


@app.get(
    "/db-check",
    response_model=DBCheckResponse,
    summary="Database connection check",
    description="Check if the MySQL database connection is working properly."
)
def db_check():
    try:
        result = test_db_connection()
        return DBCheckResponse(
            success=True,
            message="MySQL connection successful",
            result=result
        )

    except Exception as e:
        return DBCheckResponse(
            success=False,
            message="MySQL connection failed",
            error=str(e)
        )