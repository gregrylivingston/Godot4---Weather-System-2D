@tool
extends TextureRect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().get_first_node_in_group("SkySetting").updateCloudAmount.connect(setCloudAmount)


	
func setCloudAmount(cloudAmount) -> void:
	material.set_shader_parameter("cloudcover", -15.0 + cloudAmount * 25.0)
