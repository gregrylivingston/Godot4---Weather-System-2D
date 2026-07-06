extends Node2D
## Phase 3 demo: an entire scene built from code with the WeatherScene builder.
## Press Play — nothing is authored in the .tscn except this script.

func _ready() -> void:
	var builder := WeatherScene.new()
	builder.set_seed(20260705)
	builder.set_size(Vector2(1920, 1080))
	builder.weather(WeatherPreset.clear_noon())
	builder.terrain([
		TerrainLayer.mountains(),
		TerrainLayer.hills(),
		TerrainLayer.ground(),
	])
	builder.water(WaterBody2D.Mode.OCEAN_BEACH)
	add_child(builder.build())
