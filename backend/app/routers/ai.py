import os
from openai import OpenAI
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app import schemas, models
from app.models import AIContext, Room

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


def build_summary_text_from_context_json(context_json: dict) -> str:
    return json.dumps(context_json, ensure_ascii=False, indent=2)


def build_system_ice_breaking_prompt() -> str:
    return """
너는 경희대 팀 프로젝트를 돕는 친근한 AI 코치다.
상냥하게 진행자처럼 말하면 된다.
이모지는 쓰지 말아야 한다.
반드시 주어진 JSON 스키마에 맞는 JSON만 반환해야 한다.
JSON 바깥의 설명, 코드블록, 마크다운은 절대 출력하지 마라.
""".strip()


def build_ice_breaking_prompt(summary_text: str, question: str) -> str:
    return f"""
아래는 팀원 정보와 팀 상황에 대한 요약이다.

[팀 정보]
{summary_text}

[질문]
{question}

[목표]
- 팀원 각자의 성향을 부드럽게 해석
- 팀 전체 분위기를 요약
- 어색함을 줄일 대화 포인트 제안

[해석 원칙]
- 입력은 제한적 정보이므로 과도하게 단정하지 말 것
- 성격을 진단하지 말고 경향 수준으로 설명할 것

[출력 규칙]
- 반드시 JSON 하나만 반환
- 모든 key는 영문으로 유지
- questions는 문자열 리스트로 반환
- character는 "member_name", "traits", "interaction_points"를 가진 객체들의 리스트로 반환
- 실제 팀플에 바로 활용할 수 있게 구체적으로 작성
""".strip()

def get_ice_breaking_json_schema():
    return {
        "name": "ice_breaking",
        "strict": True,
        "schema": {
            "type": "object",
            "properties": {
                "mood": {"type": "string"},
                "characters": {
                    "type": "array",
                    "items": {"type": "string"}
                },
                "universal": {"type": "string"},
                "caution": {"type": "string"},
                "questions": {
                    "type": "array",
                    "items": {"type": "string"}
                },
                "first_talk": {"type": "string"}
            },
            "required": [
                "mood",
                "characters",
                "universal",
                "caution",
                "questions",
                "first_talk"
            ],
            "additionalProperties": False
        }
    }


@router.post(
    "/ice-breaking",
    response_model=schemas.IceBreakingResponse,
    summary="아이스브레이킹 및 팀 성향 분석",
    description=(
        "팀원 정보(text 또는 json)를 받아 AI가 팀 전체 성향, 팀원 특징, "
        "시너지, 아이스브레이킹 포인트를 분석합니다. "
        "질문과 답변은 ai_contexts 테이블에 저장됩니다."
    )
)
def analyze_ice_breaking(
    request: schemas.IceBreakingRequest,
    db: Session = Depends(get_db)
):
    if not client:
        raise HTTPException(status_code=500, detail="API Key is not configured")

    room = db.query(Room).filter(Room.id == request.room_id).first()
    if room is None:
        raise HTTPException(status_code=404, detail="해당 room이 존재하지 않습니다.")

    if request.summary_text:
        final_summary_text = request.summary_text
    else:
        final_summary_text = build_summary_text_from_context_json(request.context_json)

    prompt = build_ice_breaking_prompt(
        summary_text=final_summary_text,
        question=request.question
    )
    system_prompt = build_system_ice_breaking_prompt()

    try:
        response = client.chat.completions.create(
            model=MODEL_NAME,
            messages=[
                {
                    "role": "system",
                    "content": system_prompt,
                },
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            response_format={
                "type": "json_schema",
                "json_schema": get_ice_breaking_json_schema()
            },
            temperature=0.7,
        )

        raw_content = response.choices[0].message.content
        try:
            analysis_report = json.loads(raw_content)
        except:
            analysis_report = {"raw": raw_content}
        print(raw_content)
        

    except json.JSONDecodeError:
        raise HTTPException(
            status_code=500,
            detail="AI 응답을 JSON으로 파싱하지 못했습니다."
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"AI 분석 호출 중 오류가 발생했습니다: {str(e)}"
        )

    db.query(AIContext).filter(
        AIContext.room_id == request.room_id,
        AIContext.context_type == "ice_breaking",
        AIContext.is_active == True
    ).update({"is_active": False}, synchronize_session=False)

    new_ai_context = AIContext(
        room_id=request.room_id,
        context_type="ice_breaking",
        title=request.title,
        context_json=request.context_json,
        summary_text=final_summary_text,
        question=request.question,
        answer=json.dumps(analysis_report, ensure_ascii=False),  # JSON 문자열로 저장
        version=1,
        is_active=True,
    )

    db.add(new_ai_context)
    db.commit()
    db.refresh(new_ai_context)

    return schemas.IceBreakingResponse(
        success=True,
        message="아이스브레이킹 분석이 완료되었습니다.",
        analysis_report=analysis_report,  # dict 그대로 반환
        ai_context_id=new_ai_context.id
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

def build_system_chat_prompt() -> str:
    return """
너는 경희대 팀 프로젝트를 돕는 친근한 AI 코치다.
상냥하고 자연스럽게 답하되, 너무 가볍지 말고 실제로 도움이 되게 답해라.
이모지는 쓰지 말아야 한다.
반드시 한국어로 답변하라.
주어진 팀 정보와 상황 요약을 우선적으로 참고해서 답하라.
정보가 부족하면 과도하게 추측하지 말고, 부족한 점을 자연스럽게 언급하라.
""".strip()


def build_chat_prompt(summary_text: str, question: str) -> str:
    return f"""
아래는 현재 팀 프로젝트에 대한 요약 정보다.

[팀 정보]
{summary_text}

[사용자 질문]
{question}

[답변 목표]
- 팀 상황에 맞는 실질적인 조언 제공
- 추상적인 말보다 바로 활용 가능한 답변 제공
- 필요하면 우선순위나 다음 행동을 제안

[주의사항]
- 팀 정보에 없는 내용을 과도하게 단정하지 말 것
- 질문에 직접적으로 답할 것
- 너무 장황하지 않되, 핵심은 충분히 설명할 것
""".strip()

@router.post(
    "/chat",
    response_model=schemas.ChatMessageResponse,
    summary="팀 컨텍스트 기반 AI Q&A",
    description=(
        "해당 room의 활성 AI 컨텍스트를 불러와 summary_text를 기반으로 "
        "사용자 질문에 답변합니다. 답변은 ai_contexts 테이블에도 저장됩니다."
    )
)
def chat_with_bot(
    request: schemas.ChatMessageRequest,
    db: Session = Depends(get_db)
):
    if not client:
        raise HTTPException(status_code=500, detail="API Key is not configured")

    room = db.query(Room).filter(Room.id == request.room_id).first()
    if room is None:
        raise HTTPException(status_code=404, detail="해당 room이 존재하지 않습니다.")

    ai_context = (
        db.query(AIContext)
        .filter(
            AIContext.room_id == request.room_id,
            AIContext.is_active == True
        )
        .order_by(AIContext.updated_at.desc())
        .first()
    )

    if ai_context is None:
        raise HTTPException(
            status_code=404,
            detail="해당 room의 활성 AI 컨텍스트가 존재하지 않습니다."
        )

    if not ai_context.summary_text:
        raise HTTPException(
            status_code=400,
            detail="활성 AI 컨텍스트의 summary_text가 비어 있습니다."
        )

    prompt = build_chat_prompt(
        summary_text=ai_context.summary_text,
        question=request.message
    )
    system_prompt = build_system_chat_prompt()

    try:
        response = client.chat.completions.create(
            model=MODEL_NAME,
            messages=[
                {
                    "role": "system",
                    "content": system_prompt,
                },
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            temperature=0.7,
        )

        answer_text = response.choices[0].message.content.strip()

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"AI 답변 호출 중 오류가 발생했습니다: {str(e)}"
        )

    ai_context.answer = answer_text
    db.commit()
    db.refresh(ai_context)

    return schemas.ChatMessageResponse(
        success=True,
        reply=answer_text,
        ai_context_id=ai_context.id
    )