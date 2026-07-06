# Godot 4 · Weather System 2D

A small toolkit of **weather and atmosphere effects for 2D Godot scenes** — rain, drifting clouds, raindrops-on-glass, reflective water, and a controllable day-to-sunset sky. Everything is driven from a single node so you can dial a scene from "clear afternoon" to "downpour at dusk" with a few sliders, or animate it over time.

Originally built over a few days to make a short anime-style scene, it's now being reworked into a **reusable, well-documented, code-friendly atmosphere kit** for dropping into other projects.

![Rainy rose-garden demo](https://github.com/user-attachments/assets/930c2468-c58b-4c69-9b0b-86449aad2a6b)

> **Status:** functional and usable today. Actively being rebuilt — see the [Roadmap](#roadmap) below and [`docs/ROADMAP.md`](docs/ROADMAP.md) for the full plan (better water, built-in terrain, a scene-building code API, and polished docs).

---

## Table of contents

- [Features](#features)
- [Requirements](#requirements)
- [Quick start](#quick-start)
- [How it works](#how-it-works)
- [The `SkySetting` node](#the-skysetting-node)
- [Shaders](#shaders)
- [Demo scene](#demo-scene)
- [Roadmap](#roadmap)
- [Known limitations](#known-limitations)
- [Credits & license](#credits--license)

---

## Features

- **One-node weather control** — a `SkySetting` node exposes simple `0..1` sliders for rain and cloud amount, plus per-frame *delta* values to make weather build or clear over time.
- **Animated sky gradient** with a controllable sunset descent.
- **Drifting volumetric-looking clouds** (2D noise) with an optional perspective skew so the sky recedes toward the horizon.
- **Falling rain / snow** as a screen-space shader (line SDFs), tunable from drizzle to storm.
- **Raindrops-on-the-lens** refraction pass for a "shot through a rainy window" look.
- **Reflective 2D water** with animated distortion and screen reflections.
- **Full-featured 2D map camera** (`MapCamera2D`) with mouse/keyboard/gesture pan, zoom, and drag-with-inertia.
- **Editor-live** — most effects are `@tool` scripts, so you preview changes right in the editor.

## Requirements

- **Godot 4.7+** (the project uses `Parallax2D`, introduced in 4.3, and is currently configured for the 4.7 Forward+ renderer).
- No external dependencies or GDExtension — pure GDScript + shaders.

## Quick start

1. Clone the repo and open the folder as a Godot project (`project.godot`).
2. Press **Play** — the main scene is the **[launcher](demos/launcher.tscn)**: pick a **scenario** (Beach / Small Island / River / Lake / Mountains), a **weather** mood, drag the **rain** slider, and toggle props / birds / painterly. Everything rebuilds live and reproducibly from a seed. It's the fastest way to see what the kit can do.

> Prefer the original hand-authored anime demo? Open [`Weather2D/demo-rose-garden.tscn`](Weather2D/demo-rose-garden.tscn), drag to pan and scroll to zoom (`MapCamera2D`), then select the **`SkySetting`** node and try the inspector sliders: **rainAmount** (`0` dry → `1` heavy), **rainDelta** (rain change per frame), **cloudAmount** / **cloudDelta**, and **sunsetRate**.

To use it in your own scene, instance [`Weather2D/sky_setting.tscn`](Weather2D/sky_setting.tscn) (it carries the sky, camera, and rain layers) and add your own art under parallax layers. A cleaner, addon-style packaging and a code API are on the [roadmap](#roadmap).

### New: the `WaterBody2D` node *(Phase 1)*

The reworked water lives in the addon at [`addons/weather2d/`](addons/weather2d/). Open [`demos/water_demo.tscn`](demos/water_demo.tscn) to try it, or add a `WaterBody2D` node yourself — it owns its material, so it works with no setup:

```gdscript
var water := WaterBody2D.new()
water.mode = WaterBody2D.Mode.OCEAN_BEACH   # or STILL / RIVER
water.size = Vector2(1920, 540)
water.level = 0.55                          # waterline (0 top … 1 bottom)
water.foam_amount = 0.6
add_child(water)
```

Modes: **Still** (pond, ripples + reflections), **River** (surface streams along `flow_direction`, sits behind scenery), **Ocean-Beach** (an animated waterline laps up the shore with a foam band). Rolling **sine waves** (`wave_height` / `wave_frequency`) undulate the surface, and — when `react_to_weather` is on — rain from a `SkySetting` darkens the water and kicks up more foam and bigger waves. Palette, waves, flow, foam, run-up and reflection are all inspector- and code-tweakable. To enable the addon in your own project, copy the `addons/weather2d/` folder in and tick it on under **Project → Project Settings → Plugins**.

### New: terrain bands *(Phase 2)*

`TerrainBand2D` renders one parallax band from a [`TerrainLayer`](addons/weather2d/resources/terrain_layer.gd) resource — **mountains / hills / treeline** as seeded noise silhouettes with atmospheric haze, or a **sand ground** the water can wash over. Sand and water share an analytic **coastline** (`coast_level` + `wave_*`), so the ocean lines up with the land. See [`demos/beach_demo.tscn`](demos/beach_demo.tscn) for mountains → hills → sand → ocean-beach water washing in.

```gdscript
var hills := TerrainBand2D.new()
hills.layer = TerrainLayer.hills()   # or .mountains() / .treeline() / .ground()
hills.size = Vector2(1920, 300)
add_child(hills)
```

### New: build scenes from code *(Phase 3)*

The [`WeatherScene`](addons/weather2d/api/weather_scene.gd) builder assembles a whole scene — sky gradient, parallax terrain bands, and water — into a ready node tree, deterministically from a seed. See [`demos/generated_demo.tscn`](demos/generated_demo.tscn) (nothing is authored in that scene except one script).

```gdscript
var builder := WeatherScene.new()
builder.set_seed(20260705)
builder.weather(WeatherPreset.clear_noon())      # or .overcast_dusk() / .storm()
builder.terrain([
    TerrainLayer.mountains(),
    TerrainLayer.hills(),
    TerrainLayer.ground(),
])
builder.water(WaterBody2D.Mode.OCEAN_BEACH)
builder.props(true, 16)   # scatter SVG trees/rocks along the shore (seeded)
builder.painterly(true)   # soft-focus painterly post-process
add_child(builder.build())
```

Save a whole composition as a [`ScenePreset`](addons/weather2d/resources/scene_preset.gd) `.tres` and rebuild it anywhere with `WeatherScene.new().from_preset(preset).build()`. Or grab a ready-made recipe from [`Scenarios`](addons/weather2d/api/scenarios.gd):

```gdscript
add_child(Scenarios.build("River", {"seed": 7, "weather": WeatherPreset.overcast_dusk(), "rain": 0.6}).build())
```

Scenarios: **Beach, Small Island, River, Lake, Mountains** — the same ones the launcher exposes.

The kit ships a hybrid art pipeline: **`PropScatter2D`** deterministically scatters vector props (trees, palms, bushes, rocks, flowers, driftwood, birds — the SVGs in [`assets/svg/`](assets/svg/)) with even **stratified** placement, **depth-scaling**, **atmospheric haze**, ground **shadows**, and **animation** (trees sway, birds flap — via `foliage_wind` / `bird_fly` shaders); and **`PainterlyLayer`** adds a soft-focus + grain + vignette post-process so the whole frame reads like a soft painting. `.birds()` adds a flock overhead and `.rain(amount)` drops a rain overlay.

### Tests

A zero-dependency headless suite lives in [`tests/`](tests/) (**56 checks, all passing** on Godot 4.7). Run it from the project root:

```bash
godot --headless --path . --script res://tests/run_tests.gd
```

It checks the node logic (property → shader wiring, mode enum, weather response, terrain factories/shader selection) and exits non-zero on failure. Visual/shader correctness is verified in the demo scenes — see [`tests/README.md`](tests/README.md).

## How it works

The system uses a **hub-and-spoke** design built around Godot signals:

```
                       SkySetting  (Node2D, @tool, group "SkySetting")
                       ┌───────────────────────────────────────────┐
   inspector sliders → │ rainAmount / rainDelta                     │
                       │ cloudAmount / cloudDelta                   │
                       │ sunsetRate                                 │
                       └──────┬──────────────────┬─────────────────┘
                              │ updateRainAmount  │ updateCloudAmount   (signals)
             ┌────────────────┼──────────┐        │
             ▼                ▼           ▼        ▼
   panel_rain_falling   panel_raindrops   (…)   sky.gd  → cloud shader (cloudcover)
     → rain shader        → drops shader              (TextureRect w/ gradient)
       (count)              (frequency)
```

1. **`SkySetting`** holds the weather state. When `rainAmount` or `cloudAmount` change (including via their per-frame `delta`), it **emits a signal**.
2. **Effect nodes subscribe** to that signal by looking `SkySetting` up in the global group `"SkySetting"` (`get_tree().get_first_node_in_group("SkySetting")`), then map the incoming `0..1` value onto the appropriate **shader parameter**.
3. Each visible effect is a `Panel` / `TextureRect` / `ColorRect` with a **`ShaderMaterial`**. The GDScript only translates weather values into shader uniforms — all the visuals live in the shaders.

This keeps the controller decoupled from the effects: any node can opt in to weather updates just by connecting to the signal, and you can add new effects without touching `SkySetting`.

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for a full node-by-node breakdown, the exact value→uniform mappings, and data-flow notes.

## The `SkySetting` node

[`Weather2D/sky_setting.gd`](Weather2D/sky_setting.gd) — a `@tool Node2D` in the `"SkySetting"` group.

| Property | Range | Meaning |
|---|---|---|
| `rainAmount` | `-1 … 2` | Rain intensity. `0` = none, `1` = max. Values outside `0..1` create a delay before a delta of the opposite sign takes visible effect. Setting it **emits `updateRainAmount`**. |
| `rainDelta` | `-1 … 1` | Rain change applied every frame at runtime (`rainAmount += rainDelta/100`). Positive rains harder, negative clears. |
| `cloudAmount` | `-1 … 2` | Cloud cover. Setting it **emits `updateCloudAmount`**. |
| `cloudDelta` | `-0.1 … 0.1` | Cloud cover change per frame at runtime. |
| `sunsetRate` | `0 … 0.25` | How fast the sky gradient slides toward sunset (shifts the gradient's `fill_to`). |

At runtime `_process()` applies the deltas and advances the sunset; in the editor the deltas are frozen so you can author a static look.

## Shaders

All four visual effects are canvas-item shaders in [`Weather2D/shader/`](Weather2D/shader/):

| Shader | Purpose | Key uniforms |
|---|---|---|
| [`shader_clouds`](Weather2D/shader/shader_clouds.gdshader) | Drifting fBm clouds over the sky gradient, with a perspective-skew vertex stage | `cloudcover`, `cloudscale`, `speed`, `skytint` |
| [`shader_rain_snow`](Weather2D/shader/shader_rain_snow.gdshader) | Falling rain/snow streaks (line SDFs) | `count`, `slant`, `speed`, `blur`, `size` |
| [`shader_raindrops_on_screen`](Weather2D/shader/shader_raindrops_on_screen.gdshader) | Raindrop refraction over the screen texture | `frequency`, `size` |
| [`shader_water`](Weather2D/shader/shader_water.gdshader) | Reflective water with animated distortion | `level`, `water_albedo`, `water_speed`, `wave_distortion` |

## Demo scene

[`Weather2D/demo-rose-garden.tscn`](Weather2D/demo-rose-garden.tscn) shows a full assembled scene: stacked `Parallax2D` bands of scenery, instanced rose bushes, `GPUParticles2D` falling petals, a reflective-water `ColorRect`, and the `SkySetting` hub wired to rain/cloud effects. It's a good reference for how the pieces fit together.

## Roadmap

The next phases turn this from a personal effects grab-bag into a polished, reusable atmosphere kit. Full detail in [`docs/ROADMAP.md`](docs/ROADMAP.md).

- [x] **Phase 0 — Foundation & docs** *(in progress)*
  - Accurate README, architecture reference, and this roadmap.
  - Repackage as an installable `addons/` plugin; tidy repo layout.
- [x] **Phase 1 — Water overhaul** 🌊 *(core done)*
  - `WaterBody2D` node with `still / river / ocean-beach` modes.
  - Shoreline **foam**, depth shading, **flowing river**, **beach-lapping** run-up.
  - Rolling **sine-wave** surface action; **weather-reactive** tint (rain darkens water).
  - *Remaining:* shared shader includes, live wet-sand edge, caustics.
- [x] **Phase 2 — Terrain built in** ⛰️ *(core done)*
  - Procedural **sand / ground** shader (grain + dry→wet gradient).
  - Generated **hills, mountains, and tree lines** as seeded noise silhouettes with haze.
  - `TerrainLayer` resource + `TerrainBand2D` node; sand ↔ water share a coastline so the ocean washes in.
  - Painterly noise, SVG vector props (`assets/svg/`) + seeded `PropScatter2D`, and a `PainterlyLayer` post-process.
- [x] **Phase 3 — Scene generation from code** 🧩 *(core done)*
  - A GDScript **`WeatherScene` builder** that assembles sky + terrain + water into a node tree.
  - Reusable `WeatherPreset` / `ScenePreset` resources and **deterministic seeds**.
  - *Remaining:* serialize nodes back to presets; wire generated scenes to `SkySetting` weather; deeper API docs.
- [ ] **Phase 4 — Presentation & release** ✨
  - Several themed demos (rose garden, beach, river valley, mountains), GIFs/video, API docs.
  - Godot **Asset Library** submission.

## Known limitations

Called out honestly so contributors know where the sharp edges are (see [`docs/ROADMAP.md`](docs/ROADMAP.md#known-issues--tech-debt) for fixes):

- **Legacy water** ([`shader_water`](Weather2D/shader/shader_water.gdshader), still used by the rose-garden demo) is screen-reflection only — no shoreline, foam, or flow. The new [`WaterBody2D`](addons/weather2d/) (Phase 1) replaces it for new scenes; migrating the old demo to it is pending.
- **Terrain is hand-placed PNGs** — there's no procedural terrain or water/land interaction yet. (Phase 2.)
- **No code API** — scenes are authored by hand in the editor. (Phase 3.)
- **Frame-rate-dependent weather** — deltas are applied per frame, not scaled by `delta`, so weather changes faster at higher FPS.
- **`sunsetRate` mutates a shared gradient resource** in memory, so a run's ending sky state can leak into the next run.
- The demo `.tscn` is large (embedded data) and could be slimmed.

## Credits & license

Licensed under the terms in [`LICENSE`](LICENSE).

Four shaders were adapted from the excellent [godotshaders.com](https://godotshaders.com) community:

1. **Water** — https://godotshaders.com/shader/2d-water-with-reflections/
2. **Falling rain/snow** — https://godotshaders.com/shader/simple-rain-snow-shader/
3. **Raindrops on screen** — https://godotshaders.com/shader/rain-drops-on-screen-notexture/
4. **Clouds** — https://godotshaders.com/shader/cloudy-skies/

Example-use video: https://drive.google.com/file/d/1AFCj9rX0jrPF2mGHhBMslishc6YZvUd_/view
