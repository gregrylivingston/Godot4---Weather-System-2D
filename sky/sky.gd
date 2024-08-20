extends TextureRect


@export_range(-5.0,10.0) var cloudcover = -8.0



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	material.set_shader_parameter("cloudcover", cloudcover)
	cloudcover += 0.008
