import os
from openai import OpenAI
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app import schemas, models
import json

router = APIRouter(
    prefix="/api/ai",
    tags=["AI Features"]
)

# 환경 변수에서 기본 API 키를 읽어와 초기 설정
api_key = "0FSeuXcueB9auGDkB5pn4tuz4h9LbRGU"
client = None

if api_key:
    # 제공된 Mindlogic API 연동 방식 (OpenAI SDK 호환)
    client = OpenAI(
        api_key=api_key,
        base_url="https://factchat-cloud.mindlogic.ai/v1/gateway"
    )

MODEL_NAME = "claude-sonnet-4-6"

@router.post("/ice-breaking", response_model=schemas.IceBreakingResponse)
def analyze_ice_breaking(request: schemas.IceBreakingRequest, db: Session = Depends(get_db)):
    """
    [Phase 1] 아이스브레이킹 & 성향 분석 API
    각 팀원들의 답변을 종합하여 LLM이 팀 전체 성향 및 팀원간 시너지를 분석합니다.
    """
    if not client:
         raise HTTPException(status_code=500, detail="API Key is not configured")
    
    # 로직 구체화 예정
    
    return schemas.IceBreakingResponse(
        success=True,
        message="분석 성공",
        analysis_report="가상의 분석 레포트입니다."
    )

@router.post("/topics", response_model=schemas.TopicRecommendResponse)
def recommend_topics(request: schemas.TopicRecommendRequest, db: Session = Depends(get_db)):
    """
    [Phase 2] 주제 추천 및 선정 과정 API
    """
    if not client:
         raise HTTPException(status_code=500, detail="API Key is not configured")
         
    return schemas.TopicRecommendResponse(
        success=True,
        topics=[]
    )


@router.post("/tasks", response_model=schemas.TaskDistributeResponse)
def distribute_tasks(request: schemas.TaskDistributeRequest, db: Session = Depends(get_db)):
    """
    [Phase 3] 프로젝트 To-Do 생성 및 분배 API
    """
    if not client:
         raise HTTPException(status_code=500, detail="API Key is not configured")
         
    return schemas.TaskDistributeResponse(
        success=True,
        tasks=[]
    )

@router.post("/chat", response_model=schemas.ChatMessageResponse)
def chat_with_bot(request: schemas.ChatMessageRequest, db: Session = Depends(get_db)):
    """
    [Phase 4] 팀 통합 데이터베이스 AI Q&A API
    해당 룸(방)에 존재하는 과거 채팅 트래킹 포함
    """
    if not client:
         raise HTTPException(status_code=500, detail="API Key is not configured")
         
    # 사용자 메시지 DB 저장 (발신: USER)
    new_message = models.ChatMessage(room_id=request.room_id, message=request.message, sender_type="USER")
    db.add(new_message)
    db.commit()
    db.refresh(new_message)

    # 이전 내역 불러와서 컨텍스트로 전달
    history = db.query(models.ChatMessage).filter(models.ChatMessage.room_id == request.room_id).order_by(models.ChatMessage.created_at.asc()).all()
    
    messages = [
        {"role": "system", "content": "너는 세모톤 프로젝트의 다정하고 유머러스한 AI 어시스턴트야. 과거 대화 내용과 상황을 바탕으로 답변해줘."}
    ]
    
    for h in history:
        # ROLE 변환 (USER -> user, AI -> assistant)
        role = "user" if h.sender_type == "USER" else "assistant"
        messages.append({"role": role, "content": h.message})
    
    try:
        # Mindlogic API (OpenAI SDK 호환) 호출
        response = client.chat.completions.create(
            model=MODEL_NAME, # 사용 모델: claude-sonnet-4-6
            messages=messages,
        )
        answer_text = response.choices[0].message.content
    except Exception as e:
        answer_text = f"AI API 응답 과정에서 오류가 발생했습니다: {str(e)}"
    
    # AI 응답을 DB에 저장
    ai_reply = models.ChatMessage(room_id=request.room_id, message=answer_text, sender_type="AI")
    db.add(ai_reply)
    db.commit()

    return schemas.ChatMessageResponse(
        success=True,
        reply=answer_text
    )
