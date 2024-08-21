@tool
class_name SkySetting extends Node2D


@export_category("Rain")

signal updateRainAmount
@export_range(0.0,1.0) var rainAmount = 0.0:
	set(newRainAmount):
		rainAmount = newRainAmount
		updateRainAmount.emit(newRainAmount)
		
@export_range(-0.1,0.1) var rainDelta = 0.0
		
var SkyGradient2D: GradientTexture2D = load("res://sky/Gradient2D_Sky.tres")

func _ready() -> void:pass

func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		SkyGradient2D.fill_to.y += 0.0001
		rainAmount += rainDelta / 100.0
