from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models import User, UserProfile
from app.schemas import (
    SignUpRequest,
    SignUpResponse,
    LoginRequest,
    LoginResponse,
    MeResponse,
    ErrorResponse,
)
from app.security import hash_password, verify_password, create_access_token

router = APIRouter(
    prefix="/auth",
    tags=["Auth"]
)


@router.post(
    "/signup",
    response_model=SignUpResponse,
    status_code=status.HTTP_201_CREATED,
    summary="회원가입",
    description=(
        "새 사용자를 등록합니다.\n\n"
        "- username은 중복될 수 없습니다.\n"
        "- email은 중복될 수 없습니다.\n"
        "- password는 해시되어 저장됩니다.\n"
        "- 앱 클라이언트에서 사용하는 회원가입 API입니다."
    ),
    responses={
        201: {"description": "회원가입 성공"},
        400: {
            "model": ErrorResponse,
            "description": "이미 사용 중인 username 또는 email"
        }
    }
)
def signup(
    request: SignUpRequest,
    db: Session = Depends(get_db)
):
    existing_user_by_username = db.query(User).filter(User.username == request.username).first()
    if existing_user_by_username:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="이미 사용 중인 아이디입니다."
        )

    existing_user_by_email = db.query(User).filter(User.email == request.email).first()
    if existing_user_by_email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="이미 사용 중인 이메일입니다."
        )

    # User 생성
    new_user = User(
        username=request.username,
        email=request.email,
        password_hash=hash_password(request.password),
    )

    db.add(new_user)
    db.flush()  # user.id 확보

    # UserProfile 생성
    new_profile = UserProfile(
        user_id=new_user.id,
        display_name=request.username
    )

    db.add(new_profile)

    db.commit()
    db.refresh(new_user)

    return SignUpResponse(
        success=True,
        message="회원가입이 완료되었습니다.",
        user=new_user
    )


@router.post(
    "/login",
    response_model=LoginResponse,
    summary="로그인",
    description=(
        "아이디와 비밀번호로 로그인합니다.\n\n"
        "- 로그인 성공 시 JWT access token을 반환합니다.\n"
        "- 이후 보호된 API 호출 시 Authorization 헤더에 Bearer 토큰으로 사용합니다.\n"
        "- 예: `Authorization: Bearer {access_token}`"
    ),
    responses={
        200: {"description": "로그인 성공"},
        401: {
            "model": ErrorResponse,
            "description": "아이디 또는 비밀번호가 올바르지 않음"
        }
    }
)
def login(
    request: LoginRequest,
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(User.username == request.username).first()

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="아이디 또는 비밀번호가 올바르지 않습니다."
        )

    if not verify_password(request.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="아이디 또는 비밀번호가 올바르지 않습니다."
        )


    access_token = create_access_token(data={"sub": user.username})

    return LoginResponse(
        success=True,
        message="로그인에 성공했습니다.",
        access_token=access_token,
        token_type="bearer",
        user=user
    )


@router.get(
    "/me",
    response_model=MeResponse,
    summary="내 정보 조회",
    description=(
        "현재 로그인한 사용자의 정보를 조회합니다.\n\n"
        "- Bearer 토큰이 필요합니다.\n"
        "- Swagger 우측 상단 Authorize 버튼으로 토큰을 넣고 테스트할 수 있습니다."
    ),
    responses={
        200: {"description": "조회 성공"},
        401: {
            "model": ErrorResponse,
            "description": "인증 실패"
        }
    }
)
def get_me(
    current_user: User = Depends(get_current_user)
):
    return MeResponse(
        success=True,
        message="현재 로그인한 사용자 정보입니다.",
        user=current_user
    )