USE semothon;

ALTER TABLE rooms
ADD COLUMN subject VARCHAR(100) COMMENT '과목 이름';