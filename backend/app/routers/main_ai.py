import os
import json
import logging
from datetime import datetime
from typing import List, Optional, Dict, Any

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from openai import OpenAI

# 프로젝트 내부 모듈 호출
from app.database import get_db
from app import schemas, models
from app.models import AIContext, Room

# 로거 및 설정
logger = logging.getLogger(__name__)
MODEL_NAME = "gpt-4o-mini"
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

router = APIRouter(prefix="/ai", tags=["AI"])

def extract_json_safe(text: str):
    """마크다운 태그를 제거하고 JSON만 추출하는 유틸리티"""
    try:
        clean_text = text.replace("```json", "").replace("```", "").strip()
        return json.loads(clean_text)
    except Exception as e:
        raise ValueError(f"JSON 파싱 실패: {str(e)}")

# --- 1. 채팅 및 업무 배분 결과 업데이트 API ---
@router.post("/chat", response_model=schemas.ChatMessageResponse)
def chat_with_bot(request: schemas.ChatMessageRequest, db: Session = Depends(get_db)):
    # (주의: 실제 AI 호출 로직이 이 앞에 있어야 ai_content가 정의됩니다)
    # 여기서는 예시를 위해 임의의 ai_content를 가정하거나 기존 로직을 연결해야 합니다.
    ai_content = "AI가 생성한 원본 응답 텍스트" 

    # 활성 컨텍스트 조회
    ai_context = db.query(models.AIContext).filter(
        models.AIContext.room_id == request.room_id,
        models.AIContext.is_active == True
    ).first()

    if not ai_context:
        raise HTTPException(status_code=404, detail="활성 컨텍스트를 찾을 수 없습니다.")

    try:
        # 1. AI 응답에서 JSON 데이터 파싱
        task_data = extract_json_safe(ai_content)
    except ValueError as e:
        logger.error("JSON 파싱 실패 | 원본: %.200s | 오류: %s", ai_content, e)
        raise HTTPException(status_code=500, detail="AI 응답을 처리할 수 없습니다.")

    # 2. DB 저장 로직
    try:
        ai_context.question = request.message  # 사용자의 원문 질문 저장
        ai_context.content = task_data         # 파싱된 JSON 객체 저장
        ai_context.answer = ai_content         # 전체 답변 저장
        
        db.commit()
        db.refresh(ai_context)
        logger.info(f"AI 컨텍스트 업데이트 성공 | ID: {ai_context.id}")
    except Exception as db_err:
        db.rollback()
        logger.error(f"DB 저장 중 오류 발생: {str(db_err)}")
        raise HTTPException(status_code=500, detail="데이터베이스 저장에 실패했습니다.")

    return schemas.ChatMessageResponse(
        success=True,
        reply=ai_content,
        ai_context_id=ai_context.id
    )

# --- 2. 프로젝트 주제 추천 API ---
@router.post("/recommend-topics", response_model=schemas.TopicRecommendResponse)
def recommend_topics(request: schemas.TopicRecommendRequest, db: Session = Depends(get_db)):
    # (주의: 이 앞에 OpenAI 호출 로직이 있어야 raw_text가 정의됩니다)
    raw_text = "AI가 생성한 주제 추천 JSON 텍스트"

    try:
        # 마크다운 제거 및 JSON 파싱
        clean_text = raw_text.replace("```json", "").replace("```", "").strip()
        topics_data = json.loads(clean_text)
        
        topics = [
            schemas.RecommendedTopic(
                topic_name=t["topic_name"],
                reason=t["reason"],
                expected_effect=t["expected_effect"],
            )
            for t in topics_data
        ]
    except (json.JSONDecodeError, KeyError) as e:
        logger.error(f"JSON 파싱 실패: {str(e)} | 원본: {raw_text[:300]}")
        raise HTTPException(status_code=500, detail="AI의 응답 형식이 올바르지 않습니다.")

    # DB 저장 로직
    try:
        # 기존 활성 컨텍스트 비활성화
        db.query(models.AIContext).filter(
            models.AIContext.room_id == request.room_id,
            models.AIContext.is_active == True
        ).update({"is_active": False})

        # 새로운 컨텍스트 생성
        new_context = models.AIContext(
            room_id=request.room_id,
            question=f"[{request.subject}] 프로젝트 주제 추천 요청", 
            content=topics_data, 
            is_active=True,
            summary_text=f"{request.subject} 과목 기반 주제 추천 결과입니다."
        )
        
        db.add(new_context)
        db.commit()
        db.refresh(new_context)
        logger.info(f"주제 추천 결과 저장 완료 | ID: {new_context.id}")
    except Exception as db_err:
        db.rollback()
        logger.error(f"주제 추천 결과 DB 저장 중 오류: {str(db_err)}")

    return schemas.TopicRecommendResponse(
        success=True, 
        topics=topics,
        ai_context_id=new_context.id
    )