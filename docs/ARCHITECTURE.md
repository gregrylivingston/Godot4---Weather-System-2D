# Architecture — Weather System 2D

How the pieces actually fit together. For the *plan* to extend all of this, see
[`ROADMAP.md`](ROADMAP.md). This document describes the system **as it is today**: the
`addons/weather2d/` plugin. (The original hand-authored rose-garden demo and its legacy
`SkySetting` hub have been removed; everything below is the current, addon-based kit.)

---

## Overview

The kit is organized around a **code-first builder** plus a **runtime hub**:

- **`WeatherScene`** (a builder) assembles a scene declaratively — time of day, weather,
  cloud style, terrain stack, water, props — and `build()`s a ready `Node2D` tree,
  deterministic for a given seed.
- For a **living** scene (`.live()`), the builder also adds a **`SkyController`**: the
  runtime hub that advances a day-night cycle and weather transitions and pushes the results
  into every material each frame.
- Effect nodes (`WaterBody2D`, …) read weather from the controller via the **`"SkySetting"`
  group** and Godot **signals**, so weather stays decoupled from the effects.
- All visuals live in **canvas-item shaders**; the GDScript is glue that maps values →
  shader uniforms.

```
WeatherScene.build()  ─►  Node2D tree
                          Camera2D · Sky · Clouds · Terrain bands · Water ·
                          CloudShadow · Fog · Rain · (Painterly) · SkyController*
                                                          (*only when .live())

SkyController  (Node2D, group "SkySetting")
│  state:   TimeOfDay (sun_uv/color, palette, stars) + WeatherPreset (rain/fog/cloud/wind)
│  step():  day-night cycle · weather cross-fade · lightning   (all scaled by frame delta)
│  emits:   updateRainAmount, updateCloudAmount
│
├─ pushes uniforms ─► sky / clouds / cloud_shadow / fog / rain materials + water glint
└─ updateRainAmount ─► WaterBody2D  → darkens water, raises foam/waves, rain ripples
```

---

## Resources (the "what") — `addons/weather2d/resources/`

These are plain `Resource`s with static factories; they carry *data*, no nodes.

### `TimeOfDay`
The time-of-day half of the atmosphere and the **unified sun model**: `sky_top`/`sky_bottom`,
`water_deep`/`water_shallow`, `cloud_color`, `fog_color`, `ambient`, plus `sun_uv`
(screen position), `sun_color` (light tint) and `star_intensity`. Factories: `dawn()`,
`noon()`, `golden_hour()`, `dusk()`, `night()`. `cycle(day01)` interpolates the five
keyframes over a normalized clock; `lerp_to(other, t)` blends two.

### `WeatherPreset`
The weather half — `rain`, `snow`, `fog`, `clouds`, `wind`, and how much it `darken`s /
`desaturate`s the palette. Factories: `clear/cloudy/foggy/rainy/stormy/snowy()`. Orthogonal
to `TimeOfDay`, so any hour combines with any weather.

### `CloudPreset`
Cloud style — `coverage`, `scale`, `speed`, `density`, `softness`, `detail`,
`dark`/`light`. Factories: `clear/wispy/scattered/cumulus/overcast/stormy()`.

### `TerrainLayer`
Describes one parallax band: `role` (`GROUND`/`HILL`/`MOUNTAIN`/`TREELINE`/`FOREGROUND`),
palette, `roughness`, `scroll_scale`, `coast_level`, `wave_*`, `seed`. Factories:
`ground/hills/mountains/treeline/foreground()`.

### `ScenePreset`
A whole composition (seed, size, `TimeOfDay`, `WeatherPreset`, terrain list, water) so a
scene can be saved to a `.tres` and rebuilt with `WeatherScene.new().from_preset(p).build()`.

---

## Nodes (the "how") — `addons/weather2d/nodes/`

### `SkyController` — the runtime hub *(Phase 5)*
`class_name SkyController extends Node2D`, group `"SkySetting"`.

Holds the active `TimeOfDay` + `WeatherPreset` and references to the scene's materials/water.
`step(delta)` (called from `_process`, and directly from tests):

- advances `day01` by `day_night_speed * delta` when `time_cycle_enabled` (→ `TimeOfDay.cycle`);
- advances any `transition_to(target, duration)` weather cross-fade;
- runs lightning (flash cadence scales with storm intensity);
- pushes palette + `sun_uv`/`sun_color`/`star_intensity` to the sky, cloud, cloud-shadow, fog
  and rain materials and the water's glint;
- **emits `updateRainAmount` / `updateCloudAmount`** when they change.

All motion is scaled by frame `delta`, so it is **frame-rate independent**.

### `WaterBody2D` — water surface *(Phase 1)*
`class_name WaterBody2D extends ColorRect`. Owns its `ShaderMaterial` + a seamless
`NoiseTexture2D`, so it works with no setup. `Mode`: `STILL` / `RIVER` / `OCEAN_BEACH`.
Every exported property (palette, waves, flow, foam, run-up, reflection, `sun_uv`/
`glint_strength`, `rain_ripple`) pushes to the shader via a setter. When `react_to_weather`
is on, `_ready` connects to the `"SkySetting"` group's `updateRainAmount`; `_on_rain_amount`
darkens/roughens the water and rings it with ripples (modulating from captured base values,
so it never drifts).

### `TerrainBand2D` — one terrain band *(Phase 2)*
`class_name TerrainBand2D extends ColorRect`. Renders a `TerrainLayer`: picks
`terrain_ground.gdshader` for the `GROUND` role and `terrain_silhouette.gdshader` for the
silhouette roles, and pushes the layer's params.

### `PropScatter2D` — vector prop scatter *(Phase 2)*
`class_name PropScatter2D extends Node2D`. Seeded, **stratified** placement of the SVG props
(one `Sprite2D` per prop) with depth-scaling, atmospheric haze, ground shadows, and an
`animation` mode (`SWAY` → `foliage_wind`, `FLY` → `bird_fly`). Deterministic for a seed.

### `PainterlyLayer` — post-process *(Phase 2/4)*
`class_name PainterlyLayer extends CanvasLayer`. A high-layer full-rect `ColorRect` with
`painterly.gdshader` (soft-focus blur + warmth + grain + vignette).

### `MapCamera2D` — camera
`class_name MapCamera2D extends Camera2D` (repo root). Self-contained pan/zoom/drag camera
with mouse-wheel + keyboard zoom, edge/arrow panning, left-drag inertia, and pinch/pan
gestures. Independent of the weather system — reusable anywhere. *(The `WeatherScene` builder
uses a plain `Camera2D`; `MapCamera2D` is available as a standalone node.)*

---

## API — `addons/weather2d/api/`

### `WeatherScene` — the builder
`class_name WeatherScene extends RefCounted`. Fluent, chainable configuration
(`set_seed`, `time_of_day`, `weather`, `cloud_style`, `terrain`, `water`, `props`, `birds`,
`painterly`, `rain`/`fog`/`wind`/`clouds` overrides, `live`, `lightning`), then `build()`
returns the `Node2D` tree. `build()`:

1. creates the `Camera2D` and an ambient `CanvasModulate`;
2. builds the **Sky** (`sky.gdshader`) from the `TimeOfDay` sun model;
3. builds the **Clouds** (from the `CloudPreset`, tinted by time of day, darkened by weather);
4. lays out **terrain bands** back-to-front (sharing a coastline with the water);
5. adds the **`WaterBody2D`**, aligned to the ground's coast;
6. scatters **props / birds**, then **cloud shadow**, **fog**, **rain**, **lightning**, and
   **painterly** overlays;
7. when `.live()`, wires a **`SkyController`** to all of the above.

With `.live()` the cloud/fog/rain/shadow overlays are always instantiated (even at ~0
amount) so a weather transition can bring them in.

### `Scenarios`
Ready-made recipes returning a configured (not-yet-built) `WeatherScene`:
`Scenarios.build(name, opts)` for **Beach / Small Island / River / Lake / Mountains**. The
launcher uses these.

---

## Shaders — `addons/weather2d/shaders/`

All `shader_type canvas_item`. See the [README shader table](../README.md#shaders) for each
shader's key uniforms. In brief: `sky` (gradient + sun/moon disc + stars), `clouds` (fBm +
ridged detail, sun-lit, wind drift), `cloud_shadow` (moving dapple on the ground/water),
`water_body` (three modes, foam, reflections, glint, ripples), `rain` (rain/snow streaks),
`fog` (distance haze), `terrain_silhouette` and `terrain_ground` (seeded land), `foliage_wind`
and `bird_fly` (prop animation), and `painterly` (post-process).

The **unified sun model** is what makes these read as one lit world: `sky`, `clouds`,
`cloud_shadow` and `water_body` all take `sun_uv` (and a sun tint) from the same `TimeOfDay`.

---

## Data flow summary

1. `WeatherScene.build()` produces the node tree; without `.live()` it is a correct **static**
   composite (each material set once).
2. With `.live()`, `SkyController.step(delta)` each frame advances the day-night cycle and any
   weather transition and **re-pushes** the derived values to every material.
3. When rain changes, the controller **emits `updateRainAmount`**; `WaterBody2D` (found via the
   `"SkySetting"` group) maps it onto its own uniforms.
4. New effects need no controller changes — a node just joins the `"SkySetting"` group's signal
   and maps the `0..1` value to its own shader.

---

## Tests

`tests/run_tests.gd` is a zero-dependency headless runner (**89 checks**) covering the node
logic (property → uniform wiring, mode enum, weather response), the builder (tree shape,
determinism, preset round-trip), the resources (cloud styles, time × weather axes, the sun
model & `cycle`), and the `SkyController` (day advance, frame-rate independence, weather
transition, signal emission). See [`../tests/README.md`](../tests/README.md).
