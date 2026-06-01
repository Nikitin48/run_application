from __future__ import annotations

import unittest
from uuid import uuid4

from fastapi.testclient import TestClient

from app.db import db_conn
from app.main import app


class AdminUsersIntegrationTest(unittest.TestCase):
    def setUp(self) -> None:
        self.client = TestClient(app)
        self.admin_email = f"admin-{uuid4().hex[:10]}@example.com"
        self.target_email = f"target-{uuid4().hex[:10]}@example.com"
        self.password = "Password123!"

        admin_resp = self.client.post(
            "/auth/register",
            json={
                "email": self.admin_email,
                "password": self.password,
                "display_name": "Admin Tester",
            },
        )
        self.assertEqual(admin_resp.status_code, 200, admin_resp.text)
        self.admin_token = admin_resp.json()["access_token"]
        self.admin_headers = {"Authorization": f"Bearer {self.admin_token}"}

        target_resp = self.client.post(
            "/auth/register",
            json={
                "email": self.target_email,
                "password": self.password,
                "display_name": "Target Tester",
            },
        )
        self.assertEqual(target_resp.status_code, 200, target_resp.text)
        self.target_access_token = target_resp.json()["access_token"]
        self.target_refresh_token = target_resp.json()["refresh_token"]
        self.target_headers = {"Authorization": f"Bearer {self.target_access_token}"}

        with db_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    UPDATE users
                    SET is_admin = true
                    WHERE username = %s
                    RETURNING id::text
                    """,
                    (self.admin_email,),
                )
                self.admin_user_id = cur.fetchone()[0]
                cur.execute(
                    """
                    SELECT id::text
                    FROM users
                    WHERE username = %s
                    """,
                    (self.target_email,),
                )
                self.target_user_id = cur.fetchone()[0]

    def test_non_admin_cannot_search_users(self) -> None:
        resp = self.client.get("/admin/users", headers=self.target_headers)
        self.assertEqual(resp.status_code, 403, resp.text)

    def test_admin_can_search_and_grant_admin(self) -> None:
        search_resp = self.client.get(
            "/admin/users",
            params={"query": self.target_email},
            headers=self.admin_headers,
        )
        self.assertEqual(search_resp.status_code, 200, search_resp.text)
        self.assertEqual(search_resp.json()[0]["id"], self.target_user_id)

        grant_resp = self.client.post(
            f"/admin/users/{self.target_user_id}/grant-admin",
            headers=self.admin_headers,
        )
        self.assertEqual(grant_resp.status_code, 200, grant_resp.text)
        self.assertTrue(grant_resp.json()["is_admin"])

    def test_ban_revokes_sessions_blocks_access_and_deletes_territories(self) -> None:
        with db_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    INSERT INTO territories (user_id, geom)
                    VALUES (
                      %s,
                      ST_Multi(ST_GeomFromText(
                        'POLYGON((37.60 55.75,37.601 55.75,37.601 55.751,37.60 55.751,37.60 55.75))',
                        4326
                      ))
                    )
                    """,
                    (self.target_user_id,),
                )

        ban_resp = self.client.post(
            f"/admin/users/{self.target_user_id}/ban",
            headers=self.admin_headers,
        )
        self.assertEqual(ban_resp.status_code, 200, ban_resp.text)
        self.assertTrue(ban_resp.json()["user"]["is_banned"])
        self.assertEqual(ban_resp.json()["deleted_territories_count"], 1)
        self.assertGreaterEqual(ban_resp.json()["revoked_sessions_count"], 1)

        me_resp = self.client.get("/me/profile", headers=self.target_headers)
        self.assertEqual(me_resp.status_code, 403, me_resp.text)
        self.assertEqual(me_resp.json()["detail"], "user banned")

        refresh_resp = self.client.post(
            "/auth/refresh",
            json={"refresh_token": self.target_refresh_token},
        )
        self.assertEqual(refresh_resp.status_code, 403, refresh_resp.text)
        self.assertEqual(refresh_resp.json()["detail"], "user banned")

        with db_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT count(*) FROM territories WHERE user_id = %s",
                    (self.target_user_id,),
                )
                self.assertEqual(cur.fetchone()[0], 0)

    def test_admin_cannot_ban_self_or_revoke_own_admin(self) -> None:
        ban_resp = self.client.post(
            f"/admin/users/{self.admin_user_id}/ban",
            headers=self.admin_headers,
        )
        self.assertEqual(ban_resp.status_code, 400, ban_resp.text)

        revoke_resp = self.client.post(
            f"/admin/users/{self.admin_user_id}/revoke-admin",
            headers=self.admin_headers,
        )
        self.assertEqual(revoke_resp.status_code, 400, revoke_resp.text)


if __name__ == "__main__":
    unittest.main()
