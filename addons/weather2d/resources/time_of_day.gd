@tool
class_name TimeOfDay
extends Resource
## The time-of-day half of the atmosphere: sky & water palette, cloud/fog tint, a scene-wide
## ambient light, and a [b]unified sun/moon model[/b] (screen position, light color, and how
## strongly stars show). Orthogonal to [WeatherPreset] — combine any time of day with any
## weather (e.g. golden hour + storm, or night + snow).
##
## The sun model is the coherence pillar of the kit: the same [member sun_uv] / [member
## sun_color] drives the sky glow & disc, the lit side of the clouds, and the water glint, so
## a scene reads as lit by one light. See [SkyController] for animating it over a day.
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

## Canonical position of this time on the normalized day clock (0 = midnight, ~0.46 = noon).
## Lets a day-night cycle *start* at the picked hour (see [SkyController.day01]).
@export_range(0.0, 1.0) var day := 0.46

@export_group("Sun / moon")
## Where the sun (or moon) sits in the sky, in screen UV (0,0 top-left … 1,1 bottom-right).
@export var sun_uv := Vector2(0.5, 0.18)
## The light color of the sun/moon — tints the sky glow, cloud highlights, and water glint.
@export var sun_color := Color(1.0, 0.98, 0.92)
## How brightly stars show (0 = day, 1 = deep night). Also fades the moon-vs-sun read.
@export_range(0.0, 1.0) var star_intensity := 0.0


static func dawn() -> TimeOfDay:
	var t := TimeOfDay.new()
	t.sky_top = Color(0.53, 0.55, 0.74)
	t.sky_bottom = Color(0.98, 0.80, 0.72)
	t.water_deep = Color(0.18, 0.26, 0.42)
	t.water_shallow = Color(0.62, 0.62, 0.66)
	t.cloud_color = Color(1.0, 0.92, 0.90)
	t.fog_color = Color(0.92, 0.86, 0.86)
	t.ambient = Color(0.94, 0.90, 0.96)
	t.sun_uv = Vector2(0.16, 0.44)
	t.sun_color = Color(1.0, 0.86, 0.78)
	t.star_intensity = 0.15
	t.day = 0.20
	return t


static func noon() -> TimeOfDay:
	var t := TimeOfDay.new()
	t.sky_top = Color(0.38, 0.62, 0.88)
	t.sky_bottom = Color(0.74, 0.87, 0.95)
	t.water_deep = Color(0.06, 0.30, 0.48)
	t.water_shallow = Color(0.28, 0.60, 0.70)
	t.fog_color = Color(0.85, 0.88, 0.92)
	t.ambient = Color(1.0, 1.0, 1.0)
	t.sun_uv = Vector2(0.5, 0.14)
	t.sun_color = Color(1.0, 0.99, 0.94)
	t.star_intensity = 0.0
	t.day = 0.46
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
	t.sun_uv = Vector2(0.80, 0.34)
	t.sun_color = Color(1.0, 0.78, 0.52)
	t.star_intensity = 0.0
	t.day = 0.70
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
	t.sun_uv = Vector2(0.88, 0.50)
	t.sun_color = Color(0.98, 0.60, 0.50)
	t.star_intensity = 0.30
	t.day = 0.82
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
	t.sun_uv = Vector2(0.30, 0.20)          # the moon, upper-left
	t.sun_color = Color(0.78, 0.84, 0.98)   # cool moonlight
	t.star_intensity = 1.0
	t.day = 0.0
	return t


## Interpolate every field of this time of day toward [param other] by [param t] (0..1).
## Used by [method cycle] and [SkyController] for a smooth day-night transition.
func lerp_to(other: TimeOfDay, t: float) -> TimeOfDay:
	var r := TimeOfDay.new()
	r.sky_top = sky_top.lerp(other.sky_top, t)
	r.sky_bottom = sky_bottom.lerp(other.sky_bottom, t)
	r.water_deep = water_deep.lerp(other.water_deep, t)
	r.water_shallow = water_shallow.lerp(other.water_shallow, t)
	r.cloud_color = cloud_color.lerp(other.cloud_color, t)
	r.fog_color = fog_color.lerp(other.fog_color, t)
	r.ambient = ambient.lerp(other.ambient, t)
	r.sun_uv = sun_uv.lerp(other.sun_uv, t)
	r.sun_color = sun_color.lerp(other.sun_color, t)
	r.star_intensity = lerpf(star_intensity, other.star_intensity, t)
	r.day = day
	return r


# Keyframes around a normalized day (0 = midnight … wraps at 1). Positions are fractions of
# a full day; the sun rises through dawn, peaks at noon, warms through golden hour, sets at
# dusk, and the moon rules the night.
const _CYCLE := [
	[0.00, "night"],
	[0.20, "dawn"],
	[0.46, "noon"],
	[0.70, "golden_hour"],
	[0.82, "dusk"],
	[1.00, "night"],
]


static func _keyframe(name: String) -> TimeOfDay:
	match name:
		"dawn": return dawn()
		"noon": return noon()
		"golden_hour": return golden_hour()
		"dusk": return dusk()
		_: return night()


## The time of day at normalized day time [param day01] (0..1, wrapping), interpolated between
## the five keyframe factories. `0` is midnight, `~0.23` dawn, `~0.46` noon, `~0.7` golden,
## `~0.82` dusk. Drive it over time for a day-night cycle (see [SkyController]).
static func cycle(day01: float) -> TimeOfDay:
	var d := fposmod(day01, 1.0)
	for i in range(_CYCLE.size() - 1):
		var a: Array = _CYCLE[i]
		var b: Array = _CYCLE[i + 1]
		if d >= float(a[0]) and d <= float(b[0]):
			var span: float = maxf(float(b[0]) - float(a[0]), 0.00001)
			var t: float = (d - float(a[0])) / span
			var out := _keyframe(a[1]).lerp_to(_keyframe(b[1]), t)
			out.day = d
			return out
	return noon()
