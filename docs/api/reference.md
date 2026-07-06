# API reference

The public API of the `weather2d` addon. Types register via `class_name`, so they're
available globally once the plugin is enabled. For a guided intro see
[getting-started.md](getting-started.md); for the internals see
[../ARCHITECTURE.md](../ARCHITECTURE.md).

---

## `WeatherScene` — the builder

`RefCounted`. Configure with chainable calls, then `build()`. Every setter returns `self`.

| Method | Purpose |
|---|---|
| `set_seed(s: int)` | Seed for all deterministic generation (terrain, props). |
| `set_size(sz: Vector2)` | Scene size in pixels (default `1920×1080`). |
| `time_of_day(tod: TimeOfDay)` | Sky/water palette, sun model, ambient. |
| `weather(preset: WeatherPreset)` | Rain / snow / fog / clouds / wind + palette darkening. |
| `cloud_style(preset: CloudPreset)` | Cloud look (coverage/scale/softness/…). |
| `terrain(layers: Array)` | Replace the terrain stack (back-to-front). |
| `add_terrain(layer: TerrainLayer)` | Append one band. |
| `water(mode := OCEAN_BEACH, level := 0.66)` | Add a `WaterBody2D`. |
| `no_water()` | Omit water. |
| `props(enable := true, count := 16, textures := [])` | Scatter trees/rocks per layer. |
| `birds(enable := true, count := 5)` | Scatter birds across the sky. |
| `rain/fog/wind/clouds(amount: float)` | Override a weather value (negative = follow the preset). |
| `snow(on: bool)` | Force snow on/off. |
| `painterly(enable := true)` | Soft-focus + grain + vignette post-process. |
| `live(enable := true, day_night_speed := 0.0)` | Add a `SkyController` (animate at runtime). `day_night_speed` is days/sec. |
| `lightning(enable := true)` | Storm lightning flashes (needs `live`). |
| `from_preset(preset: ScenePreset)` | Load a whole composition. |
| `build() -> Node2D` | Assemble and return the node tree. |

---

## `SkyController` — the runtime hub

`Node2D`, joins the `"SkySetting"` group. Added by `WeatherScene.live()`; you rarely build one
by hand. All motion is scaled by frame `delta`.

**Exports:** `day_night_speed` (days/sec), `time_cycle_enabled`, `day01` (0..1 clock),
`lightning_enabled`.

**Signals:** `updateRainAmount(amount: float)`, `updateCloudAmount(amount: float)`.

| Method | Purpose |
|---|---|
| `set_weather(preset)` | Set the current weather with no transition. |
| `transition_to(target: WeatherPreset, duration := 6.0)` | Cross-fade to new weather over `duration` seconds. |
| `current_weather() -> WeatherPreset` | The blended weather in effect right now. |
| `current_time() -> TimeOfDay` | The time of day in effect right now. |
| `step(delta)` | Advance the sim and push to all materials (called from `_process`). |

---

## `WaterBody2D` — water surface

`ColorRect`. Owns its material + noise, so it works with no wiring. `enum Mode { STILL, RIVER,
OCEAN_BEACH }`.

**Key exported properties** (all push to the shader on set):

- *Palette:* `deep_color`, `shallow_color`, `foam_color`, `water_opacity`.
- *Surface:* `wave_scale`, `wave_speed`, `wave_distortion`, `wave_height`, `wave_frequency`.
- *Waterline:* `level` (0 top … 1 bottom, STILL & OCEAN_BEACH).
- *River:* `flow_direction`, `flow_speed`.
- *Foam:* `foam_amount`, `foam_width`.
- *Ocean run-up:* `swell_height`, `swell_speed`.
- *Reflection:* `reflection_enabled`, `reflection_strength`, `reflection_offset`.
- *Sun glint:* `sun_uv`, `sun_color`, `glint_strength`, `rain_ripple`.
- *Weather:* `react_to_weather`, `weather_influence`.
- *Terrain mask:* `use_terrain_mask`, `terrain_mask`.

**Methods:** `set_day_palette(deep, shallow)` — re-base the palette (used by the day-night
cycle) and re-apply the current rain modulation. When `react_to_weather` is on, connects to the
`"SkySetting"` group's `updateRainAmount` at `_ready`.

---

## `TerrainBand2D` — one terrain band

`ColorRect`. Set `layer: TerrainLayer`; it picks `terrain_ground` (GROUND role) or
`terrain_silhouette` (hill/mountain/treeline) and pushes the layer's params. Size/position as
any `Control`.

## `PropScatter2D` — vector prop scatter

`Node2D`. Seeded, stratified placement of `textures` (one `Sprite2D` each). Key exports:
`textures`, `count`, `seed`, `width`, `band_height`, `scale_min`/`scale_max`, `depth_scale`,
`flip_random`, `tint_variation`, `haze_amount`/`haze_color`, `cast_shadows`, `animation`
(`ANIM_NONE` / `ANIM_SWAY` / `ANIM_FLY`), `sway_strength`, `sway_speed`.

## `PainterlyLayer` — post-process

`CanvasLayer` (high layer) with a full-rect overlay running `painterly.gdshader` (soft-focus
blur + warmth + grain + vignette). Drop it on top of a scene, or add it via `WeatherScene.painterly()`.

## `MapCamera2D` — camera

`Camera2D` (repo root, standalone). Mouse-wheel + keyboard zoom (relative to the cursor),
edge/arrow panning, left-drag with inertia, and pinch/pan gestures. Independent of the weather
system.

---

## Resources

### `TimeOfDay`
Palette + unified sun model. Fields: `sky_top`, `sky_bottom`, `water_deep`, `water_shallow`,
`cloud_color`, `fog_color`, `ambient`, `day` (canonical clock position), `sun_uv`, `sun_color`,
`star_intensity`. Factories: `dawn/noon/golden_hour/dusk/night()`. Methods: `lerp_to(other, t)`,
static `cycle(day01) -> TimeOfDay` (interpolates the keyframes for a day-night cycle).

### `WeatherPreset`
Fields: `rain`, `rain_delta`, `snow`, `fog`, `clouds`, `wind`, `darken`, `desaturate`.
Factories: `clear/cloudy/foggy/rainy/stormy/snowy()`.

### `CloudPreset`
Fields: `coverage`, `scale`, `speed`, `dark`, `light`, `density`, `softness`, `detail`.
Factories: `clear/wispy/scattered/cumulus/overcast/stormy()`.

### `TerrainLayer`
Describes one band. `enum Role { GROUND, HILL, MOUNTAIN, TREELINE, FOREGROUND }`. Fields include
`role`, `roughness`, `scroll_scale`, `coast_level`, `wave_height`, `wave_frequency`, `height`,
palette colors, `seed`. Factories (each takes an optional tint `Color`):
`ground/hills/mountains/treeline/foreground()`.

### `ScenePreset`
A whole composition: `scene_seed`, `size`, `time_of_day`, `weather`, `terrain` (Array),
`include_water`, `water_mode`, `water_level`. Load with `WeatherScene.from_preset()`.

---

## `Scenarios`

`Scenarios.build(name: String, opts := {}) -> WeatherScene` returns a configured (not-yet-built)
scene. `Scenarios.LIST` = **Beach, Small Island, River, Lake, Mountains**.

`opts` keys (all optional): `seed:int`, `time_of_day:TimeOfDay`, `weather:WeatherPreset`,
`cloud_style:CloudPreset`, `props:bool`, `birds:bool`, `painterly:bool`, `snow:bool`,
`rain/fog/wind/clouds:float` (negative follows the preset), and for a living scene
`live:bool`, `day_night_speed:float`, `lightning:bool`.
