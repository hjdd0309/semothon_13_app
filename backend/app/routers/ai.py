import os
from openai import OpenAI
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session, joinedload
from app.database import get_db
from app import schemas, models
from app.models import AIContext, Room
import json
import re
import logging
from datetime import datetime, timezone
from typing import List, Optional
from sqlalchemy.exc import IntegrityError

from app.database import get_db
from app import schemas, models
from app.config import settings


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
반드시 주어진 JSON 스키마에 맞는 JSON만 반환해야 한다.
JSON 바깥의 설명, 코드블록, 마크다운은 절대 출력하지 말아라.
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



# ─── Logger ───
logger = logging.getLogger(__name__)

# ─── Constants ───
VALID_PRIORITIES = {"LOW", "MEDIUM", "HIGH"}
DEFAULT_PRIORITY = "MEDIUM"


if api_key:
    client = OpenAI(
        api_key=api_key,
        base_url="https://factchat-cloud.mindlogic.ai/v1/gateway",
    )

MODEL_NAME = "claude-sonnet-4-6"


# ─── Helper Functions ───

def safe_profile(user: models.User, field: str) -> str:
    """UserProfile 관계가 None이거나 해당 필드가 없을 때 안전하게 반환."""
    if user.profile is None:
        return "미입력"
    value = getattr(user.profile, field, None)
    return value.strip() if isinstance(value, str) and value.strip() else "미입력"


def to_utc(dt: Optional[datetime]) -> Optional[datetime]:
    """datetime을 UTC로 변환. None이면 None 반환."""
    if dt is None:
        return None
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def extract_json_safe(text: str) -> dict:
    """AI 응답에서 JSON을 안전하게 추출.
    - 순수 JSON이면 바로 파싱
    - ```json ... ``` 코드 블록이 있으면 내부만 추출
    - 그 외 첫 번째 { ... } 블록을 시도
    """
    if text is None:
        raise ValueError("AI 응답이 비어 있습니다.")

    text = text.strip()

    # 1) 직접 파싱 시도
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass

    # 2) ```json ... ``` 코드 블록 추출
    match = re.search(r"```(?:json)?\s*([\s\S]*?)```", text)
    if match:
        try:
            return json.loads(match.group(1).strip())
        except json.JSONDecodeError:
            pass

    # 3) 첫 번째 { ... } 블록 추출 (중첩 고려)
    start = text.find("{")
    if start != -1:
        depth = 0
        for i in range(start, len(text)):
            if text[i] == "{":
                depth += 1
            elif text[i] == "}":
                depth -= 1
            if depth == 0:
                try:
                    return json.loads(text[start : i + 1])
                except json.JSONDecodeError:
                    break

    raise ValueError(f"유효한 JSON을 찾을 수 없습니다: {text[:200]}")


# ─── Endpoint ───

@router.post("/distribute", response_model=schemas.TaskDistributeResponse)
def distribute_tasks(
    request: schemas.TaskDistributeRequest,
    db: Session = Depends(get_db),
):
    if not client:
        raise HTTPException(status_code=503, detail="AI 서비스를 사용할 수 없습니다.")

    # 1) 방 멤버 조회
    members: List[models.User] = (
        db.query(models.User)
        .options(joinedload(models.User.profile))
        .join(models.RoomMember, models.User.id == models.RoomMember.user_id)
        .filter(
            models.RoomMember.room_id == request.room_id,
            models.RoomMember.join_status == "joined",
        )
        .all()
    )

    if not members:
        raise HTTPException(status_code=404, detail="방에 활성 멤버가 없습니다.")

    valid_user_ids: set[int] = {m.id for m in members}

    # 2) 프롬프트 구성
    team_context = "\n".join(
        f"ID:{m.id} | {m.username} | "
        f"전공:{safe_profile(m, 'major')} | "
        f"MBTI:{safe_profile(m, 'mbti')} | "
        f"성향:{safe_profile(m, 'personality_summary')} | "
        f"역할:{safe_profile(m, 'role')}"
        for m in members
    )

    deadline_str = (
        to_utc(request.deadline).strftime("%Y-%m-%d %H:%M")
        if request.deadline
        else "자율"
    )

    system_prompt = (
        "너는 뛰어난 IT 프로젝트 매니저다. "
        "팀원의 정보를 기반으로 업무를 공평하게 분배해라. "
        "반드시 유효한 JSON만 반환해라. 다른 텍스트 금지."
    )

    user_prompt = f"""
[프로젝트]
주제: {request.final_topic}
마감: {deadline_str}

[팀원 목록]
{team_context}

[출력 형식 - JSON만 반환]
{{
  "tasks": [
    {{
      "title": "태스크 제목",
      "description": "상세 설명",
      "assigned_user_id": 숫자,
      "priority": "LOW | MEDIUM | HIGH",
      "reason": "배정 이유"
    }}
  ]
}}

[규칙]
- assigned_user_id는 반드시 {sorted(valid_user_ids)} 중 하나
- 모든 팀원에게 최소 1개 이상 배정
- priority는 LOW, MEDIUM, HIGH만 허용
"""

    # 3) AI API 호출
    try:
        api_kwargs = dict(
            model=MODEL_NAME,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            temperature=0.3,
        )
        # response_format은 일부 모델/게이트웨이에서 미지원 → 실패 시 제외하고 재시도
        try:
            api_kwargs["response_format"] = {"type": "json_object"}
            response = client.chat.completions.create(**api_kwargs)
        except Exception:
            logger.warning("response_format 미지원 — 제외 후 재시도")
            api_kwargs.pop("response_format", None)
            response = client.chat.completions.create(**api_kwargs)

        ai_content = response.choices[0].message.content

    except Exception as e:
        logger.error("AI API 호출 실패: %s", e, exc_info=True)
        raise HTTPException(
            status_code=502,
            detail="AI 서비스 호출에 실패했습니다. 잠시 후 다시 시도해주세요.",
        )

    # 4) JSON 파싱
    try:
        task_data = extract_json_safe(ai_content)
    except ValueError as e:
        logger.error("JSON 파싱 실패 | 원본: %.200s | 오류: %s", ai_content, e)
        raise HTTPException(status_code=500, detail="AI 응답을 처리할 수 없습니다.")

    raw_tasks = task_data.get("tasks")
    if not isinstance(raw_tasks, list) or not raw_tasks:
        logger.error("AI 응답 구조 오류: %s", task_data)
        raise HTTPException(status_code=500, detail="AI가 올바른 태스크를 생성하지 못했습니다.")

    # 5) 태스크 검증
    validated_tasks = []

    for i, t in enumerate(raw_tasks, start=1):
        title = (t.get("title") or "").strip()
        if not title:
            raise HTTPException(status_code=500, detail=f"{i}번째 태스크에 title이 없습니다.")

        assigned_id = t.get("assigned_user_id")
        if assigned_id not in valid_user_ids:
            logger.warning(
                "잘못된 user_id 반환됨: %s (유효: %s)", assigned_id, valid_user_ids
            )
            raise HTTPException(
                status_code=500,
                detail=f"\'{title}\': AI가 잘못된 팀원 ID를 반환했습니다.",
            )

        priority = (t.get("priority") or DEFAULT_PRIORITY).upper().strip()
        if priority not in VALID_PRIORITIES:
            logger.warning(
                "잘못된 priority '%s' → MEDIUM 폴백 (task: %s)", priority, title
            )
            priority = DEFAULT_PRIORITY

        validated_tasks.append(
            {
                "title": title,
                "description": (t.get("description") or "").strip(),
                "assigned_user_id": assigned_id,
                "priority": priority,
                "reason": (t.get("reason") or "").strip(),
            }
        )

    unassigned = valid_user_ids - {t["assigned_user_id"] for t in validated_tasks}
    if unassigned:
        raise HTTPException(
            status_code=500,
            detail=f"일부 팀원에게 태스크가 배정되지 않았습니다. (미배정 ID: {sorted(unassigned)})",
        )

    # 6) DB 저장
    try:
        task_objects: List[models.Task] = [
            models.Task(
                room_id=request.room_id,
                assigned_user_id=t["assigned_user_id"],
                title=t["title"],
                description=t["description"],
                priority=t["priority"],
                due_date=to_utc(request.deadline),   # None이면 None 저장 (안전)
                created_by="AI",
                status="TODO",
                progress_percent=0,
            )
            for t in validated_tasks
        ]

        db.add_all(task_objects)
        db.flush()
        db.commit()

    except IntegrityError as e:
        db.rollback()
        logger.error("DB 무결성 오류: %s", e, exc_info=True)
        raise HTTPException(
            status_code=400, detail="데이터 저장 중 무결성 오류가 발생했습니다."
        )
    except Exception as e:
        db.rollback()
        logger.error("DB 저장 실패: %s", e, exc_info=True)
        raise HTTPException(status_code=500, detail="데이터 저장에 실패했습니다.")

    # 7) 응답 반환
    return schemas.TaskDistributeResponse(
        success=True,
        tasks=[
            schemas.GeneratedTask(
                title=obj.title,
                description=obj.description or "",
                assigned_user_id=obj.assigned_user_id,
                reason=vt["reason"],
            )
            for obj, vt in zip(task_objects, validated_tasks)
        ],
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
