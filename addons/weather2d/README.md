# Weather System 2D

A reusable atmosphere kit for 2D Godot scenes — a shader sky with a sun/moon and day-night
cycle, drifting volumetric clouds, rain / snow / fog, reflective water (still / river /
ocean-beach), procedural terrain, and scattered vector props. Assemble a whole scene from code
with one builder call, or drop the `@tool` nodes in by hand.

## Install

Copy this `weather2d` folder into your project's `addons/` directory, then enable
**Weather System 2D** under **Project → Project Settings → Plugins**. No external dependencies.

## Quick start

```gdscript
var scene := WeatherScene.new() \
    .time_of_day(TimeOfDay.golden_hour()) \
    .weather(WeatherPreset.rainy()) \
    .terrain([TerrainLayer.mountains(), TerrainLayer.hills(), TerrainLayer.ground()]) \
    .water(WaterBody2D.Mode.OCEAN_BEACH) \
    .live(true, 0.01)   # animate: sun tracks across the sky, weather can roll in
add_child(scene.build())
```

On a weak or software (no-GPU) renderer, add `.low_graphics()` for cheap shader paths.

## Docs & source

Full documentation, demos, and the tutorial live in the GitHub repository:
<https://github.com/gregrylivingston/Godot4---Weather-System-2D>

- Getting started & API reference: `docs/api/`
- Architecture: `docs/ARCHITECTURE.md`

## License

MIT — see [`LICENSE`](LICENSE).
