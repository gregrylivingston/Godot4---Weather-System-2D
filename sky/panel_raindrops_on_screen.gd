extends Panel

@export_range(-5.0,10.0) var rainAmount = 7.0

func _process(delta: float) -> void:
	material.set_shader_parameter("frequency", rainAmount)
	rainAmount -= 0.008
	rainAmount = clamp(rainAmount, 0, 7)
