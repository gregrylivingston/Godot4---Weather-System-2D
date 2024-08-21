@tool
class_name SkySetting extends Node2D


signal updateRainAmount
@export_range(0.0,1.0) var rainAmount = 0.0:
	set(newRainAmount):
		rainAmount = newRainAmount
		updateRainAmount.emit(newRainAmount)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().process_frame
	rainAmount = rainAmount


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
