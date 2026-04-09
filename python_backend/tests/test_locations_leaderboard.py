from __future__ import annotations

import unittest
from uuid import uuid4

from fastapi.testclient import TestClient

from app.main import app


class LocationsLeaderboardIntegrationTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.client = TestClient(app)
        email = f"leaderboard-test-{uuid4().hex[:10]}@example.com"
        password = "Password123!"
        register_resp = cls.client.post(
            "/auth/register",
            json={
                "email": email,
                "password": password,
                "display_name": "Leaderboard Tester",
            },
        )
        assert register_resp.status_code == 200, register_resp.text
        token = register_resp.json()["access_token"]
        cls.headers = {"Authorization": f"Bearer {token}"}

        regions_resp = cls.client.get(
            "/locations/regions",
            params={"query": "", "limit": 10},
            headers=cls.headers,
        )
        assert regions_resp.status_code == 200, regions_resp.text
        regions = regions_resp.json()
        assert regions, "No regions in dictionary"
        cls.region_code = regions[0]["code"]

        cities_resp = cls.client.get(
            "/locations/cities",
            params={"region_code": cls.region_code, "query": "", "limit": 10},
            headers=cls.headers,
        )
        assert cities_resp.status_code == 200, cities_resp.text
        cities = cities_resp.json()
        assert cities, "No cities for selected region"
        cls.city_code = cities[0]["code"]

        profile_patch = cls.client.patch(
            "/me/profile",
            json={
                "region_code": cls.region_code,
                "city_code": cls.city_code,
            },
            headers=cls.headers,
        )
        assert profile_patch.status_code == 200, profile_patch.text

    def test_locations_endpoints_require_auth(self) -> None:
        resp = self.client.get("/locations/countries")
        self.assertEqual(resp.status_code, 401)

    def test_locations_countries_contains_ru(self) -> None:
        resp = self.client.get("/locations/countries", headers=self.headers)
        self.assertEqual(resp.status_code, 200, resp.text)
        codes = {item["code"] for item in resp.json()}
        self.assertIn("RU", codes)

    def test_locations_regions_search(self) -> None:
        resp = self.client.get(
            "/locations/regions",
            params={"query": "мос", "limit": 20},
            headers=self.headers,
        )
        self.assertEqual(resp.status_code, 200, resp.text)
        items = resp.json()
        self.assertLessEqual(len(items), 20)

    def test_locations_regions_pagination(self) -> None:
        first_page = self.client.get(
            "/locations/regions",
            params={"query": "", "limit": 10, "offset": 0},
            headers=self.headers,
        )
        second_page = self.client.get(
            "/locations/regions",
            params={"query": "", "limit": 10, "offset": 10},
            headers=self.headers,
        )
        self.assertEqual(first_page.status_code, 200, first_page.text)
        self.assertEqual(second_page.status_code, 200, second_page.text)
        first_items = first_page.json()
        second_items = second_page.json()
        if first_items and second_items:
            self.assertNotEqual(first_items[0]["code"], second_items[0]["code"])

    def test_locations_cities_without_region_fails(self) -> None:
        resp = self.client.get(
            "/locations/cities",
            params={"query": "мос"},
            headers=self.headers,
        )
        self.assertEqual(resp.status_code, 422)

    def test_leaderboard_country_area(self) -> None:
        resp = self.client.get(
            "/leaderboard",
            params={"scope": "country", "metric": "area", "limit": 20},
            headers=self.headers,
        )
        self.assertEqual(resp.status_code, 200, resp.text)
        body = resp.json()
        self.assertEqual(body["scope"], "country")
        self.assertEqual(body["metric"], "area")
        self.assertIn("entries", body)
        self.assertIn("my_rank", body)

    def test_leaderboard_region_distance(self) -> None:
        resp = self.client.get(
            "/leaderboard",
            params={"scope": "region", "metric": "distance", "limit": 20},
            headers=self.headers,
        )
        self.assertEqual(resp.status_code, 200, resp.text)
        body = resp.json()
        self.assertEqual(body["scope"], "region")
        self.assertEqual(body["metric"], "distance")

    def test_leaderboard_city_area(self) -> None:
        resp = self.client.get(
            "/leaderboard",
            params={"scope": "city", "metric": "area", "limit": 20},
            headers=self.headers,
        )
        self.assertEqual(resp.status_code, 200, resp.text)
        body = resp.json()
        self.assertEqual(body["scope"], "city")
        self.assertEqual(body["metric"], "area")


if __name__ == "__main__":
    unittest.main()
