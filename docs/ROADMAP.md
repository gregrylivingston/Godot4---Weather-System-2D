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

## Target repository layout

The current flat layout will migrate toward an addon-friendly structure (Phase 0):

```
addons/weather2d/
  plugin.cfg
  plugin.gd
  nodes/            # SkySetting, WaterBody2D, TerrainLayer, WeatherScene, MapCamera2D
  shaders/          # clouds, rain_snow, raindrops, water_*, sand, terrain
  resources/        # WeatherPreset, ScenePreset, TerrainLayer resources, gradients
  api/              # builder API (WeatherScene, presets), helper singletons
assets/
  svg/              # vector props (trees, rocks, grass tufts) authored as .svg
  textures/         # imported/raster art
demos/
  rose_garden.tscn
  beach.tscn
  river_valley.tscn
  mountains.tscn
docs/
  ARCHITECTURE.md
  ROADMAP.md
  api/              # generated/handwritten API reference
```

Migration is incremental — existing scenes keep working via path/uid updates.

---

## Phase 0 — Foundation & docs  ✅ *in progress*

**Goal:** an honest, clear baseline that new contributors (and future-us) can build on.

**Deliverables**
- [x] Rewritten `README.md` explaining what the project is and how it works.
- [x] `docs/ARCHITECTURE.md` — node-by-node breakdown and data flow.
- [x] `docs/ROADMAP.md` — this document.
- [x] Convert to an installable plugin (`addons/weather2d/plugin.cfg` + `plugin.gd`).
      Node types register via `class_name` (no `add_custom_type` needed).
- [ ] Move the *legacy* `Weather2D/` scripts/shaders/resources into the addon layout and
      fix `uid`/paths — **do this inside the Godot editor** so it rewrites the references
      in `demo-rose-garden.tscn` safely.
- [ ] Add screenshots/GIFs to `docs/` and the README.

**Definition of done:** repo opens cleanly, docs match reality, and the effects are
usable as an addon from a fresh project.

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
- [x] `terrain_mask` uniform stubbed in, ready for the Phase 2 hookup.
- [ ] Extract shared water helpers (noise, reflection) into a reusable `.gdshaderinc`.
- [ ] Wet-sand blend: darken/saturate land within N px of the current waterline
      (needs the Phase 2 terrain mask).
- [ ] Caustics/sparkle pass (optional, cheap) for sunlit water.
- [ ] Hook water tint/brightness to `SkySetting` (rain darkens/roughens water).

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
- [ ] Sand/ground shader: grain, color gradient, wetness input near waterline.
- [ ] Noise-driven hill/mountain silhouette generator (`Line2D`/`Polygon2D` or shader).
- [ ] SVG prop library in `assets/svg/` (a few trees, rocks, grass, flowers).
- [ ] Scatter system: seeded placement of props along a band with density/jitter.
- [ ] Atmospheric perspective: distance-based desaturation/fog per parallax band.
- [ ] `TerrainLayer` resource + `@tool` band node that renders from it.
- [ ] Wire ground mask → water shoreline (closes the loop with Phase 1).

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
- [ ] `WeatherScene` builder returning a ready-to-add node tree.
- [ ] `WeatherPreset` resource (rain/cloud/sunset + palette) with a starter library.
- [ ] `ScenePreset` capturing a whole composition (terrain bands + water + sky).
- [ ] Deterministic seeding threaded through terrain scatter and water phase.
- [ ] Keep `@tool` inspector parity — nodes can serialize back to presets.
- [ ] Small API examples for each entry point.

**Definition of done:** a demo scene generated entirely in `_ready()` from a preset + seed,
reproducible across runs, documented in `docs/api/`.

---

## Phase 4 — Presentation & release  ✨

**Goal:** make it genuinely impressive on the public profile and easy for others to adopt.

**Sub-tasks**
- [ ] Themed demos: `rose_garden`, `beach`, `river_valley`, `mountains`.
- [ ] Capture GIFs/short video per demo; embed in README + docs.
- [ ] API reference in `docs/api/` and a short "make your first scene" tutorial.
- [ ] Performance pass (particle counts, shader cost, mobile/web notes).
- [ ] Versioned release + **Godot Asset Library** submission.
- [ ] `CHANGELOG.md` and contribution guide.

**Definition of done:** a fresh user can install the addon, generate a scene in a few lines,
and see polished demos — and the GitHub page looks great.

---

## Known issues & tech debt

Tracked here so they get fixed inside the phases above rather than forgotten:

| Issue | Where | Fix in |
|---|---|---|
| Weather deltas are frame-rate dependent (`+= delta/100` not scaled by frame `delta`) | `sky_setting.gd` `_process` | Phase 1/3 refactor |
| `sunsetRate` mutates the shared `Gradient2D_Sky.tres` in memory; end state leaks between runs | `sky_setting.gd` | Phase 1 (own the gradient per-instance) |
| Water is screen-space reflection only; no shoreline/flow | `shader_water.gdshader` | Phase 1 |
| Terrain is hand-placed PNGs; no procedural generation | demo scene | Phase 2 |
| No code API; scenes authored by hand | — | Phase 3 |
| Large demo `.tscn` with embedded data | `demo-rose-garden.tscn` | Phase 0/4 cleanup |
| Effects look up the controller via a global group (`"SkySetting"`); brittle if absent | subscriber scripts | Phase 3 (optional export ref + null-guard) |

---

## Milestones (suggested sequencing)

| Milestone | Contents | Phase(s) |
|---|---|---|
| **M0 — Docs & addon skeleton** | README, architecture, roadmap, plugin.cfg | 0 |
| **M1 — Water that flows & laps** | river + ocean-beach modes, foam, `WaterBody2D` | 1 |
| **M2 — Generated terrain** | sand/hills/mountains, SVG props, `TerrainLayer` | 2 |
| **M3 — Scene-from-code** | `WeatherScene` builder, presets, seeds | 3 |
| **M4 — Showcase & release** | demos, media, Asset Library | 4 |

*This roadmap is a living document — update checkboxes and notes as work lands.*
