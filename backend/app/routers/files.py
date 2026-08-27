import os
import uuid
from pathlib import Path
from typing import Optional

from fastapi import (
    APIRouter,
    Depends,
    File as FastAPIFile,
    Form,
    HTTPException,
    UploadFile,
    status,
)
from fastapi.responses import RedirectResponse
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.database import get_db
from app.dependencies import get_current_user
from app.models import File, Room, RoomMember, Task, User, UserProfile
from app.schemas import FileResponse, FileDetailResponse, FileDownloadResponse
from app.services.r2 import upload_bytes, generate_download_url, generate_view_url

router = APIRouter(prefix="/files", tags=["files"])


def _check_room_member(db: Session, room_id: int, user_id: int) -> None:
    member = (
        db.query(RoomMember)
        .filter(RoomMember.room_id == room_id, RoomMember.user_id == user_id)
        .first()
    )
    if not member:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="해당 방에 속한 사용자만 파일에 접근할 수 있습니다.",
        )


@router.post(
    "/upload",
    response_model=FileResponse,
    summary="파일 업로드",
    description="Flutter 앱에서 multipart/form-data로 파일을 업로드하면 서버가 Cloudflare R2에 저장하고 DB에 메타데이터를 기록합니다.",
)
async def upload_file(
    room_id: int = Form(...),
    task_id: Optional[int] = Form(None),
    file: UploadFile = FastAPIFile(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    room = db.query(Room).filter(Room.id == room_id).first()
    if not room:
        raise HTTPException(status_code=404, detail="방을 찾을 수 없습니다.")

    _check_room_member(db, room_id, current_user.id)

    if task_id is not None:
        task = db.query(Task).filter(Task.id == task_id, Task.room_id == room_id).first()
        if not task:
            raise HTTPException(status_code=404, detail="해당 task를 찾을 수 없습니다.")

    file_bytes = await file.read()
    if not file_bytes:
        raise HTTPException(status_code=400, detail="빈 파일은 업로드할 수 없습니다.")

    original_name = file.filename or "unknown"
    ext = Path(original_name).suffix
    stored_name = f"{uuid.uuid4().hex}{ext}"

    # object key 예시: rooms/3/tasks/10/uuid.pdf 또는 rooms/3/general/uuid.pdf
    if task_id is not None:
        object_key = f"rooms/{room_id}/tasks/{task_id}/{stored_name}"
    else:
        object_key = f"rooms/{room_id}/general/{stored_name}"

    mime_type = file.content_type
    file_size = len(file_bytes)

    upload_bytes(
        data=file_bytes,
        object_key=object_key,
        content_type=mime_type,
        original_filename=original_name,
    )

    # public bucket이 아니라면 영구 URL 대신 내부 API 경로를 넣는 편이 낫다
    new_file = File(
        room_id=room_id,
        uploaded_by=current_user.id,
        task_id=task_id,
        original_name=original_name,
        stored_name=stored_name,
        object_key=object_key,
        file_url="",
        mime_type=mime_type,
        file_size=file_size,
    )
    db.add(new_file)
    db.commit()
    db.refresh(new_file)

    new_file.file_url = f"/files/{new_file.id}/download"
    db.commit()
    db.refresh(new_file)

    return new_file


@router.get(
    "/{file_id}",
    response_model=FileDetailResponse,
    summary="파일 상세 조회",
    description="파일의 메타데이터를 조회합니다.",
)
def get_file_detail(
    file_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = (
        db.query(
            File,
            Task.title.label("task_title"),
            func.coalesce(UserProfile.display_name, User.username).label("uploaded_by_name"),
        )
        .join(User, File.uploaded_by == User.id)
        .outerjoin(UserProfile, UserProfile.user_id == User.id)
        .outerjoin(Task, File.task_id == Task.id)
        .filter(File.id == file_id)
        .first()
    )

    if not result:
        raise HTTPException(status_code=404, detail="파일을 찾을 수 없습니다.")

    file_obj, task_title, uploaded_by_name = result

    _check_room_member(db, file_obj.room_id, current_user.id)

    return {
        "id": file_obj.id,
        "room_id": file_obj.room_id,
        "task_id": file_obj.task_id,
        "task_title": task_title,
        "uploaded_by": file_obj.uploaded_by,
        "uploaded_by_name": uploaded_by_name,
        "original_name": file_obj.original_name,
        "stored_name": file_obj.stored_name,
        "object_key": file_obj.object_key,
        "mime_type": file_obj.mime_type,
        "file_size": file_obj.file_size,
        "created_at": file_obj.created_at,
    }


# @router.get(
#     "/{file_id}/download",
#     summary="파일 다운로드",
#     description="권한 확인 후 Cloudflare R2 presigned 다운로드 URL로 리다이렉트합니다.",
# )
# def download_file(
#     file_id: int,
#     db: Session = Depends(get_db),
#     current_user: User = Depends(get_current_user),
# ):
#     file_obj = db.query(File).filter(File.id == file_id).first()
#     if not file_obj:
#         raise HTTPException(status_code=404, detail="파일을 찾을 수 없습니다.")

#     _check_room_member(db, file_obj.room_id, current_user.id)

#     download_url = generate_download_url(
#         object_key=file_obj.object_key,
#         download_filename=file_obj.original_name,
#         expires_in=3600,
#     )
#     return RedirectResponse(url=download_url, status_code=307)


@router.get(
    "/{file_id}/download-url",
    response_model=FileDownloadResponse,
    summary="파일 다운로드 URL 발급",
    description="Flutter 앱이 직접 URL을 받아서 다운로드할 수 있도록 presigned URL을 반환합니다.",
)
def get_download_url(
    file_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    file_obj = db.query(File).filter(File.id == file_id).first()
    if not file_obj:
        raise HTTPException(status_code=404, detail="파일을 찾을 수 없습니다.")

    _check_room_member(db, file_obj.room_id, current_user.id)

    expires_in = 3600
    download_url = generate_download_url(
        object_key=file_obj.object_key,
        download_filename=file_obj.original_name,
        expires_in=expires_in,
    )

    return FileDownloadResponse(
        file_id=file_obj.id,
        download_url=download_url,
        expires_in=expires_in,
    )


# @router.get(
#     "/{file_id}/view",
#     summary="파일 보기",
#     description="가능한 경우 inline으로 열 수 있는 presigned URL로 리다이렉트합니다.",
# )
# def view_file(
#     file_id: int,
#     db: Session = Depends(get_db),
#     current_user: User = Depends(get_current_user),
# ):
#     file_obj = db.query(File).filter(File.id == file_id).first()
#     if not file_obj:
#         raise HTTPException(status_code=404, detail="파일을 찾을 수 없습니다.")

#     _check_room_member(db, file_obj.room_id, current_user.id)

#     view_url = generate_view_url(
#         object_key=file_obj.object_key,
#         inline_filename=file_obj.original_name,
#         expires_in=3600,
#     )
#     return RedirectResponse(url=view_url, status_code=307)