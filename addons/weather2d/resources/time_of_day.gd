@tool
class_name TimeOfDay
extends Resource
## The time-of-day half of the atmosphere: sky & water palette, cloud/fog tint, and a
## scene-wide ambient light tint. Orthogonal to [WeatherPreset] — combine any time of day
## with any weather (e.g. golden hour + storm, or night + snow).
##
## Use the static factories:
## [codeblock]
## WeatherScene.new().time_of_day(TimeOfDay.golden_hour()).weather(WeatherPreset.stormy())
## [/codeblock]

@export var sky_top := Color(0.38, 0.62, 0.88)
@export var sky_bottom := Color(0.74, 0.87, 0.95)
@export var water_deep := Color(0.06, 0.30, 0.48)
@export var water_shallow := Color(0.28, 0.60, 0.70)
@export var cloud_color := Color(1.0, 1.0, 1.0)
@export var fog_color := Color(0.82, 0.85, 0.88)
## Scene-wide ambient tint (applied as a CanvasModulate). White = full daylight.
@export var ambient := Color(1.0, 1.0, 1.0)


static func dawn() -> TimeOfDay:
	var t := TimeOfDay.new()
	t.sky_top = Color(0.53, 0.55, 0.74)
	t.sky_bottom = Color(0.98, 0.80, 0.72)
	t.water_deep = Color(0.18, 0.26, 0.42)
	t.water_shallow = Color(0.62, 0.62, 0.66)
	t.cloud_color = Color(1.0, 0.92, 0.90)
	t.fog_color = Color(0.92, 0.86, 0.86)
	t.ambient = Color(0.94, 0.90, 0.96)
	return t


static func noon() -> TimeOfDay:
	var t := TimeOfDay.new()
	t.sky_top = Color(0.38, 0.62, 0.88)
	t.sky_bottom = Color(0.74, 0.87, 0.95)
	t.water_deep = Color(0.06, 0.30, 0.48)
	t.water_shallow = Color(0.28, 0.60, 0.70)
	t.fog_color = Color(0.85, 0.88, 0.92)
	t.ambient = Color(1.0, 1.0, 1.0)
	return t


static func golden_hour() -> TimeOfDay:
	var t := TimeOfDay.new()
	t.sky_top = Color(0.52, 0.52, 0.72)
	t.sky_bottom = Color(0.98, 0.74, 0.46)
	t.water_deep = Color(0.16, 0.22, 0.38)
	t.water_shallow = Color(0.66, 0.52, 0.44)
	t.cloud_color = Color(1.0, 0.86, 0.72)
	t.fog_color = Color(0.96, 0.82, 0.68)
	t.ambient = Color(1.0, 0.92, 0.82)
	return t


static func dusk() -> TimeOfDay:
	var t := TimeOfDay.new()
	t.sky_top = Color(0.30, 0.28, 0.46)
	t.sky_bottom = Color(0.86, 0.54, 0.50)
	t.water_deep = Color(0.11, 0.15, 0.30)
	t.water_shallow = Color(0.40, 0.35, 0.44)
	t.cloud_color = Color(0.92, 0.74, 0.72)
	t.fog_color = Color(0.72, 0.62, 0.66)
	t.ambient = Color(0.84, 0.76, 0.86)
	return t


static func night() -> TimeOfDay:
	var t := TimeOfDay.new()
	t.sky_top = Color(0.05, 0.07, 0.16)
	t.sky_bottom = Color(0.16, 0.20, 0.34)
	t.water_deep = Color(0.03, 0.05, 0.12)
	t.water_shallow = Color(0.10, 0.16, 0.28)
	t.cloud_color = Color(0.50, 0.54, 0.66)
	t.fog_color = Color(0.30, 0.34, 0.46)
	t.ambient = Color(0.55, 0.58, 0.72)
	return t
