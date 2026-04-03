import asyncio

from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect, status
from sqlalchemy.orm import Session, joinedload

from app.database import get_db, SessionLocal
from app.dependencies import get_current_user
from app.models import User, Room, RoomMember, ChatMessage
from app import schemas
from app.websocket.chat_manager import chat_manager

router = APIRouter(
    prefix="/chat",
    tags=["Chat"]
)

def to_chat_message_item(chat_message: ChatMessage) -> schemas.ChatMessageItem:
    sender_name = "알 수 없음"

    if chat_message.message_type == "AI":
        sender_name = "AI"
    elif chat_message.message_type == "SYSTEM":
        sender_name = "SYSTEM"
    elif chat_message.sender is not None:
        sender_name = chat_message.sender.username

    return schemas.ChatMessageItem(
        id=chat_message.id,
        room_id=chat_message.room_id,
        sender_user_id=chat_message.sender_user_id,
        sender_name=sender_name,
        message_type=chat_message.message_type,
        content=chat_message.content,
        image_url=chat_message.image_url,
        related_file_id=chat_message.related_file_id,
        created_at=chat_message.created_at,
    )

@router.get(
    "/rooms/{room_id}/messages",
    response_model=schemas.ChatMessageListResponse,
    summary="채팅 메시지 목록 조회",
    description="해당 room의 채팅 메시지를 오래된 순으로 조회합니다."
)
def get_chat_messages(
    room_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    room = db.query(Room).filter(Room.id == room_id).first()
    if room is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="해당 room이 존재하지 않습니다."
        )

    membership = (
        db.query(RoomMember)
        .filter(
            RoomMember.room_id == room_id,
            RoomMember.user_id == current_user.id,
            RoomMember.join_status == "JOINED"
        )
        .first()
    )
    if membership is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="해당 room의 멤버만 채팅을 조회할 수 있습니다."
        )

    messages = (
        db.query(ChatMessage)
        .options(joinedload(ChatMessage.sender))
        .filter(ChatMessage.room_id == room_id)
        .order_by(ChatMessage.created_at.asc(), ChatMessage.id.asc())
        .all()
    )

    return schemas.ChatMessageListResponse(
        success=True,
        messages=[to_chat_message_item(m) for m in messages]
    )

@router.post(
    "/rooms/{room_id}/messages",
    response_model=schemas.ChatMessageCreateResponse,
    summary="채팅 메시지 전송",
    description="해당 room에 새 채팅 메시지를 저장하고, 연결된 사용자들에게 실시간으로 전송합니다."
)
def create_chat_message(
    room_id: int,
    request: schemas.ChatMessageCreateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    room = db.query(Room).filter(Room.id == room_id).first()
    if room is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="해당 room이 존재하지 않습니다."
        )

    membership = (
        db.query(RoomMember)
        .filter(
            RoomMember.room_id == room_id,
            RoomMember.user_id == current_user.id,
            RoomMember.join_status == "JOINED"
        )
        .first()
    )
    if membership is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="해당 room의 멤버만 채팅을 보낼 수 있습니다."
        )

    if request.message_type == "TEXT":
        if request.content is None or not request.content.strip():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="TEXT 메시지는 content가 필요합니다."
            )

    if request.message_type == "IMAGE" and not request.image_url:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="IMAGE 메시지는 image_url이 필요합니다."
        )

    # if request.message_type == "FILE" and not request.related_file_id:
    #     raise HTTPException(
    #         status_code=status.HTTP_400_BAD_REQUEST,
    #         detail="FILE 메시지는 related_file_id가 필요합니다."
    #     )

    new_message = ChatMessage(
        room_id=room_id,
        sender_user_id=current_user.id,
        message_type=request.message_type,
        content=request.content.strip() if request.content else None,
        image_url=request.image_url,
        related_file_id=request.related_file_id,
    )

    db.add(new_message)
    db.commit()
    db.refresh(new_message)

    saved_message = (
        db.query(ChatMessage)
        .options(joinedload(ChatMessage.sender))
        .filter(ChatMessage.id == new_message.id)
        .first()
    )

    chat_item = to_chat_message_item(saved_message)

    payload = {
        "type": "chat_message_created",
        "data": chat_item.model_dump(mode="json")
    }

    try:
        loop = asyncio.get_running_loop()
        loop.create_task(chat_manager.broadcast_to_room(room_id, payload))
    except RuntimeError:
        pass

    return schemas.ChatMessageCreateResponse(
        success=True,
        message="메시지를 전송했습니다.",
        chat_message=chat_item
    )

@router.websocket("/ws/rooms/{room_id}")
async def websocket_chat(
    websocket: WebSocket,
    room_id: int,
):
    await chat_manager.connect(room_id, websocket)

    try:
        while True:
            # 프론트가 보내는 ping 또는 keep-alive 메시지를 받음
            await websocket.receive_text()
    except WebSocketDisconnect:
        chat_manager.disconnect(room_id, websocket)
    except Exception:
        chat_manager.disconnect(room_id, websocket)