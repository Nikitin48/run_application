from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, EmailStr, Field, model_validator


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=200)
    display_name: str | None = Field(default=None, max_length=80)

    model_config = {
        "json_schema_extra": {
            "examples": [
                {"email": "me@example.com", "password": "password123", "display_name": "Me"},
            ]
        }
    }


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=200)

    model_config = {
        "json_schema_extra": {
            "examples": [
                {"email": "me@example.com", "password": "password123"},
            ]
        }
    }


class AuthResponse(BaseModel):
    access_token: str
    access_expires_at: int
    refresh_token: str


class RefreshRequest(BaseModel):
    refresh_token: str


class UserOut(BaseModel):
    id: str
    username: str
    display_name: str
    avatar_url: str | None = None
    territory_color: str
    created_at: datetime


class UserStatsOut(BaseModel):
    run_count: int
    total_distance_m: float
    total_elapsed_s: int
    total_paused_s: int
    total_moving_s: int
    owned_area_m2: float


class MeProfileOut(BaseModel):
    id: str
    username: str
    display_name: str
    avatar_url: str | None = None
    email: EmailStr | None = None
    territory_color: str
    created_at: datetime
    stats: UserStatsOut


class AvatarOut(BaseModel):
    avatar_url: str | None = None


class UpdateTerritoryColorRequest(BaseModel):
    territory_color: str = Field(
        min_length=7,
        max_length=7,
        pattern="^#[0-9A-Fa-f]{6}$",
    )


class TerritoryColorOut(BaseModel):
    territory_color: str


class UpdateMeProfileRequest(BaseModel):
    display_name: str | None = Field(default=None, min_length=1, max_length=80)
    avatar_url: str | None = Field(default=None, max_length=500)

    @model_validator(mode="after")
    def validate_any_field_provided(self) -> "UpdateMeProfileRequest":
        if self.display_name is None and self.avatar_url is None:
            raise ValueError("at least one field must be provided")
        return self


class ChangePasswordRequest(BaseModel):
    current_password: str = Field(min_length=1, max_length=200)
    new_password: str = Field(min_length=8, max_length=200)

    @model_validator(mode="after")
    def validate_passwords_are_different(self) -> "ChangePasswordRequest":
        if self.current_password == self.new_password:
            raise ValueError("new_password must differ from current_password")
        return self


class RunPointIn(BaseModel):
    lat: float
    lng: float
    ts: datetime
    accuracy_m: float | None = None
    speed_mps: float | None = None
    altitude_m: float | None = None


class RunPauseIn(BaseModel):
    started_at: datetime
    ended_at: datetime | None = None
    reason: str = Field(pattern="^(manual|gps_lost|internet_lost)$")


class RunFinishRequest(BaseModel):
    started_at: datetime
    ended_at: datetime
    points: list[RunPointIn] = Field(default_factory=list)
    pauses: list[RunPauseIn] = Field(default_factory=list)

    model_config = {
        "json_schema_extra": {
            "examples": [
                {
                    "started_at": "2025-12-15T10:00:00Z",
                    "ended_at": "2025-12-15T10:10:00Z",
                    "points": [
                        {"lat": 55.75396, "lng": 37.620393, "ts": "2025-12-15T10:00:00Z"},
                        {"lat": 55.7542, "lng": 37.6225, "ts": "2025-12-15T10:02:00Z"},
                        {"lat": 55.7535, "lng": 37.622, "ts": "2025-12-15T10:04:00Z"},
                        {"lat": 55.75396, "lng": 37.620393, "ts": "2025-12-15T10:06:00Z"},
                    ],
                    "pauses": [],
                }
            ]
        }
    }


class RunFinishResponse(BaseModel):
    run_id: str
    distance_m: float
    elapsed_s: int
    paused_s: int
    moving_s: int
    capture_area_m2: float
    victims_count: int


class RunHistoryItemOut(BaseModel):
    run_id: str
    status: str
    started_at: datetime | None = None
    ended_at: datetime | None = None
    distance_m: float
    elapsed_s: int
    paused_s: int
    moving_s: int
    capture_area_m2: float
    victims_count: int
    created_at: datetime


class PushTokenUpsertRequest(BaseModel):
    platform: str = Field(pattern="^(android|ios)$")
    token: str = Field(min_length=16, max_length=4096)
    app_version: str | None = Field(default=None, max_length=64)
    device_id: str | None = Field(default=None, max_length=255)


class PushTokenDeleteRequest(BaseModel):
    token: str = Field(min_length=16, max_length=4096)

