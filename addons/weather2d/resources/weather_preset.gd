@tool
class_name WeatherPreset
extends Resource
## Atmosphere preset for the Weather System 2D kit: sky palette, rain/snow/cloud/fog amounts,
## wind, and the water palette they imply. Consumed by [WeatherScene] (and storable in a
## [ScenePreset]) so a mood can be reused across projects.
##
## Use the static factories for tuned starting points:
## [codeblock]
## var scene := WeatherScene.new().weather(WeatherPreset.golden_hour()).build()
## [/codeblock]

@export_range(0.0, 1.0) var rain := 0.0
@export_range(-1.0, 1.0) var rain_delta := 0.0
@export_range(0.0, 1.0) var clouds := 0.0
@export_range(0.0, 0.25) var sunset_rate := 0.0
## Falling snow instead of rain (uses the `rain` amount as the snow amount).
@export var snow := false
## Distance haze / fog density (0 = clear).
@export_range(0.0, 1.0) var fog := 0.0
## Wind strength — drives foliage sway and rain slant (0 = still, 1 = gale).
@export_range(0.0, 1.0) var wind := 0.3

@export var sky_top := Color(0.40, 0.62, 0.85)
@export var sky_bottom := Color(0.72, 0.85, 0.94)
@export var water_deep := Color(0.06, 0.26, 0.44)
@export var water_shallow := Color(0.26, 0.56, 0.66)
@export var fog_color := Color(0.80, 0.83, 0.87)
@export var cloud_color := Color(1.0, 1.0, 1.0)


static func clear_noon() -> WeatherPreset:
	var p := WeatherPreset.new()
	p.clouds = 0.15
	p.wind = 0.25
	p.sky_top = Color(0.38, 0.62, 0.88)
	p.sky_bottom = Color(0.74, 0.87, 0.95)
	p.water_deep = Color(0.06, 0.30, 0.48)
	p.water_shallow = Color(0.28, 0.60, 0.70)
	return p


static func golden_hour() -> WeatherPreset:
	var p := WeatherPreset.new()
	p.clouds = 0.3
	p.wind = 0.2
	p.sky_top = Color(0.52, 0.52, 0.72)
	p.sky_bottom = Color(0.98, 0.74, 0.46)
	p.water_deep = Color(0.16, 0.22, 0.38)
	p.water_shallow = Color(0.66, 0.52, 0.44)
	p.cloud_color = Color(1.0, 0.86, 0.72)
	return p


static func overcast_dusk() -> WeatherPreset:
	var p := WeatherPreset.new()
	p.rain = 0.2
	p.clouds = 0.7
	p.fog = 0.15
	p.wind = 0.4
	p.sunset_rate = 0.06
	p.sky_top = Color(0.32, 0.34, 0.46)
	p.sky_bottom = Color(0.86, 0.62, 0.52)
	p.water_deep = Color(0.10, 0.18, 0.30)
	p.water_shallow = Color(0.30, 0.40, 0.48)
	return p


static func foggy() -> WeatherPreset:
	var p := WeatherPreset.new()
	p.clouds = 0.5
	p.fog = 0.7
	p.wind = 0.15
	p.sky_top = Color(0.66, 0.70, 0.74)
	p.sky_bottom = Color(0.82, 0.85, 0.87)
	p.water_deep = Color(0.30, 0.38, 0.44)
	p.water_shallow = Color(0.52, 0.60, 0.64)
	p.fog_color = Color(0.86, 0.88, 0.90)
	return p


static func storm() -> WeatherPreset:
	var p := WeatherPreset.new()
	p.rain = 0.85
	p.rain_delta = 0.05
	p.clouds = 1.0
	p.fog = 0.25
	p.wind = 0.85
	p.sky_top = Color(0.20, 0.22, 0.28)
	p.sky_bottom = Color(0.40, 0.44, 0.50)
	p.water_deep = Color(0.05, 0.10, 0.16)
	p.water_shallow = Color(0.18, 0.26, 0.32)
	p.fog_color = Color(0.55, 0.58, 0.62)
	return p


static func snowy_dusk() -> WeatherPreset:
	var p := WeatherPreset.new()
	p.rain = 0.5
	p.snow = true
	p.clouds = 0.6
	p.fog = 0.3
	p.wind = 0.3
	p.sky_top = Color(0.42, 0.46, 0.58)
	p.sky_bottom = Color(0.74, 0.74, 0.82)
	p.water_deep = Color(0.16, 0.22, 0.30)
	p.water_shallow = Color(0.40, 0.48, 0.56)
	p.fog_color = Color(0.86, 0.88, 0.92)
	return p


static func night() -> WeatherPreset:
	var p := WeatherPreset.new()
	p.clouds = 0.25
	p.wind = 0.3
	p.sky_top = Color(0.05, 0.07, 0.16)
	p.sky_bottom = Color(0.16, 0.20, 0.34)
	p.water_deep = Color(0.03, 0.05, 0.12)
	p.water_shallow = Color(0.10, 0.16, 0.28)
	p.cloud_color = Color(0.5, 0.54, 0.66)
	return p
