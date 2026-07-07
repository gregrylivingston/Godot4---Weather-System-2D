# Using these backdrops in Lost Settlement

This project generates the flavoured scene that sits **behind a choice event / loading
screen** in Lost Settlement — the "view" that `SceneTransition` burns to reveal under the
card (e.g. *The Elders' Doubt*). The scenes are rendered naturalistically with a **light
period grade** (muted, slightly warm, soft-focus with a faint grain and vignette), so they
read as aged painted plates that nest into the game's UI — not maps.

Nothing in the game repo has been changed. This doc is the handoff.

## What was added here

- **`Regions`** (`addons/weather2d/api/regions.gd`) — one scene recipe per game biome, plus
  open ocean and the European departure ports, each with its own geography (terrain, water,
  planted props) and a default sky/weather mood. It exposes `Regions.for_biome(biome_id)`
  matching `MapSettings.Biome` (`TEMPERATE, JUNGLE, SWAMP, CARIBBEAN, ARID` → `0..4`).
- **Period grade** — the existing painterly post (`PainterlyLayer` / `painterly.gdshader`)
  gained a `saturation` control. `WeatherScene.painterly(enable, saturation, warmth)` applies
  it; every region uses a slight mute + warmth (`_GRADE_SATURATION` / `_GRADE_WARMTH` in
  `regions.gd`). Defaults are unchanged for anything that called `painterly(true)`.
- **Region props** — SVGs under `assets/svg/`: `fern`, `banana`, `mangrove`, `cactus`,
  `reed`, `dead_tree` — so jungle / swamp / arid have distinct geography.
- The demo **launcher** (`res://demos/launcher.tscn`) previews every region — run it to
  browse the plates and tweak mood.

## Porting into the game

Copy two folders from this repo into `lost-settlement/`:

1. `addons/weather2d/` — the kit (nodes, shaders, `Regions`, `WeatherScene`, presets).
2. `assets/svg/` — the props. The kit loads them by the hardcoded path `res://assets/svg/…`,
   so keep them there (or edit the `const` paths in `weather_scene.gd` / `regions.gd`).

Then enable the plugin in **Project Settings → Plugins** (or just let the `class_name`s
register — the kit works without the editor plugin enabled). Both projects are Godot 4.7, so
the shaders and nodes drop in as-is.

## Wiring it to events (recommended: pre-render to a texture)

`GameEvent.image` is a `Texture2D`, and `SceneTransition` already composites + burns it. The
lowest-friction integration is to **render a region scene to a texture** and hand that to the
event, leaving the burn transition untouched:

```gdscript
# A helper (e.g. on an autoload). Renders a region plate to a Texture2D off-screen.
func render_region_backdrop(region: String, seed: int, size := Vector2i(1600, 900)) -> Texture2D:
    var vp := SubViewport.new()
    vp.size = size
    vp.render_target_update_mode = SubViewport.UPDATE_ONCE
    vp.add_child(Regions.build(region, {"seed": seed}).build())  # scene carries its own Camera2D
    add_child(vp)
    await RenderingServer.frame_post_draw   # let it draw once
    await RenderingServer.frame_post_draw   # + a frame for the screen-read post-process
    var img := vp.get_texture().get_image()
    vp.queue_free()
    return ImageTexture.create_from_image(img)
```

The plate is a full-bleed illustration, so feed it to the transition **full-screen** rather
than through `SceneTransition._compose_backdrop` (which insets art at 72% width on a blank
parchment field). Either set the composed backdrop to the texture directly, or set
`SHIP_WIDTH_FRAC = 1.0` for these.

### Choosing the region per phase

Map the three launch phases to regions using data the game already has
(`EventLibrary.choose_for_country` runs per nation; the chosen site carries `biome`):

| Phase       | Region                                                                    |
|-------------|---------------------------------------------------------------------------|
| Departure   | The nation's home port — `"Seville (Iberia)"`, `"England Coast"`, `"France Coast"` (Europeans), or `"Temperate Woodland"` (native overland start) |
| Journey     | `"Open Ocean"` (Europeans at sea) or `"Temperate Woodland"` (native overland) |
| Arrival     | `Regions.for_biome(GameState.player_destination_site.biome)`              |

So `EventLibrary` (or `SceneTransition`, when it builds each backdrop) picks the region for
the phase, pre-renders it once, and assigns it to the event. Vary `seed` by run so repeat
playthroughs get different arrangements of the same region.

## Alternative: live animated backdrops

For moving water / drifting clouds / falling rain, add the `WeatherScene` node tree **live**
behind the card instead of a still. Build with `{"live": true}` and add it as the backdrop
node in `SceneTransition` (below the `EventCard`, above the world). This needs the burn
transition adapted (the fire-dissolve shader expects a `TextureRect`), so it's more work —
pre-rendered stills are the drop-in path; go live only if the motion is worth it.

## Tuning

- Per-region mood lives in `regions.gd` — the default `TimeOfDay` / `WeatherPreset` passed to
  `_base`, and each region's terrain palette / prop set.
- The period grade strength is `_GRADE_SATURATION` / `_GRADE_WARMTH` in `regions.gd`; the
  underlying controls (softness, blur, grain, vignette, warmth, saturation) are on
  `PainterlyLayer` / `painterly.gdshader`. Lower saturation = more aged; raise it back toward
  1.0 for a more vivid plate.
- `opts` accepted by `Regions.build` / `for_biome`: `seed`, `time_of_day`, `weather`,
  `props`, `birds`, `painterly` (default true), `live`, `day_night_speed`, `low_graphics`.
