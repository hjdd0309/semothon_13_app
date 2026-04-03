from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models import User, Room, Todo
from app.schemas import (
    TodoCreateRequest,
    TodoUpdateRequest,
    TodoStatusUpdateRequest,
    TodoReorderRequest,
    TodoResponse,
    TodoListResponse,
    TodoSingleResponse,
    MessageResponse,
)
from app.services.todo_service import get_next_sort_order, apply_status_side_effects

router = APIRouter(prefix="/todos", tags=["todos"])

@router.post("", response_model=TodoSingleResponse, status_code=status.HTTP_201_CREATED)
def create_todo(
    request: TodoCreateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    room = db.query(Room).filter(Room.id == request.room_id).first()
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")

    if request.assignee_user_id is not None:
        assignee = db.query(User).filter(User.id == request.assignee_user_id).first()
        if not assignee:
            raise HTTPException(status_code=404, detail="Assignee user not found")

    sort_order = request.sort_order
    if sort_order is None:
        sort_order = get_next_sort_order(db, request.room_id)

    todo = Todo(
        room_id=request.room_id,
        creator_user_id=current_user.id,
        assignee_user_id=request.assignee_user_id,
        title=request.title,
        description=request.description,
        status=request.status,
        success_flag=request.success_flag,
        progress_percent=request.progress_percent,
        priority=request.priority,
        category=request.category,
        tag=request.tag,
        start_date=request.start_date,
        due_date=request.due_date,
        completed_at=request.completed_at,
        estimated_minutes=request.estimated_minutes,
        actual_minutes=request.actual_minutes,
        is_recurring=request.is_recurring,
        recurrence_rule=request.recurrence_rule,
        visibility=request.visibility,
        source_type=request.source_type,
        ai_suggested=request.ai_suggested,
        sort_order=sort_order,
        archived=request.archived,
        deleted=request.deleted,
    )

    apply_status_side_effects(todo)

    db.add(todo)
    db.commit()
    db.refresh(todo)

    return {"success": True, "todo": todo}

@router.get("/me", response_model=TodoListResponse)
def get_my_todos(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    include_archived: bool = Query(False),
    include_deleted: bool = Query(False),
    status_filter: Optional[str] = Query(None),
):
    query = db.query(Todo).filter(Todo.assignee_user_id == current_user.id)

    if not include_archived:
        query = query.filter((Todo.archived.is_(False)) | (Todo.archived.is_(None)))

    if not include_deleted:
        query = query.filter((Todo.deleted.is_(False)) | (Todo.deleted.is_(None)))

    if status_filter:
        query = query.filter(Todo.status == status_filter)

    todos = query.order_by(Todo.sort_order.asc(), Todo.created_at.asc()).all()

    return {"success": True, "todos": todos}

@router.get("/rooms/{room_id}", response_model=TodoListResponse)
def get_room_todos(
    room_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    include_archived: bool = Query(False),
    include_deleted: bool = Query(False),
    assignee_user_id: Optional[int] = Query(None),
    status_filter: Optional[str] = Query(None),
):
    room = db.query(Room).filter(Room.id == room_id).first()
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")

    query = db.query(Todo).filter(Todo.room_id == room_id)

    if not include_archived:
        query = query.filter((Todo.archived.is_(False)) | (Todo.archived.is_(None)))

    if not include_deleted:
        query = query.filter((Todo.deleted.is_(False)) | (Todo.deleted.is_(None)))

    if assignee_user_id is not None:
        query = query.filter(Todo.assignee_user_id == assignee_user_id)

    if status_filter:
        query = query.filter(Todo.status == status_filter)

    todos = query.order_by(Todo.sort_order.asc(), Todo.created_at.asc()).all()

    return {"success": True, "todos": todos}

@router.get("/{todo_id}", response_model=TodoSingleResponse)
def get_todo(
    todo_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    todo = db.query(Todo).filter(Todo.id == todo_id).first()
    if not todo:
        raise HTTPException(status_code=404, detail="Todo not found")

    return {"success": True, "todo": todo}

@router.patch("/{todo_id}", response_model=TodoSingleResponse)
def update_todo(
    todo_id: int,
    request: TodoUpdateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    todo = db.query(Todo).filter(Todo.id == todo_id).first()
    if not todo:
        raise HTTPException(status_code=404, detail="Todo not found")

    update_data = request.model_dump(exclude_unset=True)

    if "assignee_user_id" in update_data and update_data["assignee_user_id"] is not None:
        assignee = db.query(User).filter(User.id == update_data["assignee_user_id"]).first()
        if not assignee:
            raise HTTPException(status_code=404, detail="Assignee user not found")

    for field, value in update_data.items():
        setattr(todo, field, value)

    apply_status_side_effects(todo)

    db.commit()
    db.refresh(todo)

    return {"success": True, "todo": todo}

@router.delete("/{todo_id}", response_model=MessageResponse)
def delete_todo(
    todo_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    todo = db.query(Todo).filter(Todo.id == todo_id).first()
    if not todo:
        raise HTTPException(status_code=404, detail="Todo not found")

    todo.deleted = True
    db.commit()

    return {"success": True, "message": "Todo deleted successfully"}

@router.patch("/{todo_id}/status", response_model=TodoSingleResponse)
def update_todo_status(
    todo_id: int,
    request: TodoStatusUpdateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    todo = db.query(Todo).filter(Todo.id == todo_id).first()
    if not todo:
        raise HTTPException(status_code=404, detail="Todo not found")

    todo.status = request.status

    if request.progress_percent is not None:
        todo.progress_percent = request.progress_percent

    if request.success_flag is not None:
        todo.success_flag = request.success_flag

    apply_status_side_effects(todo)

    db.commit()
    db.refresh(todo)

    return {"success": True, "todo": todo}

@router.patch("/{todo_id}/order", response_model=TodoSingleResponse)
def update_todo_order(
    todo_id: int,
    sort_order: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    todo = db.query(Todo).filter(Todo.id == todo_id).first()
    if not todo:
        raise HTTPException(status_code=404, detail="Todo not found")

    todo.sort_order = sort_order
    db.commit()
    db.refresh(todo)

    return {"success": True, "todo": todo}

@router.patch("/rooms/{room_id}/reorder", response_model=MessageResponse)
def reorder_room_todos(
    room_id: int,
    request: TodoReorderRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    room = db.query(Room).filter(Room.id == room_id).first()
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")

    todo_ids = [item.todo_id for item in request.items]
    todos = db.query(Todo).filter(Todo.room_id == room_id, Todo.id.in_(todo_ids)).all()
    todo_map = {todo.id: todo for todo in todos}

    if len(todos) != len(todo_ids):
        raise HTTPException(status_code=400, detail="Some todos do not belong to this room")

    for item in request.items:
        todo_map[item.todo_id].sort_order = item.sort_order

    db.commit()

    return {"success": True, "message": "Todo order updated successfully"}