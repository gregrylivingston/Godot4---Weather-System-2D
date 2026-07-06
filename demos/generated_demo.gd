extends Node2D
## Phase 3 demo: an entire scene built from code with the WeatherScene builder.
## Press Play — nothing is authored in the .tscn except this script.

func _ready() -> void:
	var builder := WeatherScene.new()
	builder.set_seed(20260705)
	builder.set_size(Vector2(1920, 1080))
	builder.time_of_day(TimeOfDay.golden_hour())
	builder.weather(WeatherPreset.clear())
	builder.terrain([
		TerrainLayer.mountains(Color(0.56, 0.60, 0.70)), # far, hazier range
		TerrainLayer.mountains(),                        # nearer range
		TerrainLayer.hills(),
		TerrainLayer.ground(),
	])
	builder.water(WaterBody2D.Mode.OCEAN_BEACH)
	builder.props(true, 20)   # scatter trees/rocks along the shore (stratified, depth-faded)
	builder.birds(true, 5)    # a few birds in the sky
	builder.painterly(true)   # soft-focus painterly post-process
	add_child(builder.build())
