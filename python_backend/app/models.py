from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, EmailStr, Field


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
    created_at: datetime


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
    points: list[RunPointIn] = Field(min_length=2)
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


