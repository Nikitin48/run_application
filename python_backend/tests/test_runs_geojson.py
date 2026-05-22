from __future__ import annotations

import unittest

from app.routers.runs import _track_geojson_from_coords


class RunsGeoJsonTest(unittest.TestCase):
    def test_track_geojson_from_coords_uses_geojson_coordinate_order(self) -> None:
        geojson = _track_geojson_from_coords(
            [
                (55.75396, 37.620393),
                (55.7542, 37.6225),
            ]
        )

        self.assertEqual(
            geojson,
            {
                "type": "LineString",
                "coordinates": [
                    [37.620393, 55.75396],
                    [37.6225, 55.7542],
                ],
            },
        )

    def test_track_geojson_from_coords_requires_two_points(self) -> None:
        self.assertIsNone(_track_geojson_from_coords([(55.75396, 37.620393)]))


if __name__ == "__main__":
    unittest.main()
