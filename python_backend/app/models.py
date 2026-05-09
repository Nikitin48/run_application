from __future__ import annotations

from datetime import datetime
from typing import Any, Literal

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
    is_admin: bool = False
    created_at: datetime


class UserStatsOut(BaseModel):
    run_count: int
    total_distance_m: float
    total_elapsed_s: int
    total_paused_s: int
    total_moving_s: int
    successful_captures_count: int
    total_captured_area_m2: float
    total_victims_count: int
    owned_area_m2: float
    profile_xp: int
    profile_level: int


class AchievementUnlockedOut(BaseModel):
    code: str
    title: str
    description: str
    category: str
    icon_key: str
    xp: int
    unlocked_at: datetime


class AchievementItemOut(BaseModel):
    code: str
    title: str
    description: str
    category: str
    icon_key: str
    xp: int
    sort_order: int
    is_unlocked: bool
    unlocked_at: datetime | None = None


class LevelUpOut(BaseModel):
    old_level: int
    new_level: int


class AchievementsResponseOut(BaseModel):
    profile_xp: int
    profile_level: int
    items: list[AchievementItemOut]


class MeProfileOut(BaseModel):
    id: str
    username: str
    display_name: str
    avatar_url: str | None = None
    email: EmailStr | None = None
    territory_color: str
    country_code: str
    country_name: str
    region_code: str | None = None
    region_name: str | None = None
    city_code: str | None = None
    city_name: str | None = None
    is_admin: bool = False
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
    country_code: str | None = Field(default=None, min_length=2, max_length=8)
    region_code: str | None = Field(default=None, min_length=2, max_length=32)
    city_code: str | None = Field(default=None, min_length=2, max_length=32)

    @model_validator(mode="after")
    def validate_any_field_provided(self) -> "UpdateMeProfileRequest":
        if not self.model_fields_set:
            raise ValueError("at least one field must be provided")
        return self

    @model_validator(mode="after")
    def validate_location_hierarchy(self) -> "UpdateMeProfileRequest":
        if self.city_code is not None and self.region_code is None:
            raise ValueError("region_code is required when city_code is set")
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
    started_at: datetime | None = None
    ended_at: datetime | None = None
    distance_m: float
    elapsed_s: int
    paused_s: int
    moving_s: int
    capture_area_m2: float
    victims_count: int
    capture_geojson: dict[str, Any] | None = None
    track_geojson: dict[str, Any] | None = None
    new_achievements: list[AchievementUnlockedOut] = Field(default_factory=list)
    level_up: LevelUpOut | None = None
    profile_xp: int = 0
    profile_level: int = 1


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
    capture_geojson: dict[str, Any] | None = None
    track_geojson: dict[str, Any] | None = None
    created_at: datetime


class PushTokenUpsertRequest(BaseModel):
    platform: str = Field(pattern="^(android|ios)$")
    token: str = Field(min_length=16, max_length=4096)
    app_version: str | None = Field(default=None, max_length=64)
    device_id: str | None = Field(default=None, max_length=255)


class PushTokenDeleteRequest(BaseModel):
    token: str = Field(min_length=16, max_length=4096)


LeaderboardScope = Literal["city", "region", "country"]
LeaderboardMetric = Literal["area", "distance"]


class LeaderboardEntryOut(BaseModel):
    rank: int
    user_id: str
    display_name: str
    avatar_url: str | None = None
    country_code: str
    region_code: str | None = None
    city_code: str | None = None
    total_distance_m: float
    owned_area_m2: float
    score: float


class LeaderboardResponseOut(BaseModel):
    scope: LeaderboardScope
    metric: LeaderboardMetric
    entries: list[LeaderboardEntryOut]
    my_rank: int | None = None
    my_score: float | None = None


class LocationItemOut(BaseModel):
    code: str
    name: str


class CountryItemOut(LocationItemOut):
    pass


class RegionItemOut(LocationItemOut):
    country_code: str


class CityItemOut(LocationItemOut):
    country_code: str
    region_code: str

