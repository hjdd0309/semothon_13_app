from datetime import datetime, time
from typing import Optional, List, Any,Dict,Literal

from pydantic import BaseModel, EmailStr, Field, ConfigDict, field_validator, model_validator


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




class IceBreakingRequest(BaseModel):
    room_id: int = Field(..., description="분석 대상 팀의 room id")
    title: str = Field(..., description="이 분석 요청의 제목")
    question: str = Field(
        default="다음 팀원 정보를 바탕으로 팀 전체 성향, 각 팀원의 특징, 팀원 간 시너지, 어색함을 줄일 수 있는 아이스브레이킹 포인트를 분석해줘.",
        description="AI에게 전달할 질문"
    )
    summary_text: Optional[str] = Field(
        default=None,
        description="AI에게 직접 전달할 텍스트 요약"
    )
    context_json: Optional[dict[str, Any]] = Field(
        default=None,
        description="팀원 정보 및 팀 상황을 구조화된 JSON으로 전달"
    )

    @model_validator(mode="after")
    def validate_input(self):
        if not self.summary_text and not self.context_json:
            raise ValueError("summary_text 또는 context_json 중 하나는 반드시 제공해야 합니다.")
        return self

class IceBreakingResponse(BaseModel):
    success: bool
    message: str
    analysis_report: Dict[str, Any]
    ai_context_id: int

class ChatMessageRequest(BaseModel):
    room_id: int = Field(..., description="질문 대상 room id")
    message: str = Field(..., description="사용자 질문")


class ChatMessageResponse(BaseModel):
    success: bool
    reply: str
    ai_context_id: int


class ChatMessageCreateRequest(BaseModel):
    message_type: Literal["TEXT", "IMAGE", "FILE", "SYSTEM", "AI"] = Field(
        default="TEXT",
        description="메시지 타입"
    )
    content: Optional[str] = Field(default=None, description="텍스트 메시지 내용")
    image_url: Optional[str] = Field(default=None, description="이미지 URL")
    related_file_id: Optional[int] = Field(default=None, description="첨부 파일 ID")


class ChatMessageItem(BaseModel):
    id: int
    room_id: int
    sender_user_id: Optional[int]
    sender_name: str
    message_type: str
    content: Optional[str]
    image_url: Optional[str]
    related_file_id: Optional[int]
    created_at: datetime

    class Config:
        from_attributes = True


class ChatMessageListResponse(BaseModel):
    success: bool
    messages: list[ChatMessageItem]


class ChatMessageCreateResponse(BaseModel):
    success: bool
    message: str
    chat_message: ChatMessageItem