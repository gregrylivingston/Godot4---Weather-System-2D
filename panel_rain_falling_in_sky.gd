@tool
extends Panel


func _ready() -> void:
	get_tree().get_first_node_in_group("SkySetting").updateRainAmount.connect(setRainAmount)
	

func setRainAmount(rainAmount) -> void:
	material.set_shader_parameter("count", clampi(rainAmount * 300, 0 , 10000))
