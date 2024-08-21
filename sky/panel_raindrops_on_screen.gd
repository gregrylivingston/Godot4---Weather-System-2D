extends Panel


func _ready() -> void:
	get_tree().get_first_node_in_group("SkySetting").updateRainAmount.connect(setRainAmount)

func setRainAmount(rainAmount):
	material.set_shader_parameter("frequency", clamp(5.0 - rainAmount * 14.0, 0.0 , 7.0))
