@tool
class_name WeatherPreset
extends Resource
## The weather half of the atmosphere: rain / snow / fog / clouds / wind, plus how much the
## weather darkens and desaturates the palette (storms). Orthogonal to [TimeOfDay] — the
## sky and water colors come from the time of day; this only sets the *conditions*.
##
## Use the static factories:
## [codeblock]
## WeatherScene.new().time_of_day(TimeOfDay.dusk()).weather(WeatherPreset.rainy())
## [/codeblock]

@export_range(0.0, 1.0) var rain := 0.0
@export_range(-1.0, 1.0) var rain_delta := 0.0
## Falling snow instead of rain (uses `rain` as the snow amount).
@export var snow := false
@export_range(0.0, 1.0) var fog := 0.0
@export_range(0.0, 1.0) var clouds := 0.0
## Wind strength — drives foliage sway and rain slant (0 = still, 1 = gale).
@export_range(0.0, 1.0) var wind := 0.25
## How much this weather darkens the time-of-day palette (0 = none, 1 = deep gloom).
@export_range(0.0, 1.0) var darken := 0.0
## How much this weather greys out the palette.
@export_range(0.0, 1.0) var desaturate := 0.0


static func clear() -> WeatherPreset:
	var p := WeatherPreset.new()
	p.clouds = 0.12
	p.wind = 0.2
	return p


static func cloudy() -> WeatherPreset:
	var p := WeatherPreset.new()
	p.clouds = 0.6
	p.wind = 0.35
	p.darken = 0.05
	return p


static func foggy() -> WeatherPreset:
	var p := WeatherPreset.new()
	p.fog = 0.7
	p.clouds = 0.4
	p.wind = 0.15
	p.darken = 0.05
	p.desaturate = 0.3
	return p


static func rainy() -> WeatherPreset:
	var p := WeatherPreset.new()
	p.rain = 0.55
	p.clouds = 0.7
	p.fog = 0.15
	p.wind = 0.45
	p.darken = 0.2
	p.desaturate = 0.2
	return p


static func stormy() -> WeatherPreset:
	var p := WeatherPreset.new()
	p.rain = 0.9
	p.rain_delta = 0.05
	p.clouds = 1.0
	p.fog = 0.25
	p.wind = 0.85
	p.darken = 0.5
	p.desaturate = 0.4
	return p


static func snowy() -> WeatherPreset:
	var p := WeatherPreset.new()
	p.rain = 0.5
	p.snow = true
	p.clouds = 0.6
	p.fog = 0.3
	p.wind = 0.3
	p.darken = 0.1
	p.desaturate = 0.25
	return p
