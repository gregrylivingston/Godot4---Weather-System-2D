# Roadmap — Weather System 2D

This document is the detailed plan for turning the project from a personal effects
collection into a **reusable, well-documented 2D atmosphere kit** with better water,
built-in terrain, a code API for generating scenes, and polished presentation.

It expands on the summary in the [README](../README.md#roadmap). Phases are ordered by
dependency but can overlap. Each phase lists **goals**, **deliverables**, and
**definition of done**.

---

## Guiding principles

1. **Reusable first.** Anything we build should drop into another Godot project with
   minimal wiring. Prefer an `addons/weather2d/` plugin layout and self-contained nodes.
2. **Code *and* editor.** Every capability should be reachable two ways: a polished
   `@tool` node/inspector for hand-authoring, and a GDScript API for procedural scenes.
3. **Calm, pleasing, stylized.** Art direction is soft, painterly, relaxing — not
   photoreal. Shaders + hybrid SVG vector assets.
4. **Deterministic.** Given a seed + preset, a scene should regenerate identically.
5. **Documented as we go.** No feature is "done" until it's in the docs with an example.

---

## Repository layout

The kit lives in an addon; demos, assets, docs and tests sit alongside it:

```
addons/weather2d/
  plugin.cfg
  plugin.gd
  nodes/            # SkyController, WaterBody2D, TerrainBand2D, PropScatter2D, PainterlyLayer
  shaders/          # sky, clouds, cloud_shadow, water_body, rain, fog, terrain_*, foliage_wind, bird_fly, painterly
  resources/        # TimeOfDay, WeatherPreset, CloudPreset, TerrainLayer, ScenePreset
  api/              # builder (WeatherScene) + Scenarios recipes
assets/
  svg/              # vector props (trees, rocks, grass, flowers, driftwood, birds)
demos/
  launcher.tscn · generated_demo.tscn · beach_demo.tscn · water_demo.tscn
docs/
  ARCHITECTURE.md · ROADMAP.md
tests/
  run_tests.gd · README.md
MapCamera2D.gd      # reusable standalone camera (root)
```

---

## Phase 0 — Foundation & docs  ✅ *done*

**Goal:** an honest, clear baseline that new contributors (and future-us) can build on.

**Deliverables**
- [x] Rewritten `README.md` explaining what the project is and how it works.
- [x] `docs/ARCHITECTURE.md` — resource/node/builder breakdown and data flow.
- [x] `docs/ROADMAP.md` — this document.
- [x] Convert to an installable plugin (`addons/weather2d/plugin.cfg` + `plugin.gd`).
      Node types register via `class_name` (no `add_custom_type` needed).
- [x] Remove the legacy `Weather2D/` rose-garden code (superseded by the addon); tidy the repo.
- [ ] Add screenshots/GIFs to `docs/` and the README.

**Definition of done:** repo opens cleanly, docs match reality, and the effects are
usable as an addon from a fresh project. *(Only media capture remains.)*

---

## Phase 1 — Water overhaul  🌊

**Goal:** water that reads as *flowing rivers* and *ocean lapping on a beach*, not just a
reflective rectangle.

**Design:** replace the single `ColorRect` + screen-reflection shader with a configurable
**`WaterBody2D`** node backed by a mode-driven shader set:

- **`still`** — ponds/lakes; gentle ripples + reflections (evolves current shader).
- **`river`** — a **flow map** (direction + speed) advects layered noise so the surface
  visibly streams in a direction; supports bends. Sits *behind* scenery layers.
- **`ocean-beach`** — an animated **waterline / run-up** that laps up a sand slope, with
  **foam** where water meets land driven by a shoreline mask (distance field against the
  terrain height/mask from Phase 2).

**Sub-tasks**
- [x] `WaterBody2D` node with `mode`, `level`, `flow_direction`, `flow_speed`, foam, tint,
      and reflection params; `@tool` live preview; self-owned material + noise.
- [x] `water_body.gdshader` with the three modes in one shader.
- [x] Foam band: edge-distance from the waterline → broken, animated foam.
- [x] Depth shading: shallow→deep color mix by shoreline distance.
- [x] River flow: directional UV advection with a two-sample noise to hide tiling.
- [x] Beach run-up: time-animated waterline (`swell_height` / `swell_speed`).
- [x] Rolling sine-wave surface action (`wave_height` / `wave_frequency`), applied to the
      still/ocean waterline and as streaming ripples on rivers.
- [x] Hook water tint/brightness to `SkySetting` (rain darkens/roughens water) via
      `react_to_weather` / `weather_influence`.
- [x] Shared analytic **coastline** with the sand ground (`coast_level` + `wave_*`) so land
      and water align — a simpler, exact alternative to a runtime `terrain_mask` texture.
- [x] `terrain_mask` uniform stubbed in for advanced (non-horizontal) coastlines.
- [ ] Extract shared water helpers (noise, reflection) into a reusable `.gdshaderinc`.
- [ ] Wet-sand blend driven by the water's *live* edge (currently a static gradient on sand).
- [ ] Caustics/sparkle pass (optional, cheap) for sunlit water.

**Definition of done:** a river demo where water flows behind hills, and a beach demo
where waves lap onto sand with foam — both tweakable live in the inspector.

---

## Phase 2 — Terrain built in  ⛰️

**Goal:** terrain the water can interact with — sand with ocean washing into it, a river
layer flowing behind a landscape, and parallax mountains/hills/trees behind it all, in a
calm stylized look. Generated from **shaders + hybrid SVG vector assets**.

**Design**
- A **`TerrainLayer`** resource describes one parallax band: silhouette source (noise
  profile *or* SVG), palette/gradient, scroll scale, and role (`ground`, `hill`,
  `mountain`, `treeline`, `foreground`).
- A **height/mask** for the ground layer is shared with `WaterBody2D` so the shoreline and
  wet-sand effects line up with the actual land.
- **Procedural** parts (sand grain, ground gradient, distant hill silhouettes, atmospheric
  haze) come from shaders/noise. **Vector props** (trees, rocks, grass tufts, flowers) are
  authored as **SVG** and imported as crisp, scalable textures, then scattered.

**Sub-tasks**
- [x] Sand/ground shader (`terrain_ground.gdshader`): grain, dry→wet color gradient, wavy
      beach line.
- [x] Noise-driven hill/mountain/treeline silhouette shader (`terrain_silhouette.gdshader`),
      seeded and self-contained (analytic value noise, no texture needed).
- [x] Atmospheric perspective: `far_color` haze at the ridge → `near_color` at the base.
- [x] `TerrainLayer` resource (+ factory presets) and a `@tool` `TerrainBand2D` node that
      renders from it.
- [x] Align ground ↔ water via a shared analytic coastline (`beach_demo.tscn` shows the
      ocean washing over the sand). Closes the loop with Phase 1.
- [x] SVG prop library in `assets/svg/` (round/pine/palm trees, bush, rock, grass, flower,
      driftwood, bird — with soft gradient shading).
- [x] Scatter system: `PropScatter2D` — stratified placement with depth-scaling and
      atmospheric haze; layered same-role terrain bands for background depth.
- [x] Painterly art pass: smooth quintic/domain-warped noise + `PainterlyLayer` post-process.
- [x] Animated props: foliage sway (wind-driven) + birds that fly across the sky; shadows.
- [x] Layer-anchored prop distribution — props planted per terrain layer, sized by depth.
- [x] Time of day + weather as separate axes; volumetric `CloudPreset` clouds (6 styles),
      fog, snow, wind.
- [ ] Density-map placement (paint where props go) instead of uniform stratification.

**Definition of done:** a landscape assembled from `TerrainLayer` bands (procedural hills +
scattered SVG trees) with a river/ocean layer correctly interacting with the ground.

---

## Phase 3 — Scene generation from code  🧩

**Goal:** build good-looking scenes programmatically so the kit is easy to reuse in other
projects (the "generate with code" requirement), while keeping editor authoring.

**Design:** a fluent **builder API** plus **preset resources**.

```gdscript
var scene := WeatherScene.new()
scene.seed = 1234
scene.sky(preset = WeatherPreset.OVERCAST_DUSK)
scene.terrain([
    TerrainLayer.mountains(tint = Color("#6b7a8f")),
    TerrainLayer.hills(),
    TerrainLayer.treeline(density = 0.6),
])
scene.water(WaterBody2D.Mode.OCEAN_BEACH, level = 0.4)
scene.weather(rain = 0.7, rain_delta = 0.1, clouds = 0.8)
add_child(scene.build())
```

**Sub-tasks**
- [x] `WeatherScene` builder returning a ready-to-add node tree (sky + terrain + water).
- [x] `WeatherPreset` resource (rain/cloud/sunset + palette) with `clear_noon` /
      `overcast_dusk` / `storm` factories.
- [x] `ScenePreset` capturing a whole composition; `WeatherScene.from_preset()` rebuilds it.
- [x] Deterministic seeding threaded through the terrain bands (verified by tests).
- [x] `demos/generated_demo.tscn` — a scene generated entirely from code in `_ready()`.
- [x] Live weather wiring into generated scenes (`.live()` + `SkyController`, Phase 5).
- [x] Longer-form API docs under [`docs/api/`](api/reference.md).
- [ ] Keep `@tool` inspector parity — nodes can serialize *back* to a `ScenePreset`.

**Definition of done:** a demo scene generated entirely in `_ready()` from a preset + seed,
reproducible across runs. ✅

---

## Phase 4 — Presentation & release  ✨

**Goal:** make it genuinely impressive on the public profile and easy for others to adopt.

**Sub-tasks**
- [x] Interactive **launcher** (`demos/launcher.tscn`) — the main scene: switch scenarios,
      weather, rain, and toggles live. The easiest way to explore the kit.
- [x] Themed scenarios: Beach, Small Island, River, Lake, Mountains (via `Scenarios`).
- [x] `CHANGELOG.md`.
- [x] API reference + "make your first scene" tutorial in [`docs/api/`](api/getting-started.md).
- [x] `CONTRIBUTING.md` and a project icon; **v0.1.0** tagged (`plugin.cfg` + changelog).
- [x] Performance: shader early-outs when effects are off, and a **`low_graphics()`** mode
      (cheap cloud/water/rain/fog paths, skips cloud-shadow + painterly, fewer props).
- [ ] Capture GIFs/short video of the launcher + scenarios; embed in README + docs.
- [ ] Further performance profiling (mobile/web notes, draw-call/overdraw budget).
- [ ] **Godot Asset Library** submission.

**Definition of done:** a fresh user can install the addon, generate a scene in a few lines,
and see polished demos — and the GitHub page looks great.

---

## Phase 5 — Living simulation & atmosphere depth  🌦️ ✅ *core done*

**Goal:** make the atmosphere feel *simulated* rather than *composited*. A plain generated
scene is still a static snapshot; opting in with [code]WeatherScene.live()[/code] adds a
[SkyController] that brings the four domains the kit is really about — **sky, clouds, weather,
water** — to life.

**Design pillar — one sun/moon model.** ✅ [TimeOfDay] now carries `sun_uv` + `sun_color` +
`star_intensity`, derived from the time of day (and animated by the day-night cycle), and
*every* subsystem reads it: the sky glow & disc, the lit side of the clouds, and the water
glint. That shared light is what turns "nice layers" into "one lit world."

### Sky
- [x] Replaced the flat `GradientTexture2D` with a **sky shader** (`sky.gdshader`).
- [x] **Sun / moon disc** with a soft glow, positioned from `sun_uv`.
- [x] **Stars** at night — a cell-hash field that fades in with `star_intensity` and twinkles.
- [x] **Day-night cycle** — `TimeOfDay.cycle(day01)` interpolates the five keyframe factories;
      [SkyController] advances it and re-pushes the palette each frame.

### Clouds
- [x] **Cast cloud shadows** — `cloud_shadow.gdshader` dapples the land & water with soft
      moving shadows tied to coverage, drifting with the wind.
- [x] **Sun-direction lighting** — the sun-facing cloud edge picks up `sun_tint`.
- [x] **Wind drives cloud drift** — `wind_dir` sets the drift direction; wind also speeds the
      cloud evolution via the controller.
- [ ] **Parallax cloud layers** — high thin cirrus + low cumulus at different speeds (still one
      layer).
- [ ] Optional **god rays / crepuscular rays** through gaps at golden hour and dusk.

### Weather
- [x] A runtime **[SkyController]** that **cross-fades between `WeatherPreset`s over time**
      (`transition_to`) — a front rolling in from clear → storm → clearing — without a rebuild.
- [x] **Lightning** for storms: occasional full-screen flash whose cadence scales with the
      storm. *(Thunder audio hook still TODO.)*
- [x] **Frame-rate independence** — the controller scales all motion by frame `delta`.
- [ ] **Cloud cover → precipitation coupling** so rain feels *caused* by the sky (coverage and
      rain are still independent preset fields).
- [ ] **Wet-surface response**: terrain/props darken while it rains and dry out afterward;
      puddle accumulation on flat ground.

### Water
- [x] **Rain-ripple impacts** — concentric expanding rings where drops land, density tied to
      the rain amount (`rain_ripple`).
- [x] **Sun glint / specular streak** aligned with `sun_uv`, shimmering on wave crests and
      faded out at night.
- [ ] **Caustics / sparkle** pass for sunlit shallows (Phase 1 carry-over).
- [ ] **Live wet-sand edge** — drive the sand's dry→wet blend from the water's *actual*
      animated run-up edge, not a static gradient (Phase 1 carry-over).
- [ ] Extract shared water/noise helpers into a `.gdshaderinc` (Phase 1 carry-over).

### Plumbing
- [x] `WeatherScene.live()` adds a **[SkyController]** in the `"SkySetting"` group so
      `WaterBody2D.react_to_weather` animates in generated scenes — closing the Phase 3 gap.
      With `.live()` the cloud/fog/rain/shadow overlays are always instantiated so a weather
      transition can bring them in.
- [x] **Motion tests** — the headless suite exercises the controller's day advance,
      frame-rate independence, weather transition, and signal emission.

### Follow-ups
- [x] **Day-cycle the water palette** — under `.live()` the water's deep/shallow colors now
      interpolate through the day (`WaterBody2D.set_day_palette`, driven by the controller).
- [x] Thread the chosen start time into `day01` (`TimeOfDay.day`) so a day-night scene begins at
      the picked hour.
- [ ] **Parallax cloud layers**, **caustics**, **live wet-sand edge**, **god rays**, **thunder
      audio** — visual polish best tuned with the editor open.

**Definition of done:** ✅ a generated scene where the sun tracks across the sky, clouds cast
moving shadows and drift with the wind, a storm front rolls in with lightning and rain that
ripples the water, and everything reads as lit by the *same* sun — reproducible from a seed
and tweakable live. (Parallax clouds, caustics, god rays and thunder remain as polish.)

---

## Known issues & tech debt

Tracked here so they get fixed inside the phases above rather than forgotten:

| Issue | Where | Fix in |
|---|---|---|
| ~~Generated scenes are a static snapshot — no live `SkySetting`~~ — done: `WeatherScene.live()` adds a frame-rate-independent `SkyController` | `weather_scene.gd`, `sky_controller.gd` | Phase 5 ✅ |
| ~~Water is screen-space reflection only; no shoreline/flow~~ — done (`water_body.gdshader`); caustics remain | `water_body.gdshader` | Phase 5 |
| ~~Terrain is hand-placed PNGs; no procedural generation~~ — done (`TerrainBand2D`) | — | Phase 2 ✅ |
| ~~No code API; scenes authored by hand~~ — done (`WeatherScene`) | — | Phase 3 ✅ |
| ~~Legacy rose-garden code / large hand-authored `.tscn`~~ — removed | — | Phase 0 ✅ |
| Effects look up the controller via a global group (`"SkySetting"`); brittle if absent (guarded, but a null path means no live weather) | subscriber scripts | optional export ref + null-guard |

---

## Milestones (suggested sequencing)

| Milestone | Contents | Phase(s) |
|---|---|---|
| **M0 — Docs & addon skeleton** | README, architecture, roadmap, plugin.cfg | 0 |
| **M1 — Water that flows & laps** | river + ocean-beach modes, foam, `WaterBody2D` | 1 |
| **M2 — Generated terrain** | sand/hills/mountains, SVG props, `TerrainLayer` | 2 |
| **M3 — Scene-from-code** | `WeatherScene` builder, presets, seeds | 3 |
| **M4 — Showcase & release** | demos, media, Asset Library | 4 |
| **M5 — Living simulation** ✅ | unified sun model, day-night cycle, weather transitions, cloud shadows, water glint/ripples | 5 |

*This roadmap is a living document — update checkboxes and notes as work lands.*
