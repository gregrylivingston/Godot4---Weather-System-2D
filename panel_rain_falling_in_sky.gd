extends Panel

@export_range(-5.0,10.0) var rainAmount = -10

func _process(delta: float) -> void:
	material.set_shader_parameter("count", rainAmount)
	rainAmount += 0.05
