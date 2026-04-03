from sqlalchemy import Column, String, DateTime, func, ForeignKey, Text, Enum, Integer, Time, JSON, Boolean, BigInteger,text
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
    user = relationship("User", back_populates="profile")


class Room(Base):
    __tablename__ = "rooms"

    id = Column(BIGINT(unsigned=True), primary_key=True, index=True, autoincrement=True)
    host_user_id = Column(BIGINT(unsigned=True), ForeignKey("users.id"), nullable=False)
    title = Column(String(255), nullable=False)
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