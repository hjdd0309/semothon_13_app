from fastapi import FastAPI, APIRouter
from app.database import test_db_connection
from .schemas import DBCheckResponse
from fastapi.middleware.cors import CORSMiddleware

from app.routers import auth, files, rooms, profile, schedules, task, ai, chat, todos
from app.database import Base, engine
from app import models

Base.metadata.create_all(bind=engine)

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
app.include_router(chat.router) # 윤성님 추가분
app.include_router(todos.router)

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
        
@app.post("/rooms/{room_id}/generate-topics")
async def generate_topics(room_id: int, db: Session = Depends(get_db)):
    room = db.query(models.Room).filter(models.Room.id == room_id).first()
    
    # 1. AI로부터 3개 주제 리스트를 받아옴
    ai_res = request_ice_breaking(client, summary_text, "팀 주제 3개 추천해줘")
    topics_list = ai_res.get("questions", [])

    # 2. 후보군 저장 (나중에 참고용)
    room.context_json = {"topics": topics_list}
    
    # [핵심] 사용자가 선택하기 전에, 일단 첫 번째 주제를 '기본값'으로 확정해버림!
    if topics_list:
        room.topic = topics_list[0] 
    
    room.current_stage = "ROLE" # 바로 다음 단계로 점프
    
    db.commit()
    return {"message": "주제가 생성 및 자동 확정되었습니다.", "topic": room.topic}