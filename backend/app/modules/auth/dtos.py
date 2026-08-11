from pydantic import BaseModel, EmailStr, Field, field_validator

from app.modules.users.dtos import PrivateUser


class RegisterRequest(BaseModel):
    name: str = Field(min_length=2, max_length=80)
    age: int = Field(ge=18, le=120)
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    avatar_url: str | None = Field(default=None, max_length=500)
    referral_code: str | None = Field(default=None, max_length=16)

    @field_validator("password")
    @classmethod
    def strong_password(cls, value: str) -> str:
        if not any(char.isalpha() for char in value) or not any(char.isdigit() for char in value):
            raise ValueError("Password must include a letter and number")
        return value


class LoginRequest(BaseModel):
    email: EmailStr
    password: str
    device_name: str = Field(default="mobile", max_length=120)


class RefreshRequest(BaseModel):
    refresh_token: str


class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: PrivateUser


class EmailRequest(BaseModel):
    email: EmailStr


class VerifyRequest(BaseModel):
    token: str = Field(min_length=6, max_length=128)


class ResetPasswordRequest(BaseModel):
    token: str
    password: str = Field(min_length=8, max_length=128)
