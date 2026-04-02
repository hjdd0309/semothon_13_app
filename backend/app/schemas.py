from datetime import datetime, time
from typing import Optional, List, Any

from pydantic import BaseModel, EmailStr, Field, ConfigDict, field_validator


class DBCheckResponse(BaseModel):
    success: bool
    message: str
    result: Optional[Any] = None
    error: Optional[str] = None


class SignUpRequest(BaseModel):
    username: str = Field(
        ...,
        min_length=4,
        max_length=20,
        description="로그인에 사용할 아이디",
        examples=["aico_user01"]
    )
    email: EmailStr = Field(
        ...,
        description="사용자 이메일",
        examples=["user@example.com"]
    )
    password: str = Field(
        ...,
        min_length=8,
        max_length=100,
        description="비밀번호. 최소 8자 이상 입력해야 합니다.",
        examples=["StrongPass123!"]
    )


    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "username": "aico_user01",
                "email": "user@example.com",
                "password": "StrongPass123!",
            }
        }
    )


class LoginRequest(BaseModel):
    username: str = Field(
        ...,
        description="로그인 아이디",
        examples=["aico_user01"]
    )
    password: str = Field(
        ...,
        description="로그인 비밀번호",
        examples=["StrongPass123!"]
    )

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "username": "aico_user01",
                "password": "StrongPass123!"
            }
        }
    )


class UserResponse(BaseModel):
    id: int
    username: str
    email: EmailStr
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class SignUpResponse(BaseModel):
    success: bool
    message: str
    user: UserResponse


class LoginResponse(BaseModel):
    success: bool
    message: str
    access_token: str = Field(..., description="JWT access token")
    token_type: str = Field(..., examples=["bearer"])
    user: UserResponse


class MeResponse(BaseModel):
    success: bool
    message: str
    user: UserResponse


class ErrorResponse(BaseModel):
    detail: str


class TokenPayload(BaseModel):
    sub: str
    exp: int
    
class ProfileUpdate(BaseModel):
    email: EmailStr | None = None
    username: Optional[str] = None
    display_name: str | None = Field(default=None, max_length=50)
    mbti: str | None = Field(default=None, max_length=10)
    major: str | None = Field(default=None, max_length=100)
    personality_summary: str | None = None
    profile_image_url: str | None = Field(default=None, max_length=255)
    hobby: str | None = None
    role: str | None = None

    @field_validator("mbti")
    @classmethod
    def normalize_mbti(cls, value: str | None):
        if value is None:
            return None
        value = value.strip().upper()
        if value and len(value) != 4:
            raise ValueError("MBTI는 4글자여야 합니다.")
        return value


class PublicProfileResponse(BaseModel):
    id: int
    username: str
    display_name: str | None = None
    mbti: str | None = None
    major: str | None = None
    personality_summary: str | None = None
    profile_image_url: str | None = None
    hobby: str | None = None
    role: str | None = None

    model_config = ConfigDict(from_attributes=True)


class MyProfileResponse(PublicProfileResponse):
    email: EmailStr | None = None


class FileResponse(BaseModel):
    id: int
    room_id: int
    uploaded_by: int
    task_id: Optional[int]
    original_name: str
    stored_name: str
    file_url: str
    mime_type: Optional[str]
    file_size: Optional[int]
    created_at: datetime

    class Config:
        from_attributes = True

class FileDetailResponse(BaseModel):
    id: int
    room_id: int

    task_id: Optional[int]
    task_title: Optional[str]

    uploaded_by: int
    uploaded_by_name: str

    original_name: str
    stored_name: str
    object_key: str

    mime_type: Optional[str]
    file_size: Optional[int]

    created_at: datetime

    class Config:
        from_attributes = True

class FileDownloadResponse(BaseModel):
    file_id: int
    download_url: str
    expires_in: int


class RoomCreateRequest(BaseModel):
    title: str = Field(..., min_length=1, max_length=255, description="룸 제목")
    description: Optional[str] = Field(None, max_length=500, description="룸 설명")
    max_members: int = Field(default=10, ge=1, le=100, description="최대 인원")


class RoomUserAddRequest(BaseModel):
    user_id: int = Field(..., description="추가할 사용자 ID")
    role_in_room: str = Field(default="MEMBER", description="HOST 또는 MEMBER")


class RoomMemberItem(BaseModel):
    user_id: int
    username: str
    display_name: Optional[str] = None
    role_in_room: str
    join_status: str
    joined_at: datetime


class RoomCreateResponse(BaseModel):
    id: int
    host_user_id: int
    title: str
    description: Optional[str] = None
    invite_code: str
    max_members: int
    status: str
    current_stage: str
    created_at: datetime

    class Config:
        from_attributes = True


class RoomDetailResponse(BaseModel):
    id: int
    host_user_id: int
    host_name: str
    title: str
    description: Optional[str] = None
    invite_code: str
    max_members: int
    status: str
    current_stage: str
    created_at: datetime
    members: List[RoomMemberItem]


class RoomListItemResponse(BaseModel):
    id: int
    host_user_id: int
    host_name: str
    title: str
    description: Optional[str] = None
    invite_code: str
    max_members: int
    member_count: int
    status: str
    current_stage: str
    created_at: datetime


class RoomUserAddResponse(BaseModel):
    room_id: int
    user_id: int
    role_in_room: str
    join_status: str
    joined_at: datetime


class ScheduleCreateRequest(BaseModel):
    day: str = Field(..., description="요일. 예: monday")
    start_time: time
    end_time: time
    name: str = Field(..., max_length=255)
    location: Optional[str] = Field(None, max_length=255)
    description: Optional[str] = Field(None, max_length=500)


class ScheduleUpdateRequest(BaseModel):
    day: Optional[str] = None
    start_time: Optional[time] = None
    end_time: Optional[time] = None
    name: Optional[str] = Field(None, max_length=255)
    location: Optional[str] = Field(None, max_length=255)
    description: Optional[str] = Field(None, max_length=500)


class ScheduleResponse(BaseModel):
    id: int
    user_id: int
    day: str
    start_time: time
    end_time: time
    name: str
    location: Optional[str] = None
    description: Optional[str] = None
    created_at: datetime
    updated_at: datetime

class TaskAssignedUser(BaseModel):
    id: int
    username: str
    model_config = ConfigDict(from_attributes=True)


class TaskCreateRequest(BaseModel):
    room_id: int
    assigned_user_id: int
    title: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = Field(None)
    priority: str = Field(default="MEDIUM", description="LOW / MEDIUM / HIGH")
    due_date: Optional[datetime] = None
    created_by: str = Field(default="AI", description="AI / USER")

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "room_id": 1,
                "assigned_user_id": 3,
                "title": "기획안 초안 작성",
                "description": "1차 회의 내용 기반으로 초안 작성",
                "priority": "HIGH",
                "due_date": "2025-07-10T23:59:00",
                "created_by": "AI"
            }
        }
    )


class TaskResponse(BaseModel):
    id: int
    room_id: int
    assigned_user_id: Optional[int]
    title: str
    description: Optional[str]
    status: str
    priority: str
    progress_percent: int
    due_date: Optional[datetime]
    created_by: str
    created_at: datetime
    updated_at: Optional[datetime] = None
    assigned_user: Optional[TaskAssignedUser] = None
    ai_comment: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class TaskListResponse(BaseModel):
    tasks: List[TaskResponse]
    total: int
    overdue_count: int
    ai_alert: Optional[str] = None
    
class JoinRoomByInviteCodeRequest(BaseModel):
    invite_code: str


class JoinRoomByInviteCodeResponse(BaseModel):
    success: bool
    message: str
    room_id: int
    title: str
    current_stage: str

    
# --- AI Feature Schemas ---

class IceBreakingAnswer(BaseModel):
    user_id: int
    question: str
    answer: str

class IceBreakingRequest(BaseModel):
    room_id: int
    answers: List[IceBreakingAnswer]

class IceBreakingResponse(BaseModel):
    success: bool
    message: str
    analysis_report: str

class TopicRecommendRequest(BaseModel):
    room_id: int
    subject: str
    answers: List[IceBreakingAnswer]

class RecommendedTopic(BaseModel):
    topic_name: str
    reason: str
    expected_effect: str

class TopicRecommendResponse(BaseModel):
    success: bool
    topics: List[RecommendedTopic]

class TaskDistributeRequest(BaseModel):
    room_id: int
    final_topic: str
    deadline: Optional[datetime] = None

class GeneratedTask(BaseModel):
    title: str
    description: str
    assigned_user_id: Optional[int]
    reason: str

class TaskDistributeResponse(BaseModel):
    success: bool
    tasks: List[GeneratedTask]

class ChatMessageRequest(BaseModel):
    room_id: int
    message: str

class ChatMessageResponse(BaseModel):
    success: bool
    reply: str