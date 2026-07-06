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
- **`demos/water_demo.tscn`:** a minimal scene to preview and tweak the water modes.
- **Docs:** rewritten `README.md`, new `docs/ARCHITECTURE.md` and `docs/ROADMAP.md`.

### Notes
- Legacy assets under `Weather2D/` are intentionally left in place for now; migrating them
  into `addons/weather2d/` should be done via the Godot editor (drag-move updates the
  `uid`/path references in the large demo scene safely).

## [0.0.0] — original
- Initial personal release: `SkySetting` weather hub, cloud/rain/raindrop/water shaders,
  `MapCamera2D`, and the hand-authored rose-garden demo.
