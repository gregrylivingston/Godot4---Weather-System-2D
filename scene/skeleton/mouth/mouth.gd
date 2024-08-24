extends Polygon2D

@onready var startScaleX = scale.x

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


var frameBuffer := 5

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if 	%AudioStreamPlayer.playing && frameBuffer < 1:
		frameBuffer = 3
		var volume := clampf( db_to_linear(AudioServer.get_bus_peak_volume_left_db(0,0)) , 0.1 ,1.0)

		if volume < 0.11:
			scale = Vector2(startScaleX, 0.1)
			modulate  = Color.BLACK
		else:
			modulate = Color.WHITE
			scale = Vector2(startScaleX, volume * 0.75)

	else: 
		frameBuffer -= 1
