# Make your first scene

A five-minute tour of the Weather System 2D kit. By the end you'll have a living beach that
runs a day-night cycle and rolls a storm in — built entirely from code.

> Prerequisite: copy [`addons/weather2d/`](../../addons/weather2d/) into your project and tick
> **Weather System 2D** on under **Project → Project Settings → Plugins**. No other setup.

## 1. The simplest scene

Everything is assembled by the [`WeatherScene`](../../addons/weather2d/api/weather_scene.gd)
builder. Chain a few calls, then `build()` a ready `Node2D` and add it:

```gdscript
extends Node2D

func _ready() -> void:
    var scene := WeatherScene.new() \
        .terrain([TerrainLayer.ground()]) \
        .water(WaterBody2D.Mode.OCEAN_BEACH) \
        .build()
    add_child(scene)
```

That already gives you a sky, a sandy shore, and ocean water lapping it — a `Camera2D` is
included, so press Play and you'll see it centered.

## 2. Set the time and weather

Time of day and weather are **independent axes** — combine any hour with any conditions.

```gdscript
var scene := WeatherScene.new() \
    .time_of_day(TimeOfDay.golden_hour()) \   # Dawn / Noon / Golden Hour / Dusk / Night
    .weather(WeatherPreset.rainy()) \         # Clear / Cloudy / Foggy / Rainy / Stormy / Snowy
    .cloud_style(CloudPreset.cumulus()) \     # Clear / Wispy / Scattered / Cumulus / Overcast / Stormy
    .terrain([TerrainLayer.mountains(), TerrainLayer.hills(), TerrainLayer.ground()]) \
    .water(WaterBody2D.Mode.OCEAN_BEACH) \
    .build()
```

The `TimeOfDay` sets the palette and the sun; the `WeatherPreset` layers rain/fog/cloud on top
and darkens the palette for storms.

## 3. Add scenery

```gdscript
    .props(true, 20) \   # scatter seeded trees/rocks along the shore, sized by depth
    .birds(true, 5) \    # a few birds crossing the sky
    .painterly(true)     # soft-focus + grain + vignette post-process
```

Props are planted **per terrain layer** — small, hazy trees on the back hills; big, crisp ones
up front — and the whole layout is deterministic for a given `set_seed(n)`.

## 4. Make it live

By default the scene is a static snapshot. Add `.live()` and a
[`SkyController`](../../addons/weather2d/nodes/sky_controller.gd) animates everything at
runtime:

```gdscript
    .live(true, 0.01) \  # animate; 0.01 days/sec = a slow day-night cycle
    .lightning(true)     # storms flash
```

Now the sun tracks across the sky, the palette (sky, clouds, **and water**) shifts through the
day, stars come out at night, clouds drift and cast moving shadows, and the water glints and
ripples. The cycle **starts at the time of day you picked**.

## 5. Change the weather at runtime

Grab the controller and cross-fade to a new `WeatherPreset`:

```gdscript
var root := scene   # the Node2D from build()
add_child(root)
var ctrl := root.get_node("SkyController") as SkyController
ctrl.transition_to(WeatherPreset.stormy(), 8.0)   # roll a storm in over 8 seconds
```

## 6. Reuse it

- **Presets:** save a whole composition to a [`ScenePreset`](../../addons/weather2d/resources/scene_preset.gd)
  `.tres` and rebuild it with `WeatherScene.new().from_preset(preset).build()`.
- **Scenarios:** grab a ready-made recipe —
  `Scenarios.build("River", {"seed": 7, "time_of_day": TimeOfDay.dusk()}).build()`.
  Recipes: **Beach, Small Island, River, Lake, Mountains**.
- **By hand:** every node (`WaterBody2D`, `TerrainBand2D`, `PropScatter2D`, …) is a `@tool`
  with a full inspector, so you can drop them into a scene and tune them live instead.

Next: the full [API reference](reference.md).
