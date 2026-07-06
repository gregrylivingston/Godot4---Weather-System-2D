# Godot 4 · Weather System 2D

A **reusable atmosphere kit for 2D Godot scenes** — a shader sky with a sun/moon and day-night cycle, drifting volumetric clouds, rain / snow / fog, reflective water that laps a beach or flows as a river, procedural terrain, and scattered vector props. Assemble a whole scene from code with one builder call — deterministically from a seed — and optionally make it *live*, with the sun tracking across the sky and weather fronts rolling in.

It began as a few-day project for a short anime-style scene and has grown into a **well-documented, code-friendly** kit for dropping atmosphere into other projects.

![Weather System 2D — rain, clouds, and reflective water](https://github.com/user-attachments/assets/930c2468-c58b-4c69-9b0b-86449aad2a6b)

> **Status:** functional and usable today (v0.1.0). Distributed as an installable `addons/weather2d/` plugin — see the [Roadmap](#roadmap) for what's next.
>
> **Docs:** [Getting started](docs/api/getting-started.md) · [API reference](docs/api/reference.md) · [Architecture](docs/ARCHITECTURE.md) · [Roadmap](docs/ROADMAP.md)

---

## Table of contents

- [Features](#features)
- [Requirements](#requirements)
- [Quick start](#quick-start)
- [How it works](#how-it-works)
- [Shaders](#shaders)
- [Demos](#demos)
- [Roadmap](#roadmap)
- [Known limitations](#known-limitations)
- [Credits & license](#credits--license)

---

## Features

- **Build scenes from code** — one [`WeatherScene`](addons/weather2d/api/weather_scene.gd) builder call assembles sky + terrain + water + props into a ready node tree, **deterministically from a seed**.
- **Living atmosphere** — opt-in [`.live()`](#new-living-scenes-phase-5) adds a `SkyController`: a **day-night cycle** (the sun/moon tracks, the sky palette shifts, stars come out), **weather transitions** (roll a storm in), and **lightning** — all frame-rate independent.
- **Unified sun model** — one sun position + color drives the sky glow & disc, the lit side of the clouds, and the water glint together, so a scene reads as lit by *one* light.
- **Shader sky** with a sun/moon disc, glow, and twinkling night stars.
- **Volumetric clouds** with six style presets, sun-lit edges, wind drift, and **cast shadows** dappling the land & water.
- **Configurable water** (`WaterBody2D`) — **still / river / ocean-beach** modes with foam, run-up, reflections, sun glint, and rain ripples; reacts to weather.
- **Procedural terrain** (`TerrainBand2D`) — seeded mountains / hills / treeline silhouettes and a sand ground that shares a coastline with the water.
- **Rain / snow / fog** overlays and **wind** that slants the rain and sways the foliage.
- **Vector prop scatter** (`PropScatter2D`) — seeded, stratified trees / rocks / birds with depth haze, sway, and flight.
- **Painterly post-process** — soft focus, grain, vignette.
- **Full-featured 2D map camera** (`MapCamera2D`) with mouse / keyboard / gesture pan, zoom, and drag-with-inertia.
- **Editor-live** — the nodes are `@tool` scripts, so you preview changes right in the editor — plus a zero-dependency headless test suite.

## Requirements

- **Godot 4.7** (developed and tested on 4.7, Forward+). No `Parallax2D` or other bleeding-edge nodes are required, so recent 4.x builds should work too.
- No external dependencies or GDExtension — pure GDScript + shaders.

## Quick start

1. Clone the repo and open the folder as a Godot project (`project.godot`).
2. Press **Play** — the main scene is the **[launcher](demos/launcher.tscn)**: pick a **scenario** (Beach / Small Island / River / Lake / Mountains), then set the **time of day** (Dawn / Noon / Golden Hour / Dusk / Night), the **weather** (Clear / Cloudy / Foggy / Rainy / Stormy / Snowy), and the **clouds** (Wispy / Scattered / Cumulus / Overcast / Stormy, or *Auto*) — all independent axes, so you can do *golden hour + storm clouds* or *dusk + cumulus*. Drag **rain / fog / wind**, toggle **snow** / props / birds / painterly. Everything rebuilds live and reproducibly from a seed. It's the fastest way to see what the kit can do.

To use it in your own project, copy the [`addons/weather2d/`](addons/weather2d/) folder in and tick it on under **Project → Project Settings → Plugins**, then build a scene from code (below) or drop the nodes in by hand.

### The `WaterBody2D` node *(Phase 1)*

The reworked water lives in the addon at [`addons/weather2d/`](addons/weather2d/). Open [`demos/water_demo.tscn`](demos/water_demo.tscn) to try it, or add a `WaterBody2D` node yourself — it owns its material, so it works with no setup:

```gdscript
var water := WaterBody2D.new()
water.mode = WaterBody2D.Mode.OCEAN_BEACH   # or STILL / RIVER
water.size = Vector2(1920, 540)
water.level = 0.55                          # waterline (0 top … 1 bottom)
water.foam_amount = 0.6
add_child(water)
```

Modes: **Still** (pond, ripples + reflections), **River** (surface streams along `flow_direction`, sits behind scenery), **Ocean-Beach** (an animated waterline laps up the shore with a foam band). Rolling **sine waves** (`wave_height` / `wave_frequency`) undulate the surface, and — when `react_to_weather` is on — rain from a `SkyController` (via the `"SkySetting"` group) darkens the water and kicks up more foam and bigger waves. Palette, waves, flow, foam, run-up and reflection are all inspector- and code-tweakable. To enable the addon in your own project, copy the `addons/weather2d/` folder in and tick it on under **Project → Project Settings → Plugins**.

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
builder.time_of_day(TimeOfDay.golden_hour())     # Dawn / Noon / Golden Hour / Dusk / Night
builder.weather(WeatherPreset.stormy())          # Clear / Cloudy / Foggy / Rainy / Stormy / Snowy
builder.cloud_style(CloudPreset.cumulus())       # Wispy / Scattered / Cumulus / Overcast / Stormy
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
add_child(Scenarios.build("River", {"seed": 7, "time_of_day": TimeOfDay.dusk(), "weather": WeatherPreset.rainy()}).build())
```

Scenarios: **Beach, Small Island, River, Lake, Mountains** — the same ones the launcher exposes.

### New: living scenes *(Phase 5)*

By default a built scene is a static composite. Call [`.live()`](addons/weather2d/api/weather_scene.gd) and the builder adds a [`SkyController`](addons/weather2d/nodes/sky_controller.gd) that animates the whole atmosphere at runtime — the sun tracks across the sky and the palette shifts through a **day-night cycle**, clouds drift with the wind and cast **moving shadows**, the water **glints** under the sun and **ripples** in the rain, and you can roll one weather front into another:

```gdscript
var scene := WeatherScene.new() \
    .time_of_day(TimeOfDay.golden_hour()) \
    .weather(WeatherPreset.clear()) \
    .terrain([TerrainLayer.mountains(), TerrainLayer.hills(), TerrainLayer.ground()]) \
    .water(WaterBody2D.Mode.OCEAN_BEACH) \
    .live(true, 0.01)   # animate; 0.01 = a slow day-night cycle (days per second)
    .lightning(true)    # storms flash
add_child(scene.build())

# Later, roll a storm in over 8 seconds:
var ctrl := scene.build().get_node("SkyController") as SkyController
ctrl.transition_to(WeatherPreset.stormy(), 8.0)
```

The controller joins the `"SkySetting"` group and emits `updateRainAmount` / `updateCloudAmount`, so a `WaterBody2D` (and any legacy subscriber) reacts to it exactly as it would to the classic `SkySetting` hub. All motion is scaled by frame `delta`, so it runs the same at any FPS. The launcher's **Animate**, **Lightning**, and **Day–night speed** controls drive this live.

The kit ships a hybrid art pipeline: **`PropScatter2D`** deterministically scatters vector props (trees, palms, bushes, rocks, flowers, driftwood, birds — the SVGs in [`assets/svg/`](assets/svg/)) with even **stratified** placement, ground **shadows**, and **animation** (trees sway in the wind, birds fly across the sky — via `foliage_wind` / `bird_fly` shaders). The builder plants props **per terrain layer**, so back layers get small, hazy trees and near layers get big, crisp ones. **`PainterlyLayer`** adds a soft-focus + grain + vignette post-process. Weather adds `.rain()` / `.snow()` (`rain.gdshader`), `.fog()` (`fog.gdshader`), `.clouds()` (`clouds.gdshader`), and `.wind()` (sway + slant) — all reachable from the launcher.

### Tests

A zero-dependency headless suite lives in [`tests/`](tests/) (**95 checks, all passing** on Godot 4.7 — the node logic, the builder, determinism, presets, and the Phase 5 sun model / day-night cycle / `SkyController`). Run it from the project root:

```bash
godot --headless --path . --script res://tests/run_tests.gd
```

It checks the node logic (property → shader wiring, mode enum, weather response, terrain factories/shader selection) and exits non-zero on failure. Visual/shader correctness is verified in the demo scenes — see [`tests/README.md`](tests/README.md).

## How it works

A scene is assembled by the **`WeatherScene` builder**, not authored by hand. You describe the scene declaratively — time of day, weather, cloud style, terrain stack, water mode, props — and `build()` returns a ready `Node2D` tree (sky, clouds, terrain bands, water, overlays, camera), deterministic for a given seed.

For a **living** scene (`.live()`), the builder also adds a **`SkyController`** — the runtime hub. It holds the current `TimeOfDay` + `WeatherPreset`, advances the day-night cycle and any weather transition each frame (scaled by frame `delta`, so it's FPS-independent), and pushes the results into every material. It joins the `"SkySetting"` group and emits `updateRainAmount` / `updateCloudAmount`; effect nodes like `WaterBody2D` subscribe by looking the controller up in that group (`get_tree().get_first_node_in_group("SkySetting")`) and map the `0..1` value onto their own shader uniforms — so weather stays decoupled from the effects.

```
WeatherScene.build()  ─►  Node2D tree: Camera2D · Sky · Clouds · Terrain bands · Water ·
                          CloudShadow · Fog · Rain · (Painterly) · SkyController*   (*if .live())

SkyController  (group "SkySetting")
│  state:  TimeOfDay (sun, palette, stars) + WeatherPreset (rain / fog / cloud / wind)
│  step(delta):  day-night cycle · weather cross-fade · lightning
│  emits:  updateRainAmount, updateCloudAmount
│
├─ pushes uniforms ─► sky / clouds / cloud_shadow / fog / rain materials + water glint
└─ updateRainAmount ─► WaterBody2D  → darkens water, raises foam/waves, rain ripples
```

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for a full breakdown of the resources, nodes, builder, and value→uniform mappings.

## Shaders

The reworked kit ships its canvas-item shaders in [`addons/weather2d/shaders/`](addons/weather2d/shaders/). These are the current, addon-canonical effects driven by the `WeatherScene` builder and the addon nodes:

| Shader | Purpose | Key uniforms |
|---|---|---|
| [`sky`](addons/weather2d/shaders/sky.gdshader) | Sky gradient with a **sun/moon disc + glow** and **twinkling night stars**, from the unified sun model | `sky_top`/`sky_bottom`, `sun_uv`, `sun_color`, `sun_size`/`sun_glow`, `star_intensity` |
| [`water_body`](addons/weather2d/shaders/water_body.gdshader) | Mode-driven water (still / river / ocean-beach) — depth shading, sine-wave surface, foam band, run-up, screen reflections, **sun glint** & **rain-ripple impacts** | `mode`, `level`, `deep_color`/`shallow_color`, `wave_height`/`wave_frequency`, `flow_direction`, `foam_amount`, `swell_height`, `sun_uv`/`glint_strength`, `rain_ripple` |
| [`clouds`](addons/weather2d/shaders/clouds.gdshader) | Layered fBm + ridged-detail volumetric clouds with lit tops / shadowed bases, a horizon perspective, **sun-direction lighting** and **wind drift** | `coverage`, `cloud_scale`, `density`, `softness`, `detail`, `cloud_dark`/`cloud_light`, `cloud_color`, `sun_uv`/`sun_tint`, `wind_dir` |
| [`cloud_shadow`](addons/weather2d/shaders/cloud_shadow.gdshader) | Soft moving cloud shadows dappling the land & water, drifting with the wind | `coverage`, `wind_dir`, `shadow_color`, `strength`, `horizon` |
| [`rain`](addons/weather2d/shaders/rain.gdshader) | Falling rain / snow overlay (snow toggled by `snow`) with wind-driven slant | `amount`, `snow`, `slant` |
| [`fog`](addons/weather2d/shaders/fog.gdshader) | Distance-haze / fog wash over the scene | `density`, `fog_color` |
| [`terrain_silhouette`](addons/weather2d/shaders/terrain_silhouette.gdshader) | Seeded noise silhouettes (hills / mountains / treeline) with atmospheric haze | `roughness`, `seed`, `near_color`/`far_color` |
| [`terrain_ground`](addons/weather2d/shaders/terrain_ground.gdshader) | Sand / ground with grain and a dry→wet gradient, sharing the water's analytic coastline | `coast_level`, `wave_height`/`wave_frequency`, grain/wetness params |
| [`foliage_wind`](addons/weather2d/shaders/foliage_wind.gdshader) | Per-sprite wind sway for scattered trees/bushes (each out of phase) | `sway_strength`, `sway_speed` |
| [`bird_fly`](addons/weather2d/shaders/bird_fly.gdshader) | Drift + bob + wing-flap animation for scattered birds | flap/bob params |
| [`painterly`](addons/weather2d/shaders/painterly.gdshader) | Soft-focus blur + warmth + paper grain + vignette post-process | blur, grain, vignette |

## Demos

Four scenes under [`demos/`](demos/), each a good reference:

- **[`launcher.tscn`](demos/launcher.tscn)** *(main scene)* — the interactive playground: pick a scenario, time of day, weather and cloud style; drag rain / fog / wind; toggle snow / props / birds / painterly / **animate** — everything rebuilds live.
- **[`generated_demo.tscn`](demos/generated_demo.tscn)** — a whole scene built entirely from code in `_ready()` (nothing authored in the `.tscn`), running a slow **day-night cycle** with lightning.
- **[`beach_demo.tscn`](demos/beach_demo.tscn)** — mountains → hills → sand → ocean-beach water washing over the shore, showing the shared coastline.
- **[`water_demo.tscn`](demos/water_demo.tscn)** — the three `WaterBody2D` modes side by side.

## Roadmap

The next phases turn this from a personal effects grab-bag into a polished, reusable atmosphere kit. Full detail in [`docs/ROADMAP.md`](docs/ROADMAP.md).

- [x] **Phase 0 — Foundation & docs**
  - Accurate README, architecture reference, and this roadmap.
  - Repackaged as an installable `addons/weather2d/` plugin; legacy rose-garden code removed and the repo tidied.
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
  - Live weather wiring landed in Phase 5 (`.live()` + `SkyController`).
  - *Remaining:* serialize a built scene back to a `ScenePreset`.
- [ ] **Phase 4 — Presentation & release** ✨ *(started)*
  - ✅ [Getting-started tutorial](docs/api/getting-started.md) + [API reference](docs/api/reference.md), `CONTRIBUTING.md`, icon, and v0.1.0 tagged.
  - *Remaining:* GIFs/video of the launcher + scenarios, a performance pass, and a Godot **Asset Library** submission.
- [x] **Phase 5 — Living simulation & atmosphere depth** 🌦️ *(core done)*
  - Makes the atmosphere feel *simulated* rather than *composited*. Enabled per-scene with
    [`.live()`](#new-living-scenes-phase-5); full detail in
    [`docs/ROADMAP.md`](docs/ROADMAP.md#phase-5--living-simulation--atmosphere-depth).
  - **Sky:** a sky **shader** with a **sun/moon disc + glow**, **twinkling stars** at night,
    and a **day-night cycle** that interpolates `TimeOfDay` over time.
  - **Clouds:** **sun-direction lighting**, **wind-driven drift**, and **cast cloud shadows**
    on land/water. *(Remaining: parallax cloud layers, god rays.)*
  - **Weather:** a runtime **`SkyController`** that **cross-fades between presets** over time,
    **lightning** for storms, and coupling so **wind drives cloud drift**. *(Remaining:
    thunder audio, wet-surface darkening, puddles.)*
  - **Water:** **sun glint** and **rain-ripple impacts**. *(Remaining: caustics, live
    wet-sand edge.)*
  - **Plumbing:** generated scenes now get a live `SkyController` (in the `"SkySetting"`
    group) so `WaterBody2D.react_to_weather` animates, and all motion is scaled by frame
    `delta` (frame-rate independent).

## Known limitations

Called out honestly so contributors know where the sharp edges are (see [`docs/ROADMAP.md`](docs/ROADMAP.md#known-issues--tech-debt) for fixes):

- **Generated scenes are static unless you opt in** — a plain `WeatherScene.build()` composites a fixed weather look (each material is set once). Call [`.live()`](#new-living-scenes-phase-5) to add a `SkyController` that animates the sky/weather/water and drives `WaterBody2D.react_to_weather`.
- **Clouds are a single layer** — no parallax between high and low cloud decks yet (Phase 5 follow-up), and there are no god rays.
- **No caustics or live wet-sand edge** — the sand's dry→wet blend is a static gradient rather than following the water's animated run-up (Phase 1 carry-overs).

## Credits & license

Licensed under the terms in [`LICENSE`](LICENSE).

The kit's shaders were written for this project, drawing on techniques shared by the excellent [godotshaders.com](https://godotshaders.com) community — in particular:

- **Clouds** (`clouds.gdshader`) — adapted from [Cloudy skies](https://godotshaders.com/shader/cloudy-skies/).
- **Water reflections** (`water_body.gdshader`) — inspired by [2D water with reflections](https://godotshaders.com/shader/2d-water-with-reflections/).
- **Rain / snow** (`rain.gdshader`) — line-SDF approach akin to [Simple rain/snow](https://godotshaders.com/shader/simple-rain-snow-shader/).

Example video (an early rose-garden build, since replaced by the addon): https://drive.google.com/file/d/1AFCj9rX0jrPF2mGHhBMslishc6YZvUd_/view
