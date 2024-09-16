@tool
class_name SkySetting extends Node2D


@export_category("Rain")

signal updateRainAmount
## Amount of rain from 0 (no rain) to 1 (max rain).  Numbers outside that range will delay the effects of a delta with the opposite signal.
## Scenes must subscribe to recieve rain updates.
@export_range(-1.0,2.0) var rainAmount: float = 0.0:
	set(newRainAmount):
		rainAmount = newRainAmount
		updateRainAmount.emit(newRainAmount)
## Change in rainAmount over time.  0 is no change, positive numbers increase rain, negative decreases.
@export_range(-1.0,1.0) var rainDelta: float = 0.0

@export_category("Sky")
signal updateCloudAmount
@export_range(-1.0,2.0) var cloudAmount: float = 0.0:
	set(newCloudAmount):
		cloudAmount = newCloudAmount
		updateCloudAmount.emit(newCloudAmount)
@export_range(-0.1,0.1) var cloudDelta:float = 0.0

@export_range(0.0,0.25) var sunsetRate := 0.0

var SkyGradient2D: GradientTexture2D = load("res://Weather2D/scene/Gradient2D_Sky.tres")

func _process(delta: float) -> void:
	if not Engine.is_editor_hint():  
		rainAmount += float(rainDelta) / 100.0
		cloudAmount += float(cloudDelta) / 100.0
	
		SkyGradient2D.fill_to.y += sunsetRate / 1000.0   
		SkyGradient2D.fill_to.x += sunsetRate / 1000.0   
