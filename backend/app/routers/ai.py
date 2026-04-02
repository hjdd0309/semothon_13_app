import os
from openai import OpenAI
from fastapi import APIRouter, Depends, HTTPException, Query
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

# ---------------------------------------------------------------------------
# 과목별 질문 목록 (하드코딩)
# ---------------------------------------------------------------------------
SUBJECT_QUESTIONS: dict = {
    "디자인적 사고": {
        "questions": [
            {
                "index": 1,
                "text": "최근 흥미로웠던 개발 주제가 있으신가요? (중복 가능)",
                "type": "multiple_choice",
                "multiple": True,
                "options": ["사회 문제 해결", "재미있는 서비스", "기술적으로 도전적인", "창업 아이디어", "생활 편의 서비스"]
            },
            {
                "index": 2,
                "text": "어떤 개발 경험이 있으신가요? (중복 가능)",
                "type": "multiple_choice",
                "multiple": True,
                "options": ["디자인 (UI/UX)", "게임 개발", "웹 프로그래밍", "앱 프로그래밍", "AI / 머신러닝", "시스템 프로그래밍", "데이터 분석"]
            },
            {
                "index": 3,
                "text": "이건 정말 창의적이다라고 생각되시는 아이디어가 있나요?",
                "type": "free_text",
                "multiple": None,
                "options": None
            },
            {
                "index": 4,
                "text": "관심있는 문제 영역이 있나요?",
                "type": "multiple_choice",
                "multiple": True,
                "options": ["교육", "환경", "건강", "교통", "커뮤니티", "게임 / 엔터테인먼트", "생산성"]
            },
            {
                "index": 5,
                "text": "프로젝트 결과물이 어디까지 나오면 좋겠나요?",
                "type": "multiple_choice",
                "multiple": False,
                "options": ["아이디어 기획 중심", "간단한 프로토타입", "핵심 기능 구현", "대부분 기능 구현", "실제 배포 가능 수준"]
            },
        ],
        "tip": "디자인적 사고는 개발보다 디자인적 사고를 거쳐 도출하는 아이디어가 더 중요합니다. 기술 구현보다 문제 정의와 창의성에 초점을 맞춰 주제를 추천하세요."
    },
    "세계와 시민": {
        "questions": [
            {
                "index": 1,
                "text": "우리 조가 다뤄봤으면 하는 사회문제 분야는 무엇인가요? (1~2개 선택)",
                "type": "multiple_choice",
                "multiple": True,
                "options": ["환경/생태", "인권/복지", "생활/안전", "교육/문화", "기술/과학", "기타"]
            },
            {
                "index": 2,
                "text": "최근 일상생활에서 불편을 느끼거나 문제라고 생각했던 경험이 있다면 무엇인가요?",
                "type": "free_text",
                "multiple": None,
                "options": None
            },
            {
                "index": 3,
                "text": "해결하는 사회문제 혹은 해결을 위한 노력이 어떤 범위에서 이루어졌으면 좋겠나요?",
                "type": "multiple_choice",
                "multiple": False,
                "options": ["캠퍼스", "지역사회", "대한민국/국가 및 글로벌"]
            },
            {
                "index": 4,
                "text": "이번 활동에서 대변하거나 돕고싶은 구체적 대상은 누구인가요?",
                "type": "free_text",
                "multiple": None,
                "options": None
            },
            {
                "index": 5,
                "text": "사회문제를 조사하고 해결하는 과정에서 특히 도전해보고 싶은 해결 방식은 무엇인가요? (1~2개 선택)",
                "type": "multiple_choice",
                "multiple": True,
                "options": ["숏폼 영상 제작", "오프라인 캠페인", "카드뉴스 제작", "SNS 운영", "제도 제안 및 문제 상황 신고 활동", "기타"]
            },
        ],
        "tip": "세계와 시민 과목은 사회문제 해결에 초점을 맞춥니다. 팀원들이 관심 갖는 사회 이슈와 표현 방식을 중심으로, 실제로 실행 가능한 캠페인·콘텐츠 형태의 주제를 추천하세요."
    },
    "데이터분석캡스톤디자인": {
        "questions": [
            {
                "index": 1,
                "text": "가장 흥미를 느끼는 산업/도메인은 무엇인가요? (최대 3개 선택)",
                "type": "multiple_choice",
                "multiple": True,
                "options": ["스마트시티 / 교통", "헬스케어 / 스포츠", "엔터테인먼트 / 미디어", "금융 / 경제", "소셜 / 커뮤니티", "기타"]
            },
            {
                "index": 2,
                "text": "이번 프로젝트에서 메인으로 다뤄보고 싶은 데이터의 종류는 무엇인가요? (1~2개 선택)",
                "type": "multiple_choice",
                "multiple": True,
                "options": ["이미지 / 영상 데이터 (컴퓨터 비전)", "텍스트 데이터 (자연어 처리, LLM 활용)", "정형 데이터 (CSV, DB 형태)", "시계열 데이터"]
            },
            {
                "index": 3,
                "text": "우리 팀의 최종 결과물은 어떤 형태였으면 좋겠나요?",
                "type": "multiple_choice",
                "multiple": False,
                "options": ["실제 사용 가능한 웹/앱 서비스", "가벼운 환경에서 동작하는 온디바이스 AI 어플리케이션", "데이터 시각화 중심의 대시보드 (Streamlit 등)", "특정 모델의 성능 개선 및 분석 결과 중심의 리포트/논문"]
            },
            {
                "index": 4,
                "text": "이번 학기에 꼭 활용해 보거나 역량을 키우고 싶은 기술 스택이 있나요? (자유 기재)",
                "type": "free_text",
                "multiple": None,
                "options": None
            },
            {
                "index": 5,
                "text": "최근 일상이나 전공 공부 중 '이거 데이터로 해결하거나 자동화할 수 있지 않을까?'라고 생각했던 불편함이나 호기심을 자유롭게 적어주세요.",
                "type": "free_text",
                "multiple": None,
                "options": None
            },
        ],
        "tip": "데이터분석 캡스톤디자인은 데이터 기반의 분석·모델링·서비스 구현에 초점을 맞춥니다. 팀원들의 관심 도메인, 희망 데이터 유형, 결과물 형태를 최우선으로 고려하여 실현 가능한 주제를 추천하세요."
    },
}

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

@router.get("/topics/questions", response_model=schemas.SubjectQuestionsResponse)
def get_topic_questions(subject: str = Query(..., description="과목명. 예: 디자인적 사고")):
    """
    [Phase 2 - 사전 요청] 과목별 주제 선정 질문 목록 조회
    프론트엔드가 질문을 렌더링하기 위해 먼저 호출합니다.
    """
    subject_data = SUBJECT_QUESTIONS.get(subject)
    if not subject_data:
        raise HTTPException(
            status_code=404,
            detail=f"'{subject}'은(는) 지원하지 않는 과목입니다. 지원 과목: {list(SUBJECT_QUESTIONS.keys())}"
        )

    questions = [
        schemas.QuestionItem(
            index=q["index"],
            text=q["text"],
            type=q["type"],
            multiple=q.get("multiple"),
            options=q.get("options"),
        )
        for q in subject_data["questions"]
    ]

    return schemas.SubjectQuestionsResponse(
        subject=subject,
        questions=questions,
        tip=subject_data.get("tip")
    )


@router.post("/topics", response_model=schemas.TopicRecommendResponse)
def recommend_topics(request: schemas.TopicRecommendRequest, db: Session = Depends(get_db)):
    """
    [Phase 2] 주제 추천 API
    팀원 전체의 답변을 종합하여 LLM이 해당 과목에 맞는 프로젝트 주제 3개를 추천합니다.
    """
    if not client:
        raise HTTPException(status_code=500, detail="API Key is not configured")

    # 1. 과목 유효성 확인
    subject_data = SUBJECT_QUESTIONS.get(request.subject)
    if not subject_data:
        raise HTTPException(
            status_code=400,
            detail=f"지원하지 않는 과목입니다. 지원 과목: {list(SUBJECT_QUESTIONS.keys())}"
        )

    # 2. 룸 존재 여부 확인
    room = db.query(models.Room).filter(models.Room.id == request.room_id).first()
    if not room:
        raise HTTPException(status_code=404, detail="해당 룸을 찾을 수 없습니다.")

    # 3. 룸 멤버 프로필 조회 (user_id → username 매핑)
    members = (
        db.query(models.User, models.UserProfile)
        .join(models.RoomMember, models.RoomMember.user_id == models.User.id)
        .outerjoin(models.UserProfile, models.UserProfile.user_id == models.User.id)
        .filter(models.RoomMember.room_id == request.room_id)
        .all()
    )
    user_map = {user.id: user.username for user, _ in members}

    # 4. 질문 목록 텍스트화
    questions = subject_data["questions"]
    questions_text = "\n".join(
        [f"Q{q['index']}. {q['text']}" for q in questions]
    )

    # 5. 팀원별 답변 집계
    all_answers_text = ""
    for member_ans in request.member_answers:
        username = user_map.get(member_ans.user_id, f"user_{member_ans.user_id}")
        all_answers_text += f"\n[{username}의 답변]\n"
        for idx, answer in enumerate(member_ans.answers):
            q_text = questions[idx]["text"] if idx < len(questions) else f"질문 {idx+1}"
            all_answers_text += f"  Q{idx+1}. {q_text}\n  → {answer}\n"

    # 6. 프롬프트 구성
    tip_text = subject_data.get("tip", "")

    system_prompt = (
        f"너는 '{request.subject}' 과목의 팀 프로젝트 주제 추천 전문가 AI야.\n"
        f"[과목 핵심 방향] {tip_text}\n\n"
        "팀원들의 답변을 종합 분석하여, 팀 전체에 가장 잘 맞는 프로젝트 주제 3개를 추천해줘.\n"
        "반드시 아래 JSON 형식만 출력하고, 설명·마크다운 코드블록 없이 순수 JSON 배열만 반환해야 해.\n\n"
        "출력 형식:\n"
        "[\n"
        "  {\"topic_name\": \"주제명\", \"reason\": \"이 팀에 맞는 추천 이유\", \"expected_effect\": \"기대 효과\"},\n"
        "  ...\n"
        "]"
    )

    user_prompt = (
        f"[과목] {request.subject}\n\n"
        f"[질문 목록]\n{questions_text}\n\n"
        f"[팀원별 답변]\n{all_answers_text}\n\n"
        "위 내용을 바탕으로 이 팀에게 최적화된 프로젝트 주제 3개를 JSON 배열로 추천해줘."
    )

    # 7. LLM 호출
    try:
        response = client.chat.completions.create(
            model=MODEL_NAME,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
        )
        raw_text = response.choices[0].message.content.strip()
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"AI API 호출 오류: {str(e)}")

    # 8. JSON 파싱
    try:
        topics_data = json.loads(raw_text)
        topics = [
            schemas.RecommendedTopic(
                topic_name=t["topic_name"],
                reason=t["reason"],
                expected_effect=t["expected_effect"],
            )
            for t in topics_data
        ]
    except (json.JSONDecodeError, KeyError):
        raise HTTPException(
            status_code=500,
            detail=f"AI 응답 파싱 실패. 원본 응답: {raw_text[:300]}"
        )

    return schemas.TopicRecommendResponse(success=True, topics=topics)


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