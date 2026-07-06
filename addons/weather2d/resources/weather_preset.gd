@tool
class_name WeatherPreset
extends Resource
## Atmosphere preset for the Weather System 2D kit: the sky palette, rain/cloud amounts,
## and the water palette they imply. Consumed by [WeatherScene] (and storable in a
## [ScenePreset]) so a mood can be reused across projects.
##
## Use the static factories for tuned starting points:
## [codeblock]
## var scene := WeatherScene.new().weather(WeatherPreset.overcast_dusk()).build()
## [/codeblock]

@export_range(0.0, 1.0) var rain := 0.0
@export_range(-1.0, 1.0) var rain_delta := 0.0
@export_range(0.0, 1.0) var clouds := 0.0
@export_range(0.0, 0.25) var sunset_rate := 0.0

@export var sky_top := Color(0.40, 0.62, 0.85)
@export var sky_bottom := Color(0.72, 0.85, 0.94)
@export var water_deep := Color(0.06, 0.26, 0.44)
@export var water_shallow := Color(0.26, 0.56, 0.66)


static func clear_noon() -> WeatherPreset:
	var p := WeatherPreset.new()
	p.rain = 0.0
	p.clouds = 0.15
	p.sky_top = Color(0.38, 0.62, 0.88)
	p.sky_bottom = Color(0.74, 0.87, 0.95)
	p.water_deep = Color(0.06, 0.30, 0.48)
	p.water_shallow = Color(0.28, 0.60, 0.70)
	return p


static func overcast_dusk() -> WeatherPreset:
	var p := WeatherPreset.new()
	p.rain = 0.2
	p.clouds = 0.7
	p.sunset_rate = 0.06
	p.sky_top = Color(0.32, 0.34, 0.46)
	p.sky_bottom = Color(0.86, 0.62, 0.52)
	p.water_deep = Color(0.10, 0.18, 0.30)
	p.water_shallow = Color(0.30, 0.40, 0.48)
	return p


static func storm() -> WeatherPreset:
	var p := WeatherPreset.new()
	p.rain = 0.85
	p.rain_delta = 0.05
	p.clouds = 1.0
	p.sky_top = Color(0.20, 0.22, 0.28)
	p.sky_bottom = Color(0.40, 0.44, 0.50)
	p.water_deep = Color(0.05, 0.10, 0.16)
	p.water_shallow = Color(0.18, 0.26, 0.32)
	return p
