from datetime import datetime
from sqlalchemy.orm import Session
from sqlalchemy import func


from app.models import User, Room, Todo


def get_next_sort_order(db: Session, room_id: int) -> int:
    max_order = db.query(func.max(Todo.sort_order)).filter(
        Todo.room_id == room_id,
        Todo.deleted.isnot(True)
    ).scalar()

    return (max_order or 0) + 1


def apply_status_side_effects(todo: Todo) -> None:
    if todo.status == "DONE":
        if todo.progress_percent is None or todo.progress_percent < 100:
            todo.progress_percent = 100
        if todo.completed_at is None:
            todo.completed_at = datetime.utcnow()
        if todo.success_flag is None:
            todo.success_flag = True
    elif todo.status in ("TODO", "IN_PROGRESS", "BLOCKED", "REVIEW", "CANCELLED"):
        if todo.status != "DONE":
            # 필요시 완료시간 해제
            if todo.status == "CANCELLED" and todo.success_flag is None:
                todo.success_flag = False