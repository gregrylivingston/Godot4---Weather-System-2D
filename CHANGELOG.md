# Changelog

All notable changes to this project are documented here.
The format loosely follows [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Fixed
- **Drifting vertical banding in the sky.** The cloud (and cloud-shadow / fog) noise fed
  ever-growing coordinates into a `sin()`/multiply hash; at large values the hash lost float
  precision and collapsed into faint axis-aligned bands that scrolled with the wind. The hash
  input is now wrapped to a large period (`mod(p, 256)`), keeping it precise — the banding is
  gone with no meaningful change to the cloud shape.

### Added
- **Low-graphics mode** (`WeatherScene.low_graphics()`, a **Low graphics** toggle in the
  launcher, and a `low_graphics:bool` scenario option) for weak or software (no-GPU) renderers.
  A `quality` uniform selects cheap shader paths and the builder drops the priciest passes:
  - **Clouds:** 3 octaves instead of 6, and the ridged detail + sun-rim lighting are skipped.
  - **Water:** no screen reflection, a single wave sample, and no rain ripples.
  - **Rain:** the per-pixel drop loop is capped much lower (thinner rain).
  - **Fog:** a flat band with no per-pixel noise.
  - The **cloud-shadow** and **painterly** full-screen passes are skipped, and fewer props are
    scattered. The composition is unchanged; the look is simplified.
- **High-quality perf trims (no significant visual change):** the fog / cloud-shadow / rain
  shaders now early-out when their effect is off (density/coverage/amount ≈ 0) instead of
  running full-screen noise, and the cloud sun-rim probe uses 3 octaves instead of a full
  second 6-octave fBm.
- Test suite up to **103 checks** (adds the low-graphics wiring).

## [0.1.0] — 2026-07-06

First tagged release: the `addons/weather2d/` kit (builder, living scenes, water, terrain,
props, painterly) with docs and a 95-check test suite. The legacy rose-garden system has been
removed. Highlights:

### Added
- **Day-night water palette (Phase 5 polish).** Under `.live()` with a running clock, the
  water's deep/shallow colors now interpolate through the day too (via
  `WaterBody2D.set_day_palette`), closing the "water doesn't day-cycle" gap. `TimeOfDay` gained
  a canonical `day` position so a living scene **starts at the chosen time of day**.
- **API docs** — `docs/api/getting-started.md` (a five-minute "make your first scene" tutorial)
  and `docs/api/reference.md` (the full builder / node / resource reference).
- **`CONTRIBUTING.md`**, a project **icon** (`icon.svg`), and a filled-in `plugin.cfg`.
- **Phase 5 — Living simulation & atmosphere depth** 🌦️. Generated scenes can now
  be *alive* rather than a static snapshot:
  - **Unified sun/moon model.** [TimeOfDay] now carries a `sun_uv` (screen position), `sun_color`
    (light tint), and `star_intensity`. The same model drives the sky glow & disc, the lit side
    of the clouds, and the water glint, so a scene reads as lit by one light.
  - **Sky shader (`sky.gdshader`)** replaces the flat 2-stop gradient — a gradient with a
    **sun/moon disc + glow** positioned from `sun_uv`, and **twinkling stars** that fade in with
    `star_intensity`. `WeatherScene` now builds the Sky as a `ColorRect` + shader.
  - **Day-night cycle.** `TimeOfDay.cycle(day01)` interpolates the five keyframe times
    (dawn→noon→golden→dusk→night) over a normalized clock; the new [SkyController] advances it.
  - **`SkyController` runtime node** (joins the `"SkySetting"` group, emits `updateRainAmount` /
    `updateCloudAmount`): runs the day-night cycle, **cross-fades between `WeatherPreset`s**
    (`transition_to`), flashes **lightning** during storms, and drives every material each frame —
    all scaled by frame `delta`, so it's **frame-rate independent**. Added by
    `WeatherScene.live()` / `.lightning()`.
  - **Water: sun glint + rain-ripple impacts.** `water_body.gdshader` gains a shimmering specular
    streak under the sun (`sun_uv` / `glint_strength`, faded at night) and concentric **ripple
    rings** driven by the rain amount (`rain_ripple`).
  - **Clouds: sun lighting + wind drift + cast shadows.** `clouds.gdshader` now lights the
    sun-facing edge (`sun_uv` / `sun_tint`) and drifts along `wind_dir`; a new
    `cloud_shadow.gdshader` dapples the land & water with soft moving shadows tied to coverage.
  - **Live plumbing.** With `.live()`, the builder always instantiates the cloud/fog/rain/shadow
    overlays so a weather transition can bring them in, and wires the `SkyController` to them —
    closing the Phase 3 gap where generated scenes had no live `SkySetting` for
    `WaterBody2D.react_to_weather` to hook into.
  - **Launcher** gains an *Animate (live sun + weather)* toggle, a *Lightning* toggle, and a
    *Day–night speed* slider; `demos/generated_demo` now runs a slow day-night cycle.
- **Volumetric clouds with their own controls & presets.** Rewrote `clouds.gdshader` into a
  layered fBm + ridged-detail cloud system (ported from the "Cloudy skies" technique) with
  lit tops / shadowed bases and a horizon perspective. New **`CloudPreset`** resource with
  six styles — **Clear, Wispy, Scattered, Cumulus, Overcast, Stormy** — exposed via
  `WeatherScene.cloud_style()` and a **Clouds** dropdown in the launcher (with an *Auto*
  option that matches the weather). Cloud color comes from the [TimeOfDay] and storms darken
  them, so the same style reads right at any hour (e.g. warm golden-hour thunderheads,
  purple dusk cumulus).
- **Time of day and weather are now separate, orthogonal axes** — combine any of Dawn / Noon
  / Golden Hour / Dusk / Night with any of Clear / Cloudy / Foggy / Rainy / Stormy / Snowy
  (e.g. *golden hour + storm*, *night + snow*). New **`TimeOfDay`** resource sets the sky &
  water palette, cloud/fog tint, and a scene-wide **ambient** light; **`WeatherPreset`** is
  now weather-only (rain/snow/fog/clouds/wind + how much it darkens/greys the palette).
  `WeatherScene.time_of_day()` / `.weather()`; the launcher has two dropdowns.
- **Weather options:** **fog** (`fog.gdshader`), **snow** (rain shader snow mode),
  **drifting clouds** (`clouds.gdshader`), and **wind** that drives foliage sway and rain
  slant. Exposed via `WeatherScene.fog()/.wind()/.clouds()/.snow()` and the launcher sliders.
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
- **Tests:** dependency-free headless runner `tests/run_tests.gd` — **95 checks, all passing** covering the
  water/terrain nodes, weather response, the builder, determinism, preset round-trip, cloud
  styles, the time-of-day × weather axes, prop scatter/animation, the painterly layer, the
  rain overlay, every `Scenarios` recipe, that the real `beach_demo`/`launcher` scenes load and
  drive their live materials, and the Phase 5 additions (sun model & day-night cycle, sky/water/
  cloud sun uniforms, the live overlays, and the `SkyController`'s day advance, frame-rate
  independence, weather transition and signal emission) (+ `tests/README.md`).
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
- **Docs refresh:** README documents the full **addon shader set** (not just the four legacy
  shaders) — now including `sky`, `cloud_shadow` and the Phase 5 uniforms — and `docs/ROADMAP.md`
  gained a **Phase 5 — Living simulation** section (now largely implemented).
- The generated Sky is now a `ColorRect` + `sky.gdshader` instead of a `TextureRect` + gradient
  texture; `WeatherScene._make_sky_gradient()` was removed.
- Nicer water defaults (more saturated teal palette, lower reflection strength, slightly
  bigger waves) and a beach demo re-composed so the sand beach is clearly visible.
- **Painterly terrain art pass:** both terrain shaders rewritten to use smooth quintic
  value-noise fBm with domain warping — organic, non-repetitive mountain ridges, soft tonal
  mottling, and fine (no longer blocky) sand grain. Removed the vertical "curtain" shading
  on silhouettes by gradient-ing on absolute height.
- **Generated-scene composition retuned:** lower, less dominant mountains and a higher
  waterline so the sea reads properly (horizon a little below centre). Layout is now
  expressed in screen fractions for easier tuning.

### Removed
- **The legacy `Weather2D/` rose-garden demo and its whole subsystem** — the hand-authored
  `demo-rose-garden.tscn`, the `SkySetting` hub + `sky.gd` / rain panels, the four legacy
  shaders (`shader_clouds`, `shader_rain_snow`, `shader_raindrops_on_screen`, `shader_water`),
  the rose/scenery textures and rosebush scenes, and `Gradient2D_Sky.tres` (47 files). It was
  fully superseded by the `addons/weather2d/` kit and nothing else referenced it. The reusable
  `MapCamera2D` (its only external dependency) is kept as a standalone node at the repo root.
  The `"SkySetting"` global group name is retained — it's the signal channel the new
  `SkyController` and `WaterBody2D` use. Docs (README, ARCHITECTURE, ROADMAP) were rewritten
  to describe the addon instead of the removed hub.

## [0.0.0] — original
- Initial personal release: `SkySetting` weather hub, cloud/rain/raindrop/water shaders,
  `MapCamera2D`, and the hand-authored rose-garden demo. *(Removed in Unreleased; see above.)*
