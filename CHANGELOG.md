# Changelog

All notable changes to this project are documented here.
The format loosely follows [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Added
- **Addon packaging (Phase 0):** `addons/weather2d/` plugin (`plugin.cfg` + `plugin.gd`)
  so the kit can be enabled as a unit and grow editor tooling.
- **`WaterBody2D` node (Phase 1):** a configurable, self-contained 2D water surface
  (`addons/weather2d/nodes/water_body_2d.gd`) with three modes — **Still**, **River**,
  and **Ocean-Beach** — exposing palette, waves, flow, foam, run-up, and reflection
  properties in the inspector and from code.
- **`water_body.gdshader`:** new water shader supporting the three modes, shoreline
  **foam**, wetness-style depth shading, directional **river flow**, animated
  **beach run-up**, and an optional `terrain_mask` input reserved for Phase 2.
- **Rolling sine-wave surface action:** `wave_height` / `wave_frequency` undulate the
  waterline (and the ocean-beach shore edge) as a sum of sines, with crest highlights and
  streaming river ripples.
- **Weather-reactive water:** `WaterBody2D` connects to a `SkySetting` at runtime so rain
  darkens/desaturates the palette and raises foam and wave height (`react_to_weather`,
  `weather_influence`).
- **Terrain (Phase 2):** `TerrainLayer` resource + `TerrainBand2D` node, with
  `terrain_silhouette.gdshader` (hills/mountains/treeline, analytic noise, seeded) and
  `terrain_ground.gdshader` (sand/beach with grain + wetness). The sand and water share an
  analytic **coastline** (`coast_level` + `wave_*`) so the ocean lines up with the land it
  washes over.
- **Scene builder (Phase 3):** `WeatherScene` fluent builder API
  (`addons/weather2d/api/weather_scene.gd`) that assembles sky + terrain bands + water into
  a ready node tree, deterministically from a seed. Plus `WeatherPreset` and `ScenePreset`
  resources (atmosphere + whole-composition presets, with `clear_noon` / `overcast_dusk` /
  `storm` factories).
- **Demos:** `demos/water_demo.tscn` (water modes), `demos/beach_demo.tscn`
  (mountains → hills → sand → ocean washing in), and `demos/generated_demo.tscn` (a scene
  built entirely from code in `_ready`).
- **Tests:** dependency-free headless runner `tests/run_tests.gd` — 38 checks covering the
  water/terrain nodes, weather response, the builder, determinism, and preset round-trip
  (+ `tests/README.md`).
- **Docs:** rewritten `README.md`, new `docs/ARCHITECTURE.md` and `docs/ROADMAP.md`.

### Fixed
- Terrain shaders degenerated to near-flat noise for large `seed` values (precision loss
  feeding big numbers into `sin()`); the seed is now bounded with `mod()`. Generated scenes
  with realistic seeds now show proper jagged mountains and sand grain.

### Changed
- Nicer water defaults (more saturated teal palette, lower reflection strength, slightly
  bigger waves) and a beach demo re-composed so the sand beach is clearly visible.

### Notes
- Legacy assets under `Weather2D/` are intentionally left in place for now; migrating them
  into `addons/weather2d/` should be done via the Godot editor (drag-move updates the
  `uid`/path references in the large demo scene safely).

## [0.0.0] — original
- Initial personal release: `SkySetting` weather hub, cloud/rain/raindrop/water shaders,
  `MapCamera2D`, and the hand-authored rose-garden demo.
