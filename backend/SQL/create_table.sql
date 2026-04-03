CREATE DATABASE semothon;
USE semothon;

CREATE TABLE users (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(100) NULL UNIQUE,
    status ENUM('ACTIVE', 'INACTIVE', 'BANNED') NOT NULL DEFAULT 'ACTIVE',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE user_profiles (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL UNIQUE,
    display_name VARCHAR(50) NOT NULL,
    distributed VARCHAR(255) NULL,
    mbti VARCHAR(10) NULL,
    major VARCHAR(100) NULL,
    bio TEXT NULL,
    personality_summary TEXT NULL,
    profile_image_url VARCHAR(255) NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_user_profiles_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE
);

CREATE TABLE rooms (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    host_user_id BIGINT UNSIGNED NOT NULL,
    title VARCHAR(100) NOT NULL,
    description TEXT NULL,
    invite_code VARCHAR(20) NOT NULL UNIQUE,
    max_members INT NOT NULL DEFAULT 10,
    status ENUM('WAITING', 'ICEBREAKING', 'TOPIC_SELECTION', 'ROLE_ASSIGNMENT', 'IN_PROGRESS', 'COMPLETED') NOT NULL DEFAULT 'WAITING',
    current_stage ENUM('WAITING', 'ICEBREAKING', 'TOPIC', 'VOTING', 'ROLE', 'TASK', 'CHAT', 'DONE') NOT NULL DEFAULT 'WAITING',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_rooms_host_user
        FOREIGN KEY (host_user_id) REFERENCES users(id)
        ON DELETE RESTRICT
);

CREATE TABLE room_members (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    room_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    role_in_room ENUM('HOST', 'MEMBER') NOT NULL DEFAULT 'MEMBER',
    join_status ENUM('JOINED', 'LEFT', 'KICKED') NOT NULL DEFAULT 'JOINED',
    joined_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_room_member (room_id, user_id),
    CONSTRAINT fk_room_members_room
        FOREIGN KEY (room_id) REFERENCES rooms(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_room_members_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE
);

CREATE TABLE tasks (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    room_id BIGINT UNSIGNED NOT NULL,
    assigned_user_id BIGINT UNSIGNED NOT NULL,
    role_id BIGINT UNSIGNED NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT NULL,
    status ENUM('TODO', 'IN_PROGRESS', 'DONE', 'BLOCKED') NOT NULL DEFAULT 'TODO',
    progress_percent TINYINT NOT NULL DEFAULT 0,
    priority ENUM('LOW', 'MEDIUM', 'HIGH') NOT NULL DEFAULT 'MEDIUM',
    due_date DATETIME NULL,
    created_by ENUM('USER', 'AI') NOT NULL DEFAULT 'AI',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_progress_percent CHECK (progress_percent BETWEEN 0 AND 100),
    CONSTRAINT fk_tasks_room
        FOREIGN KEY (room_id) REFERENCES rooms(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_tasks_assigned_user
        FOREIGN KEY (assigned_user_id) REFERENCES users(id)
        ON DELETE CASCADE
);
CREATE TABLE files (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    room_id BIGINT UNSIGNED NOT NULL,
    uploaded_by BIGINT UNSIGNED NOT NULL,
    task_id BIGINT UNSIGNED NULL,
    original_name VARCHAR(255) NOT NULL,
    stored_name VARCHAR(255) NOT NULL,
    file_url VARCHAR(500) NOT NULL,
    mime_type VARCHAR(100) NULL,
    file_size BIGINT UNSIGNED NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_files_room
        FOREIGN KEY (room_id) REFERENCES rooms(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_files_uploaded_by
        FOREIGN KEY (uploaded_by) REFERENCES users(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_files_task
        FOREIGN KEY (task_id) REFERENCES tasks(id)
        ON DELETE SET NULL
);


CREATE TABLE chat_messages (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    room_id BIGINT UNSIGNED NOT NULL,
    sender_user_id BIGINT UNSIGNED NULL,
    message_type ENUM('TEXT', 'IMAGE', 'FILE', 'SYSTEM', 'AI') NOT NULL DEFAULT 'TEXT',
    content TEXT NULL,
    image_url VARCHAR(500) NULL,
    related_file_id BIGINT UNSIGNED NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_chat_messages_room
        FOREIGN KEY (room_id) REFERENCES rooms(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_chat_messages_sender
        FOREIGN KEY (sender_user_id) REFERENCES users(id)
        ON DELETE SET NULL,
    CONSTRAINT fk_chat_messages_file
        FOREIGN KEY (related_file_id) REFERENCES files(id)
        ON DELETE SET NULL
);

CREATE TABLE notifications (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    room_id BIGINT UNSIGNED NULL,
    type ENUM('REMINDER', 'PUSH', 'SYSTEM', 'AI_COACHING') NOT NULL,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
	image_url VARCHAR(500) NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    scheduled_at DATETIME NULL,
    sent_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notifications_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_notifications_room
        FOREIGN KEY (room_id) REFERENCES rooms(id)
        ON DELETE CASCADE
);