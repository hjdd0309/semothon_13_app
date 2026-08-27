# 쿠옹 (Khuong)

> 팀 프로젝트는 매번 같은 지점에서 삐걱거립니다 — 어색한 첫 만남, 감으로 나누는 역할, "그거 누가 하기로 했죠?"로 흩어지는 진행 상황. 쿠옹은 아이스브레이킹부터 주제 선정, 역할·업무 분배, 실시간 협업까지 AI가 각 단계를 코칭해서 팀장 한 명에게 쏠리는 조율 부담을 덜어줍니다.

경희대학교 세모톤(Semothon) 13조가 만든 팀 프로젝트 코칭 앱입니다. Flutter 클라이언트(Android · iOS · Web)와 FastAPI 백엔드로 구성되어 있으며, 팀이 방(Room)을 만들면 아이스브레이킹 → 주제선정 → 역할분배 → 협업진행 4단계를 AI가 순서대로 가이드합니다.

![Flutter](https://img.shields.io/badge/Flutter-3.5%2B-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.5%2B-0175C2?logo=dart&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-009688?logo=fastapi&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.13-3776AB?logo=python&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-4479A1?logo=mysql&logoColor=white)
![SQLAlchemy](https://img.shields.io/badge/SQLAlchemy-2.0-D71F00)
![Cloudflare R2](https://img.shields.io/badge/Storage-Cloudflare%20R2-F38020?logo=cloudflare&logoColor=white)

## 왜 쿠옹인가

세모톤 13조가 팀 프로젝트 경험이 있는 대학생 38명을 대상으로 설문한 결과, 팀플의 문제는 매번 비슷한 지점에서 반복됩니다.

- 약 **79%**가 첫 모임의 어색한 분위기 때문에 협업 시작이 늦어졌다고 답했습니다.
- 약 **68%**는 팀원 간 소통 부족을 가장 큰 문제로 꼽았습니다.
- 약 **40%**는 주제 선정 자체가 어렵다고 답했습니다.
- 약 **74%**는 "AI 팀플 코치가 있으면 써보고 싶다"고 답했습니다.

쿠옹은 이 네 지점을 그대로 앱의 4단계로 옮겼습니다. 팀장 한 명이 "누가 뭐 할지", "무슨 주제로 할지"를 감으로 정하고 조율하는 대신, AI가 매 단계마다 팀원 전체의 답변을 모아 구조를 잡아줍니다.

| 단계 | 화면 | 하는 일 |
| --- | --- | --- |
| 1. 아이스브레이킹 | `icebreaking_stage_screen.dart` | 팀원 전원이 5개의 성향 질문에 답하면, AI가 팀 전체 분위기 요약과 서로를 알아가기 위한 대화 포인트를 생성합니다 (`POST /api/ai/ice-breaking`). |
| 2. 주제 선정 | `topic_selection_stage_screen.dart` | 수강 과목(디자인적 사고 · 세계와 시민 · 데이터분석캡스톤디자인)별로 준비된 질문에 팀원이 답하면, AI가 팀 관심사를 종합해 주제 3개를 이유·기대효과와 함께 추천합니다 (`POST /api/ai/topics`). |
| 3. 역할·업무 분배 | `role_assignment_stage_screen.dart` | 확정된 주제를 바탕으로 AI가 팀원별 역할과 To-do를 자동 배분하고, 각 항목을 실제 `tasks` 레코드로 저장합니다 (`POST /api/ai/distribute`). |
| 4. 협업 진행 | `project_detail_screen.dart` | 역할 분배 이후부터는 진행 상황 트래커, 실시간 채팅, 할 일 관리, 파일 공유로 넘어가 팀플이 끝날 때까지 계속 씁니다. |

이 4단계 진행 상태는 프로젝트 디테일 화면 상단의 "프로젝트 단계" 트래커에서 항상 확인할 수 있고, 각 단계의 결과(팀 성향 요약, 추천 주제, 분배 근거)는 `ai_contexts` 테이블에 버전과 함께 남아 나중에 다시 열어볼 수 있습니다.

## 미리보기

| 홈 | 프로젝트 디테일 | 아이스브레이킹 |
| --- | --- | --- |
| ![홈 화면](docs/screenshots/home.png) | ![프로젝트 디테일](docs/screenshots/project-detail.png) | ![아이스브레이킹](docs/screenshots/icebreaking.png) |

## 핵심 기능

- **4단계 온보딩 트래커** — 아이스브레이킹 · 주제선정 · 역할분배 · 협업진행 단계를 프로젝트 디테일 화면에서 진행률과 함께 관리 (`lib/screens/home/project_detail_screen.dart`)
- **AI 코치** — 팀원 성향 요약, 과목별 주제 추천, 업무 자동 배분을 LLM에 위임하고 결과를 `ai_contexts` 테이블에 버전 관리하며 저장 (`backend/app/routers/ai.py`)
- **초대 코드 기반 팀 룸** — 6자리 코드로 방 생성·참여, 방 단위 멤버/역할 관리 (`backend/app/routers/rooms.py`)
- **실시간 채팅** — 방(Room) 단위 WebSocket 브로드캐스트 (`backend/app/websocket/chat_manager.py`)
- **파일 공유** — Cloudflare R2 업로드 후 presigned URL로 다운로드/미리보기 (`backend/app/services/r2.py`)
- **할 일 관리** — 담당자·우선순위·마감일·반복 여부까지 가진 Todo 모델과 정렬 재배치 API (`backend/app/routers/todos.py`)

## 기술적 의사결정

- **Flutter 단일 코드베이스** — `pubspec.yaml`에 android/ios/web/windows/macos/linux 플랫폼이 모두 구성되어 있고, `vercel.json`이 `flutter build web`을 직접 실행하도록 되어 있어 팀 규모(학생 해커톤)에 맞게 하나의 코드베이스로 웹 배포와 모바일 빌드를 동시에 해결하는 구조를 택했습니다.
- **FastAPI + Pydantic 스키마** — `backend/app/schemas.py`가 800줄 넘게 요청/응답 모델과 `model_validator`(예: `IceBreakingRequest`의 `summary_text` 또는 `context_json` 중 하나 필수 검증)로 채워져 있습니다. AI 라우터가 다루는 입력이 자유 텍스트 + 구조화 JSON을 섞어 받아야 해서, 자동 검증과 `/docs` 스펙 노출이 되는 FastAPI가 이 팀에는 유리했을 것으로 보입니다.
- **JWT + bcrypt(SHA-256 프리해시)** — `backend/app/security.py`에서 비밀번호를 bcrypt에 넣기 전에 SHA-256으로 먼저 압축합니다. bcrypt는 72바이트를 넘는 입력을 자르기 때문에, 긴 비밀번호에서도 잘림 없이 전체 입력이 검증에 반영되도록 한 선택입니다. 인증은 세션 대신 Bearer 토큰(`HTTPBearer` + `python-jose`)으로 처리해 Flutter 클라이언트가 토큰만 들고 다니면 되도록 했습니다.
- **SQLAlchemy + BIGINT(unsigned) PK** — `backend/app/models.py`의 거의 모든 테이블이 `BIGINT(unsigned=True)`를 기본 키로 씁니다. 표준 `Integer` PK보다 큰 범위를 미리 확보해 두는 선택이며, `Todo` 모델에는 `CheckConstraint("progress_percent BETWEEN 0 AND 100")`과 room/creator/assignee/status/due_date 각각에 대한 인덱스가 명시되어 있어, 목록·정렬 조회가 잦을 것으로 예상하고 설계한 흔적입니다.
- **Cloudflare R2 (S3 호환)** — `backend/app/services/r2.py`는 `boto3`의 S3 클라이언트를 `region_name="auto"`와 R2 전용 엔드포인트로 그대로 재사용합니다. S3 SDK 생태계를 그대로 쓰면서 R2의 이그레스 비용 이점을 취하는, 학생 프로젝트에서 흔히 보이는 실용적 선택입니다.
- **OpenAI SDK 호환 게이트웨이로 Claude 호출** — `backend/app/routers/ai.py`는 `openai` 패키지의 `OpenAI` 클라이언트를 쓰지만 `base_url`을 자체 게이트웨이(`factchat-cloud.mindlogic.ai`)로 돌리고 `MODEL_NAME = "claude-sonnet-4-6"`을 지정합니다. 즉 OpenAI SDK의 인터페이스만 재사용하고 실제로는 Claude 계열 모델을 호출하는 프록시 구성입니다.

## 폴더 구조

```
semothon_13_app/
├─ lib/                          # Flutter 클라이언트
│  ├─ main.dart                  # 앱 진입점, AuthService/ProjectService 초기화
│  └─ screens/
│     ├─ home/                   # 홈·프로젝트 디테일·4단계 온보딩 화면
│     │  └─ widgets/             # 홈 화면 전용 서브 위젯 (캘린더, AI 브리핑 카드 등)
│     ├─ login/                  # 로그인 · 회원가입
│     ├─ models/                 # JSON ↔ Dart 모델 (fromJson/toJson)
│     └─ services/                # 백엔드 REST 호출 (auth, project, ai)
├─ backend/
│  ├─ app/
│  │  ├─ routers/                # 기능별 API 라우터 (auth, rooms, ai, chat, todos …)
│  │  ├─ services/               # r2.py(파일 스토리지), todo_service.py
│  │  ├─ websocket/               # 방 단위 채팅 브로드캐스트
│  │  ├─ models.py               # SQLAlchemy ORM 테이블 정의
│  │  ├─ schemas.py               # Pydantic 요청/응답 스키마
│  │  ├─ security.py / dependencies.py  # JWT 발급·검증
│  │  └─ main.py                 # FastAPI 앱, 라우터 등록
│  └─ SQL/                       # 적용된 DDL 변경 이력
├─ assets/images/                # 마스코트·아이콘 이미지
├─ android/ ios/ web/ windows/ macos/ linux/   # Flutter 플랫폼별 빌드 설정
└─ vercel.json                   # Vercel에서 flutter build web을 실행하는 배포 설정
```

## Quick Start

### 프론트엔드 (Flutter)

```bash
flutter pub get
flutter run -d chrome        # 웹으로 실행, 또는 -d <연결된 디바이스 ID>
```

기본 상태에서는 `lib/main.dart`에 하드코딩된 배포 서버(Railway)를 바라봅니다. 로컬 백엔드를 붙이려면 `lib/main.dart`와 `lib/screens/services/*.dart`의 `baseUrl`을 `http://localhost:8000`으로 바꿔주세요.

### 백엔드 (FastAPI)

```bash
cd backend
python -m venv venv
venv\Scripts\activate         # macOS/Linux: source venv/bin/activate

pip install -r requirements.txt
cp .env.example .env          # 아래 표를 참고해 값 채우기
fastapi dev app/main.py       # http://localhost:8000
```

`.env`에 채워야 하는 값 (`backend/app/config.py` 기준):

| 변수 | 설명 | 기본값 |
| --- | --- | --- |
| `DB_USER` | MySQL 사용자명 | `root` |
| `DB_PASSWORD` | MySQL 비밀번호 | `1234` |
| `DB_HOST` | MySQL 호스트 | `127.0.0.1` |
| `DB_PORT` | MySQL 포트 | `3306` |
| `DB_NAME` | 데이터베이스 이름 | `testdb` |
| `SECRET_KEY` | JWT 서명 키 | *(필수)* |
| `R2_ACCOUNT_ID` / `R2_ACCESS_KEY_ID` / `R2_SECRET_ACCESS_KEY` / `R2_BUCKET_NAME` / `R2_PUBLIC_BASE_URL` | Cloudflare R2 자격 증명 (파일 업로드용) | *(필수)* |

MySQL 연결 확인: `http://localhost:8000/db-check`
API 문서(Swagger): `http://localhost:8000/docs`
