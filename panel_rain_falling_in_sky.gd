@tool
extends Panel


func _ready() -> void:
	get_tree().get_first_node_in_group("SkySetting").updateRainAmount.connect(setRainAmount)
	

func setRainAmount(rainAmount) -> void:
	material.set_shader_parameter("count", clamp(rainAmount * 300, 0.0 , 500.0))
