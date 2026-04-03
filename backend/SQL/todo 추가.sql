USE semothon;

CREATE TABLE todos (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT '할 일 PK',

    room_id BIGINT UNSIGNED NOT NULL COMMENT '소속 room ID',
    creator_user_id BIGINT UNSIGNED NOT NULL COMMENT '할 일 생성자',

    assignee_user_id BIGINT UNSIGNED COMMENT '담당자',

    title VARCHAR(200) NOT NULL COMMENT '할 일 제목',
    description TEXT COMMENT '할 일 상세 설명',

    status ENUM(
        'TODO',
        'IN_PROGRESS',
        'BLOCKED',
        'REVIEW',
        'DONE',
        'CANCELLED'
    ) DEFAULT 'TODO' COMMENT '진행 상태',

    success_flag BOOLEAN COMMENT '최종 성공 여부',

    progress_percent TINYINT UNSIGNED COMMENT '진행률 0~100',

    priority ENUM(
        'LOW',
        'MEDIUM',
        'HIGH',
        'URGENT'
    ) DEFAULT 'MEDIUM' COMMENT '우선순위',

    category VARCHAR(50) COMMENT '카테고리',
    tag VARCHAR(100) COMMENT '태그',

    start_date DATETIME COMMENT '작업 시작일',
    due_date DATETIME COMMENT '마감일',
    completed_at DATETIME COMMENT '완료 시각',

    estimated_minutes INT UNSIGNED COMMENT '예상 소요 시간',
    actual_minutes INT UNSIGNED COMMENT '실제 소요 시간',

    is_recurring BOOLEAN COMMENT '반복 작업 여부',
    recurrence_rule VARCHAR(255) COMMENT '반복 규칙',

    visibility ENUM(
        'PRIVATE',
        'ROOM',
        'PUBLIC'
    ) DEFAULT 'ROOM' COMMENT '공개 범위',

    source_type ENUM(
        'MANUAL',
        'AI',
        'SYSTEM'
    ) DEFAULT 'MANUAL' COMMENT '생성 출처',

    ai_suggested BOOLEAN COMMENT 'AI 추천 생성 여부',

    sort_order INT COMMENT '정렬 순서',
    archived BOOLEAN COMMENT '보관 여부',
    deleted BOOLEAN COMMENT '소프트 삭제 여부',

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '생성 시각',
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP COMMENT '수정 시각',

    FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE CASCADE,
    FOREIGN KEY (creator_user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (assignee_user_id) REFERENCES users(id) ON DELETE SET NULL,

    CHECK (progress_percent BETWEEN 0 AND 100),

    INDEX idx_todos_room (room_id),
    INDEX idx_todos_creator (creator_user_id),
    INDEX idx_todos_assignee (assignee_user_id),
    INDEX idx_todos_status (status),
    INDEX idx_todos_due_date (due_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE todos ADD COLUMN sort_order INT;