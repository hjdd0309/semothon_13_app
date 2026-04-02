from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload
from sqlalchemy.exc import IntegrityError
from sqlalchemy import case
from datetime import datetime, timezone
from typing import Optional
from enum import Enum

from app.database import get_db
from app.models import Task
from app.schemas import TaskCreateRequest, TaskResponse, TaskListResponse, TaskAssignedUser

router = APIRouter(prefix="/tasks", tags=["Tasks"])


class PriorityEnum(str, Enum):
    LOW = "LOW"
    MEDIUM = "MEDIUM"
    HIGH = "HIGH"


class CreatedByEnum(str, Enum):
    AI = "AI"
    USER = "USER"


def get_now() -> datetime:
    return datetime.now(timezone.utc)


def to_utc(dt: Optional[datetime]) -> Optional[datetime]:
    if dt is None:
        return None
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt


def is_overdue(task: Task, now: datetime) -> bool:
    due = to_utc(task.due_date)
    now = to_utc(now)
    return bool(due and due < now and task.status != "DONE")


def make_ai_comment(task: Task) -> str:
    now = get_now()
    if is_overdue(task, now):
        return f" '{task.title}' 마감이 지났습니다!"
    if task.priority == "HIGH":
        if task.progress_percent == 0:
            return f" '{task.title}' HIGH 우선순위에요!"
        elif task.progress_percent >= 80:
            return f" '{task.title}' 거의 끝났어요! "
        return f"'{task.title}' HIGH 우선순위예요!"
    return f" '{task.title}' 태스크 등록 완료. "


def make_ai_alert(overdue_count: int) -> Optional[str]:
    if overdue_count == 0:
        return None
    return f" 경고: 마감이 지난 태스크가 {overdue_count}개 있어요!"


def serialize_task(task: Task) -> TaskResponse:
    assigned_user = None
    if task.assigned_user:
        assigned_user = TaskAssignedUser(
            id=task.assigned_user.id,
            username=task.assigned_user.username
        )
    return TaskResponse(
        id=task.id,
        room_id=task.room_id,
        assigned_user_id=task.assigned_user_id,
        title=task.title,
        description=task.description,
        status=task.status,
        priority=task.priority,
        progress_percent=task.progress_percent,
        due_date=task.due_date,
        created_by=task.created_by,
        created_at=task.created_at,
        updated_at=task.updated_at,
        assigned_user=assigned_user,
        ai_comment=make_ai_comment(task),
    )


# ──────────────────────────────────
# POST /tasks/ 태스크 생성
# ──────────────────────────────────
@router.post(
    "/", 
    response_model=TaskResponse, 
    status_code=status.HTTP_201_CREATED,
    summary="태스크 생성",
    description="새로운 태스크를 생성하고 AI 팀장의 분석 코멘트를 함께 반환합니다."
)
def create_task(body: TaskCreateRequest, db: Session = Depends(get_db)):
    """
    **태스크 생성 시 주의사항:**
    - room_id와 assigned_user_id는 실제 존재하는 ID여야 합니다.
    - priority는 'LOW', 'MEDIUM', 'HIGH' 중 하나를 입력하세요.
    """
    new_task = Task(
        room_id=body.room_id,
        assigned_user_id=body.assigned_user_id,
        title=body.title,
        description=body.description,
        priority=body.priority,
        due_date=body.due_date,
        created_by=body.created_by,
        status="TODO",
        progress_percent=0,
    )

    try:
        db.add(new_task)
        db.commit()
        db.refresh(new_task)
    except IntegrityError as e:
        db.rollback()
        raise HTTPException(
            status_code=400,
            detail=f"DB 오류: 데이터 무결성 제약 조건 위반 (외래키 등 확인 필요)"
        )

    return serialize_task(new_task)


# ──────────────────────────────────
# GET /tasks/room/{room_id} 태스크 목록 조회
# ──────────────────────────────────
@router.get(
    "/room/{room_id}", 
    response_model=TaskListResponse,
    summary="방별 태스크 목록 조회",
    description="특정 방의 모든 태스크를 우선순위와 마감일 순서로 정렬하여 가져옵니다. 지연된 태스크 개수에 따른 AI 알림이 포함됩니다."
)
def get_tasks_by_room(room_id: int, db: Session = Depends(get_db)):
    # DB에서 우선순위 정렬 (HIGH -> MEDIUM -> LOW)
    priority_case = case(
        (Task.priority == "HIGH", 0),
        (Task.priority == "MEDIUM", 1),
        (Task.priority == "LOW", 2),
        else_=99
    )

    tasks = (
        db.query(Task)
        .options(joinedload(Task.assigned_user))
        .filter(Task.room_id == room_id)
        .order_by(priority_case, Task.due_date)
        .all()
    )

    if not tasks:
        return TaskListResponse(
            tasks=[],
            total=0,
            overdue_count=0,
            ai_alert=None
        )

    now = get_now()
    overdue_count = sum(1 for t in tasks if is_overdue(t, now))

    return TaskListResponse(
        tasks=[serialize_task(t) for t in tasks],
        total=len(tasks),
        overdue_count=overdue_count,
        ai_alert=make_ai_alert(overdue_count),
    )
