# Changelog

All notable changes to this project are documented here.
The format loosely follows [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Added
- **Weather options:** seven presets (Clear Noon, Golden Hour, Overcast Dusk, Foggy, Storm,
  Snowy Dusk, Night) plus **fog** (`fog.gdshader`), **snow** (rain shader snow mode),
  **drifting clouds** (`clouds.gdshader`), and **wind** that drives foliage sway and rain
  slant. Exposed via `WeatherScene.fog()/.wind()/.clouds()/.snow()` and the launcher sliders
  (selecting a preset fills the sliders with its mood).
- **Layer-anchored prop distribution:** props are now planted **per terrain layer** — small,
  hazy trees on the back hills; big, crisp trees/palms/rocks on the near shore/foreground —
  instead of one flat random row. Further layers get smaller, hazier props (`_ROW_CONFIG`).
- **Better birds:** each bird has its own flap phase (they no longer beat in unison) and
  actually **flies across the sky** (script-driven travel + wrap, facing its direction).
- **Launcher / playground (`demos/launcher.tscn`, now the main scene):** pick a **scenario**
  (Beach / Small Island / River / Lake / Mountains), a **weather** mood, drag **rain / fog /
  wind**, toggle **snow** / props / birds / painterly — the scene rebuilds live. Plus a seed
  field + Randomize.
- **`Scenarios`** helper — five ready-made scene recipes (`Scenarios.build(name, opts)`),
  each a configured `WeatherScene`.
- **Animated props:** `foliage_wind.gdshader` (trees/bushes sway, each out of phase) and
  `bird_fly.gdshader` (birds drift, bob, and flap). `PropScatter2D` gains an `animation`
  mode, **rotation jitter**, and soft **ground shadows** so props read as planted.
- **Rain overlay** (`rain.gdshader`) added by `WeatherScene.rain(amount)` / the weather
  preset; **river** water mode + a `TerrainLayer.foreground()` bank that draws in front of
  the water.
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

- **SVG props + seeded scatter (Phase 2):** a vector-art set under `assets/svg/` (round
  tree, pine, **palm, bush, flower, driftwood, bird**, rock, grass tuft — now with soft
  gradient shading) and a `PropScatter2D` node that scatters them **stratified** (even, no
  clumps/gaps), with **depth-scaling** and **atmospheric haze** so far props recede.
  Scattered sprites are internal (not serialized). `WeatherScene.props()` / `.birds()`.
- **Layered background:** the builder staggers multiple same-role bands, so a far + near
  mountain range reads with real depth; hills raised to sit visibly behind the shore props.
- **Painterly post-process (Phase 4 start):** `painterly.gdshader` + `PainterlyLayer`
  (CanvasLayer) — a soft-focus blur, warmth, paper grain, and vignette that make the whole
  frame read like a soft painting. `WeatherScene.painterly()` / `.props()` add them.

### Fixed
- Terrain shaders degenerated to near-flat noise for large `seed` values (precision loss
  feeding big numbers into `sin()`); the seed is now bounded with `mod()`. Generated scenes
  with realistic seeds now show proper jagged mountains and sand grain.

### Changed
- Nicer water defaults (more saturated teal palette, lower reflection strength, slightly
  bigger waves) and a beach demo re-composed so the sand beach is clearly visible.
- **Painterly terrain art pass:** both terrain shaders rewritten to use smooth quintic
  value-noise fBm with domain warping — organic, non-repetitive mountain ridges, soft tonal
  mottling, and fine (no longer blocky) sand grain. Removed the vertical "curtain" shading
  on silhouettes by gradient-ing on absolute height.
- **Generated-scene composition retuned:** lower, less dominant mountains and a higher
  waterline so the sea reads properly (horizon a little below centre). Layout is now
  expressed in screen fractions for easier tuning.

### Notes
- Legacy assets under `Weather2D/` are intentionally left in place for now; migrating them
  into `addons/weather2d/` should be done via the Godot editor (drag-move updates the
  `uid`/path references in the large demo scene safely).

## [0.0.0] — original
- Initial personal release: `SkySetting` weather hub, cloud/rain/raindrop/water shaders,
  `MapCamera2D`, and the hand-authored rose-garden demo.
