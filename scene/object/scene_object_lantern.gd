extends Sprite2D

@onready var startingScale := scale

func _ready() -> void:
	await get_tree().create_timer(randf_range(0.01,0.1)).timeout
	updateLight()




func updateLight() -> void:
	var rateOfChange := randf_range(0.2,0.4)
	get_tree().create_tween().tween_property($PointLight2D, "skew", randf_range(-0.01,0.01), rateOfChange)
	get_tree().create_tween().tween_property($PointLight2D, "scale", startingScale * randf_range(0.95,1.05), rateOfChange)
	get_tree().create_tween().tween_property($PointLight2D, "energy", randf_range(0.19,0.21), rateOfChange)

	await get_tree().create_timer(randf_range(0.1,0.5)).timeout
	updateLight()
