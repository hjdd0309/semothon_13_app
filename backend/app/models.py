from sqlalchemy import Column, String, DateTime, func, ForeignKey, Text, Enum, Integer, Time, JSON, Boolean, BigInteger,text, CheckConstraint, Index
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.mysql import BIGINT
from app.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(BIGINT(unsigned=True), primary_key=True, autoincrement=True, index=True)
    username = Column(String(50), unique=True, nullable=False, index=True)
    email = Column(String(100), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    status = Column(
        Enum("ACTIVE", "INACTIVE", "BANNED", name="user_status"),
        nullable=False,
        server_default="ACTIVE",
    )
    created_at = Column(DateTime, nullable=False, server_default=func.now())
    updated_at = Column(DateTime, nullable=False, server_default=func.now(), onupdate=func.now())

    profile = relationship("UserProfile", back_populates="user", uselist=False, cascade="all, delete-orphan")
    tasks = relationship("Task", back_populates="assigned_user")


class UserProfile(Base):
    __tablename__ = "user_profiles"

    id = Column(BIGINT(unsigned=True), primary_key=True, autoincrement=True, index=True)
    user_id = Column(BIGINT(unsigned=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, unique=True)
    display_name = Column(String(50), nullable=False)
    mbti = Column(String(10), nullable=True)
    major = Column(String(100), nullable=True)
    bio = Column(Text, nullable=True)
    personality_summary = Column(Text, nullable=True)
    profile_image_url = Column(String(255), nullable=True)
    created_at = Column(DateTime, nullable=False, server_default=func.now())
    updated_at = Column(DateTime, nullable=False, server_default=func.now(), onupdate=func.now())
    hobby = Column(String(255), nullable=True)
    role = Column(String(255), nullable=True)
    distributed = Column(String(255), nullable=True)
    user = relationship("User", back_populates="profile")


class Room(Base):
    __tablename__ = "rooms"

    id = Column(BIGINT(unsigned=True), primary_key=True, index=True, autoincrement=True)
    host_user_id = Column(BIGINT(unsigned=True), ForeignKey("users.id"), nullable=False)
    title = Column(String(255), nullable=False)
    topic = Column(String(255), nullable=True)
    description = Column(String(500), nullable=True)
    invite_code = Column(String(20), unique=True, nullable=False)
    max_members = Column(Integer, default=10)
    status = Column(String(50), default="active")
    current_stage = Column(String(50), default="waiting")
    created_at = Column(DateTime, server_default=func.now())

    tasks = relationship("Task", back_populates="room")


class RoomMember(Base):
    __tablename__ = "room_members"

    id = Column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    room_id = Column(BIGINT(unsigned=True), ForeignKey("rooms.id", ondelete="CASCADE"), nullable=False)
    user_id = Column(BIGINT(unsigned=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    role_in_room = Column(String(20), default="member")
    join_status = Column(String(20), default="joined")
    joined_at = Column(DateTime, server_default=func.now())


class Task(Base):
    __tablename__ = "tasks"

    id = Column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    room_id = Column(BIGINT(unsigned=True), ForeignKey("rooms.id", ondelete="CASCADE"), nullable=False)
    assigned_user_id = Column(BIGINT(unsigned=True), ForeignKey("users.id"), nullable=True)
    title = Column(String(255), nullable=False)
    description = Column(String(500), nullable=True)
    
    status = Column(
        Enum("TODO", "IN_PROGRESS", "DONE", "BLOCKED", name="task_status"),
        nullable=False,
        server_default="TODO"
    )
    progress_percent = Column(Integer, nullable=False, default=0)
    priority = Column(
        Enum("LOW", "MEDIUM", "HIGH", name="task_priority"),
        nullable=False,
        server_default="MEDIUM"
    )
    due_date = Column(DateTime, nullable=True)
    created_by = Column(
        Enum("USER", "AI", name="task_created_by"),
        nullable=False,
        server_default="AI"
    )
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())

    room = relationship("Room", back_populates="tasks")
    assigned_user = relationship("User", back_populates="tasks")
    files = relationship("File", back_populates="task")


class File(Base):
    __tablename__ = "files"

    id = Column(BIGINT(unsigned=True), primary_key=True, index=True, autoincrement=True)
    room_id = Column(BIGINT(unsigned=True), ForeignKey("rooms.id", ondelete="CASCADE"), nullable=False)
    # 수정 완료: uploaded_by와 task_id를 BIGINT(unsigned=True)로 변경
    uploaded_by = Column(BIGINT(unsigned=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    task_id = Column(BIGINT(unsigned=True), ForeignKey("tasks.id", ondelete="SET NULL"), nullable=True)

    original_name = Column(String(255), nullable=False)
    stored_name = Column(String(255), nullable=False)
    object_key = Column(String(500), nullable=False)
    file_url = Column(String(500), nullable=False)
    mime_type = Column(String(100), nullable=True)
    file_size = Column(BIGINT(unsigned=True), nullable=True) # 파일 사이즈도 큰 값을 대비해 BIGINT 유지
    created_at = Column(DateTime, nullable=False, server_default=func.now())

    task = relationship("Task", back_populates="files")


class UserSchedule(Base):
    __tablename__ = "user_schedules"

    id = Column(BIGINT(unsigned=True), primary_key=True, autoincrement=True, index=True)
    user_id = Column(BIGINT(unsigned=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    day = Column(String(20), nullable=False)
    start_time = Column(Time, nullable=False)
    end_time = Column(Time, nullable=False)
    name = Column(String(255), nullable=False)
    location = Column(String(255), nullable=True)
    description = Column(String(500), nullable=True)
    created_at = Column(DateTime, nullable=False, server_default=func.now())
    updated_at = Column(DateTime, nullable=False, server_default=func.now(), onupdate=func.now())

# class ChatMessage(Base):
#     __tablename__ = "chat_messages"

    id = Column(BIGINT(unsigned=True), primary_key=True, autoincrement=True, index=True)
    room_id = Column(BIGINT(unsigned=True), ForeignKey("rooms.id", ondelete="CASCADE"), nullable=False)
    user_id = Column(BIGINT(unsigned=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=True) 
    sender_type = Column(Enum("USER", "AI", "SYSTEM", name="message_sender_type"), nullable=False, server_default="USER")
    message = Column(Text, nullable=False)
    created_at = Column(DateTime, nullable=False, server_default=func.now())

#     room = relationship("Room", backref="chat_messages")
#     user = relationship("User", backref="chat_messages")


class AIContext(Base):
    __tablename__ = "ai_contexts"

    id = Column(BIGINT(unsigned=True), primary_key=True, index=True)
    room_id = Column(BIGINT(unsigned=True), ForeignKey("rooms.id"), nullable=False)
    context_type = Column(String(50), nullable=False, default="team_project")
    title = Column(String(255), nullable=False)
    context_json = Column(JSON, nullable=True)
    summary_text = Column(Text, nullable=False)
    question = Column(Text, nullable=True)
    answer = Column(Text, nullable=True)
    version = Column(Integer, nullable=False, default=1)
    is_active = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime, nullable=False, server_default=func.now())
    updated_at = Column(DateTime, nullable=False, server_default=func.now(), onupdate=func.now())


class ChatMessage(Base):
    __tablename__ = "chat_messages"

    id = Column(BIGINT(unsigned=True), primary_key=True, index=True)
    room_id = Column(BIGINT(unsigned=True), ForeignKey("rooms.id", ondelete="CASCADE"), nullable=False)
    sender_user_id = Column(BIGINT(unsigned=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    message_type = Column(
        Enum("TEXT", "IMAGE", "FILE", "SYSTEM", "AI", name="chat_message_type_enum"),
        nullable=False,
        default="TEXT"
    )
    content = Column(Text, nullable=True)
    image_url = Column(String(500), nullable=True)
    related_file_id = Column(BigInteger, ForeignKey("files.id", ondelete="SET NULL"), nullable=True)
    created_at = Column(DateTime,nullable=False,server_default=text("CURRENT_TIMESTAMP"))

    sender = relationship("User", foreign_keys=[sender_user_id])

    from sqlalchemy import (
    Column,
    BigInteger,
    ForeignKey,
    String,
    Text,
    Enum,
    DateTime,
    text,
)
from sqlalchemy.orm import relationship

class Todo(Base):
    __tablename__ = "todos"

    id = Column(BIGINT(unsigned=True).with_variant(BigInteger, "mysql"), primary_key=True, autoincrement=True, comment="할 일 PK")

    room_id = Column(BIGINT(unsigned=True), 
        ForeignKey("rooms.id", ondelete="CASCADE"), 
        nullable=False, 
        comment="소속 room ID"
    )
    creator_user_id = Column(
        BIGINT(unsigned=True), 
        ForeignKey("users.id", ondelete="CASCADE"), 
        nullable=False, 
        comment="할 일 생성자"
    )
    assignee_user_id = Column(
        BIGINT(unsigned=True), 
        ForeignKey("users.id", ondelete="SET NULL"), 
        nullable=True, 
        comment="담당자"
    )
    title = Column(String(200), nullable=False, comment="할 일 제목")
    description = Column(Text, nullable=True, comment="할 일 상세 설명")

    status = Column(
        Enum("TODO", "IN_PROGRESS", "BLOCKED", "REVIEW", "DONE", "CANCELLED", name="todo_status_enum"),
        nullable=False,
        server_default="TODO",
        comment="진행 상태",
    )

    success_flag = Column(Boolean, nullable=True, comment="최종 성공 여부")
    progress_percent = Column(nullable=True, type_=__import__("sqlalchemy").Integer, comment="진행률 0~100")

    priority = Column(
        Enum("LOW", "MEDIUM", "HIGH", "URGENT", name="todo_priority_enum"),
        nullable=False,
        server_default="MEDIUM",
        comment="우선순위",
    )

    category = Column(String(50), nullable=True, comment="카테고리")
    tag = Column(String(100), nullable=True, comment="태그")

    start_date = Column(DateTime, nullable=True, comment="작업 시작일")
    due_date = Column(DateTime, nullable=True, comment="마감일")
    completed_at = Column(DateTime, nullable=True, comment="완료 시각")

    estimated_minutes = Column(__import__("sqlalchemy").Integer, nullable=True, comment="예상 소요 시간")
    actual_minutes = Column(__import__("sqlalchemy").Integer, nullable=True, comment="실제 소요 시간")

    is_recurring = Column(Boolean, nullable=True, comment="반복 작업 여부")
    recurrence_rule = Column(String(255), nullable=True, comment="반복 규칙")

    visibility = Column(
        Enum("PRIVATE", "ROOM", "PUBLIC", name="todo_visibility_enum"),
        nullable=False,
        server_default="ROOM",
        comment="공개 범위",
    )

    source_type = Column(
        Enum("MANUAL", "AI", "SYSTEM", name="todo_source_type_enum"),
        nullable=False,
        server_default="MANUAL",
        comment="생성 출처",
    )

    ai_suggested = Column(Boolean, nullable=True, comment="AI 추천 생성 여부")

    sort_order = Column(__import__("sqlalchemy").Integer, nullable=True, comment="정렬 순서")
    archived = Column(Boolean, nullable=True, comment="보관 여부")
    deleted = Column(Boolean, nullable=True, comment="소프트 삭제 여부")

    created_at = Column(DateTime, nullable=False, server_default=func.now(), comment="생성 시각")
    updated_at = Column(DateTime, nullable=False, server_default=func.now(), onupdate=func.now(), comment="수정 시각")

    __table_args__ = (
        CheckConstraint("progress_percent BETWEEN 0 AND 100", name="ck_todos_progress_percent"),
        Index("idx_todos_room", "room_id"),
        Index("idx_todos_creator", "creator_user_id"),
        Index("idx_todos_assignee", "assignee_user_id"),
        Index("idx_todos_status", "status"),
        Index("idx_todos_due_date", "due_date"),
        Index("idx_todos_room_sort_order", "room_id", "sort_order"),
    )
