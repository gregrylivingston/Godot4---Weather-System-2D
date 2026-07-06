@tool
class_name ScenePreset
extends Resource
## A whole reusable composition for the Weather System 2D kit: a seed, a size, an
## atmosphere ([WeatherPreset]), a stack of [TerrainLayer]s, and a water configuration.
##
## Feed one to [method WeatherScene.from_preset] to rebuild the same scene anywhere. Because
## it is a [Resource], you can save it as a `.tres` and share it between projects.

@export var scene_seed := 0
@export var size := Vector2(1920, 1080)
@export var time_of_day: TimeOfDay
@export var weather: WeatherPreset
## Back-to-front stack of terrain bands (mountains first … foreground last).
@export var terrain: Array[TerrainLayer] = []

@export var include_water := true
@export var water_mode: int = 2 # WaterBody2D.Mode.OCEAN_BEACH
## Waterline in UV (0 top … 1 bottom). Aligned to a GROUND layer's coast when one exists.
@export_range(0.0, 1.0) var water_level := 0.66


## Capture a [ScenePreset] from an existing scene tree — e.g. one authored by hand in the editor
## (`@tool` round-trip). Reads the [TerrainBand2D] bands (their [TerrainLayer]s, in order) and
## the [WaterBody2D]. Time-of-day and weather can't be reversed from composited colors, so set
## [member time_of_day] / [member weather] on the result yourself if you need them.
static func from_scene(root: Node) -> ScenePreset:
	var p := ScenePreset.new()
	var layers: Array[TerrainLayer] = []
	p.include_water = false
	for c in root.get_children():
		if c is TerrainBand2D and c.layer != null:
			layers.append(c.layer)
		elif c is WaterBody2D:
			p.include_water = true
			p.water_mode = int(c.mode)
			p.water_level = c.level
	p.terrain = layers
	return p
