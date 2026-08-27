# 쿠옹 (Khuong)

> 팀플은 매번 같은 데서 삐걱거립니다. 첫 모임은 어색하고, 역할은 감으로 나누고, 나중엔 누가 뭘 하기로 했는지도 다들 까먹습니다. 쿠옹은 아이스브레이킹부터 주제 선정, 역할 분배, 협업까지 AI가 옆에서 코치처럼 붙어서 팀장 한 명이 다 떠안던 조율 부담을 나눕니다.

경희대학교 세모톤(Semothon) 13조가 만든 팀 프로젝트 코칭 앱입니다. Flutter 클라이언트(Android · iOS · Web)와 FastAPI 백엔드로 구성되어 있으며, 팀이 방(Room)을 만들면 아이스브레이킹 → 주제선정 → 역할분배 → 협업진행 4단계를 AI가 순서대로 가이드합니다.

![Flutter](https://img.shields.io/badge/Flutter-3.5%2B-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.5%2B-0175C2?logo=dart&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-009688?logo=fastapi&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.13-3776AB?logo=python&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-4479A1?logo=mysql&logoColor=white)
![SQLAlchemy](https://img.shields.io/badge/SQLAlchemy-2.0-D71F00)
![Cloudflare R2](https://img.shields.io/badge/Storage-Cloudflare%20R2-F38020?logo=cloudflare&logoColor=white)

## 왜 쿠옹인가

세모톤 13조가 팀플 경험이 있는 대학생 38명에게 설문했더니, 79%는 첫 모임이 어색해서 협업이 늦게 시작됐다고 답했고 68%는 팀원 간 소통 부족을 가장 큰 문제로 꼽았습니다. 주제를 못 정해서 막힌다는 응답도 40%나 됐고요. 대신 "AI 팀플 코치가 있으면 써보고 싶다"는 응답은 74%였습니다.

쿠옹은 이 문제들을 그대로 4단계로 옮겼습니다. 팀장 혼자 "누가 뭐 할지", "무슨 주제로 할지"를 감으로 정하고 조율하는 대신, 단계마다 팀원 전체의 답변을 AI가 모아서 구조를 잡아줍니다.

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

- **4단계 온보딩 트래커**: 아이스브레이킹 · 주제선정 · 역할분배 · 협업진행을 프로젝트 디테일 화면에서 진행률과 함께 보여줍니다.
- **AI 코치**: 팀원 성향 요약, 주제 추천, 업무 자동 배분을 LLM에 맡기고 결과는 `ai_contexts` 테이블에 버전을 매겨 저장합니다.
- 초대 코드 6자리만 있으면 팀 룸을 만들거나 들어갈 수 있습니다.
- 채팅은 방(Room) 단위 WebSocket으로 실시간으로 오갑니다.
- 파일은 Cloudflare R2에 올라가고, presigned URL로 내려받거나 미리 봅니다.
- 할 일(Todo)에는 담당자·우선순위·마감일·반복 여부까지 붙습니다.

## 기술적 의사결정

- **Flutter 단일 코드베이스** — `pubspec.yaml`에 android/ios/web/windows/macos/linux가 전부 들어 있고, `vercel.json`은 배포할 때 그냥 `flutter build web`을 돌립니다. 학생 팀 규모에서 웹/모바일을 따로 만들 여유는 없었을 겁니다.
- **FastAPI + Pydantic** — `schemas.py`가 800줄 넘게 요청/응답 모델과 `model_validator`로 채워져 있습니다. `IceBreakingRequest`는 `summary_text`나 `context_json` 둘 중 하나가 없으면 그 자리에서 검증 에러를 던지죠. AI 라우터가 자유 텍스트와 구조화 JSON을 섞어 받다 보니, 자동 검증과 `/docs` 스펙이 딸려오는 FastAPI 쪽이 편했을 겁니다.
- **JWT + bcrypt(SHA-256 프리해시)** — `security.py`는 비밀번호를 bcrypt에 넣기 전에 SHA-256으로 한 번 압축합니다. bcrypt가 72바이트 넘는 입력을 그냥 잘라버리는 걸 피하려는 흔한 트릭입니다. 인증은 세션 대신 Bearer 토큰(`HTTPBearer` + `python-jose`) 하나로 처리해서, Flutter 쪽은 토큰만 들고 다니면 됩니다.
- **SQLAlchemy, PK는 전부 BIGINT(unsigned)** — `models.py`의 테이블 대부분이 그렇습니다. `Todo`에는 `CheckConstraint("progress_percent BETWEEN 0 AND 100")`과 room/creator/assignee/status/due_date별 인덱스까지 붙어 있어서, 목록·정렬 조회를 꽤 신경 써서 설계했다는 게 보입니다.
- **Cloudflare R2** — `r2.py`는 `boto3`의 S3 클라이언트를 엔드포인트만 R2로 바꿔서 그대로 씁니다. S3 SDK를 재사용하면서 R2의 이그레스 무료 혜택만 챙기는, 흔히 보이는 조합입니다.
- **OpenAI SDK로 Claude 호출** — `ai.py`는 `openai` 패키지를 쓰지만 `base_url`을 자체 게이트웨이(`factchat-cloud.mindlogic.ai`)로 돌리고 `MODEL_NAME = "claude-sonnet-4-6"`을 지정합니다. SDK 인터페이스만 빌려 쓰고 실제로는 Claude를 부르는 프록시인 셈입니다.

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
