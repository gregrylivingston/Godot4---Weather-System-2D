# Architecture — Weather System 2D

How the pieces actually fit together, node by node. For the *plan* to change all of this,
see [`ROADMAP.md`](ROADMAP.md). This document describes the system **as it is today**.

---

## Overview

The system is a **hub-and-spoke** design connected by Godot **signals**:

- One controller node, **`SkySetting`**, holds the weather state.
- Effect nodes **subscribe** to `SkySetting`'s signals and translate the incoming
  `0..1` weather values into **shader uniforms**.
- All visuals live in **canvas-item shaders**; the GDScript is just glue.

```
SkySetting (Node2D, @tool, group "SkySetting")
│  state: rainAmount, rainDelta, cloudAmount, cloudDelta, sunsetRate
│  emits: updateRainAmount, updateCloudAmount
│  _process(): applies deltas at runtime, advances the sunset gradient
│
├─ signal updateRainAmount ───► panel_rain_falling_in_sky.gd → rain shader `count`
│                          └──► panel_raindrops_on_screen.gd → drops shader `frequency`
│
└─ signal updateCloudAmount ──► sky.gd (TextureRect) → cloud shader `cloudcover`

Independent:
  MapCamera2D  — pan/zoom/drag camera
  shader_water — reflective water on a ColorRect (reads the weather indirectly via scene)
```

---

## Nodes & scripts

### `SkySetting` — the controller
**File:** [`../Weather2D/sky_setting.gd`](../Weather2D/sky_setting.gd) · `@tool class_name SkySetting extends Node2D`
**Group:** `"SkySetting"` (global group; effects find it with
`get_tree().get_first_node_in_group("SkySetting")`).

Exported state and the signals emitted when it changes:

| Property | Range | Setter emits | Notes |
|---|---|---|---|
| `rainAmount` | `-1 … 2` | `updateRainAmount` | `0` none → `1` max. Out-of-range values create a "delay" before an opposite delta shows. |
| `rainDelta` | `-1 … 1` | — | Runtime: `rainAmount += rainDelta / 100` each frame. |
| `cloudAmount` | `-1 … 2` | `updateCloudAmount` | Cloud cover. |
| `cloudDelta` | `-0.1 … 0.1` | — | Runtime: `cloudAmount += cloudDelta / 100` each frame. |
| `sunsetRate` | `0 … 0.25` | — | Slides the sky gradient's `fill_to` toward sunset. |

`_process(delta)`:
- Guarded by `if not Engine.is_editor_hint()` so the editor shows a static authored look.
- At runtime, applies both deltas and nudges `SkyGradient2D.fill_to` (x and y) by
  `sunsetRate / 1000` to descend into sunset.
- ⚠️ `SkyGradient2D` is a **loaded shared resource** (`Gradient2D_Sky.tres`); mutating it
  changes the in-memory instance for the whole run. See [known issues](ROADMAP.md#known-issues--tech-debt).

### `sky.gd` — cloud + sky background
**File:** [`../Weather2D/scene/sky.gd`](../Weather2D/scene/sky.gd) · `@tool extends TextureRect`

- On `_ready`, connects `SkySetting.updateCloudAmount` → `setCloudAmount`.
- Maps cloud amount to the cloud shader: `cloudcover = -15.0 + cloudAmount * 25.0`
  (the cloud shader treats ~`-20` as clear and ~`5` as fully overcast).
- The `TextureRect`'s texture is the **sky gradient**; the cloud shader composites clouds
  over it and applies a perspective skew (see [Shaders](#shaders)).

### `panel_rain_falling_in_sky.gd` — falling rain
**File:** [`../Weather2D/scene/panel_rain_falling_in_sky.gd`](../Weather2D/scene/panel_rain_falling_in_sky.gd) · `@tool extends Panel`

- Connects `updateRainAmount` → `setRainAmount`.
- Maps rain to the rain/snow shader's line count:
  `count = clampi(rainAmount * 300, 0, 10000)`.

### `panel_raindrops_on_screen.gd` — raindrops on the lens
**File:** [`../Weather2D/scene/panel_raindrops_on_screen.gd`](../Weather2D/scene/panel_raindrops_on_screen.gd) · `@tool extends Panel`

- Connects `updateRainAmount` → `setRainAmount`.
- Maps rain to the drops shader `frequency = clamp(4.0 - rainAmount * 7.0, -3.0, 7.0)`
  (lower `frequency` = more drops, so more rain → more drops).

Both rain panels live under a `CanvasLayer` (`RainController`) parented to the camera, so
they cover the screen regardless of camera movement.

### `MapCamera2D` — camera
**File:** [`../MapCamera2D.gd`](../MapCamera2D.gd) · `class_name MapCamera2D extends Camera2D`

Self-contained pan/zoom/drag camera: mouse-wheel + keyboard zoom (relative to cursor),
edge-of-screen and arrow-key panning, left-drag with inertia, and pinch/pan gesture
support. Independent of the weather system — reusable anywhere.

---

## Shaders

All in [`../Weather2D/shader/`](../Weather2D/shader/), `shader_type canvas_item`.

### `shader_clouds.gdshader`
Drifting clouds via fBm (fractal Brownian motion) 2D noise, composited over the sky
gradient texture. Includes a **perspective-transform vertex stage** (`up_left`,
`up_right`, `down_right`, `down_left`, `plane_size`) so the sky plane can be skewed to
recede toward a horizon. `cloudcover` is the main weather-driven uniform.

### `shader_rain_snow.gdshader`
Screen-space falling streaks. Each of `count` lines is placed and animated with hash
functions; a line **SDF** + `blur` gives soft edges. `slant` tilts the rain and biases its
travel direction; `speed`, `size`, and `colour` tune the look (raise `size`/lower `speed`
for snow).

### `shader_raindrops_on_screen.gdshader`
Samples the **screen texture** and adds refracting raindrops on a grid at multiple scales.
`frequency` controls how many drop sizes are active (driven inversely by rain amount);
`size` sets drop scale. A "poor-man's refraction" offsets the screen sample per drop.

### `shader_water.gdshader`
Reflective 2D water on a `ColorRect`/panel below `level`. Distorts and samples the
**screen texture** to fake reflections, mixes in `water_albedo` by `water_opacity`, and
scrolls noise for waves (`water_speed`, `wave_distortion`, `wave_multiplyer`). An optional
`water_texture_type` adds a stylized surface pattern. Reflection offset uniforms align the
mirrored image. *This is the shader most changed by the [Phase 1 roadmap](ROADMAP.md#phase-1--water-overhaul).*

---

## Scene composition (the demo)

[`../Weather2D/demo-rose-garden.tscn`](../Weather2D/demo-rose-garden.tscn) is assembled by
hand and is the canonical example of wiring:

- **`SkySetting`** instance (from `sky_setting.tscn`) carries the sky `TextureRect`, the
  `MapCamera2D`, a `CanvasModulate` (global tint), a `WorldEnvironment` (glow/bloom), and
  the two rain `Panel`s under the camera's `CanvasLayer`.
- **`Parallax2D`** bands (Godot 4.3+) hold scenery at different `scroll_scale`s: distant
  townscape/villagescape textures, mid-ground rose-bush instances
  (`scene_plant_rosebush_full.tscn`), and a foreground level.
- A **water `ColorRect`** with the water `ShaderMaterial` sits on its own parallax band.
- **`GPUParticles2D`** emit falling petals.

To reuse the system in another project today: instance `sky_setting.tscn`, add your own
scenery under `Parallax2D` layers, and give any effect node the water/rain/cloud materials.
A cleaner addon + code API for this is the subject of
[Phases 0–3](ROADMAP.md).

---

## Data flow summary

1. A slider (or a runtime `delta`) changes `rainAmount` / `cloudAmount` on `SkySetting`.
2. The property **setter emits** `updateRainAmount` / `updateCloudAmount`.
3. Subscribed effect scripts receive the new `0..1` value and **write a shader uniform**.
4. The shader renders the updated effect that frame.
5. Independently, `sunsetRate` advances the sky gradient, and `MapCamera2D` handles view.

The decoupling means **new effects need no changes to `SkySetting`** — a node just joins
the party by connecting to the signal and mapping the value to its own shader.
