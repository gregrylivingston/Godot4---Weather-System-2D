extends Polygon2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if 	%AudioStreamPlayer.playing:
		var volume := int( 100 * db_to_linear(AudioServer.get_bus_peak_volume_left_db(0,0)))
		#%Label_db.text =  str(volume)
	
		if volume > 10:
			texture = load("res://texture/character/t_mouth_wide.png")
		else:
			texture = load("res://texture/character/t_mouth_closed_confident.png")
