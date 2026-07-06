class_name SkyController
extends Node2D
## Runtime brain that makes a generated scene a [b]living[/b] one (Phase 5).
##
## A static [WeatherScene] composites a fixed look; drop a [SkyController] in and the sky,
## clouds, water and weather come alive:
## [ul]
## [li][b]Day-night cycle[/b] — advance [member day_night_speed] and the whole palette,
## sun/moon position, glow and stars interpolate through [method TimeOfDay.cycle].[/li]
## [li][b]Weather transitions[/b] — [method transition_to] lerps between [WeatherPreset]s over
## time, so a clear scene can cloud over and storm without a rebuild.[/li]
## [li][b]Lightning[/b] — occasional flashes while it storms.[/li]
## [/ul]
##
## It joins the [code]"SkySetting"[/code] group and emits [signal updateRainAmount] /
## [signal updateCloudAmount], so a [WaterBody2D] (and any legacy subscriber) reacts to it
## exactly as it would to the classic SkySetting hub. All motion is scaled by frame [code]
## delta[/code], so it runs at the same rate at any FPS.
##
## [WeatherScene.live] builds one wired up for you; you rarely construct it by hand.

## Rain intensity (0..1) — emitted whenever it changes so water/rain overlays follow.
signal updateRainAmount(amount: float)
## Cloud coverage (0..1) — emitted whenever it changes.
signal updateCloudAmount(amount: float)

## Whole days per second. 0 freezes the clock; ~0.01 is a slow, watchable cycle.
@export var day_night_speed := 0.0
## When true, the palette/sun follow [member day01] via [method TimeOfDay.cycle]. When false,
## the sky holds [member base_time] and only weather transitions animate.
@export var time_cycle_enabled := false
## Normalized time of day (0 = midnight, ~0.46 = noon, wraps at 1). Advanced by the cycle.
@export_range(0.0, 1.0) var day01 := 0.46
## Emit occasional lightning flashes while it rains hard.
@export var lightning_enabled := false

# --- wiring (set by WeatherScene.build, or by hand) ---
var size := Vector2(1920, 1080)
var base_time: TimeOfDay = null
var cloud_style: CloudPreset = null
var sky_material: ShaderMaterial = null
var cloud_material: ShaderMaterial = null
var cloud_shadow_material: ShaderMaterial = null
var fog_material: ShaderMaterial = null
var rain_material: ShaderMaterial = null
var water: WaterBody2D = null
var ambient: CanvasModulate = null
var lightning_rect: ColorRect = null

# --- weather transition state ---
var _w_from: WeatherPreset = null
var _w_to: WeatherPreset = null
var _w_blend := 1.0
var _w_blend_speed := 0.0

# --- lightning state ---
var _flash := 0.0
var _strike_timer := 0.0

# --- emit de-dupe ---
var _emitted_rain := -1.0
var _emitted_cloud := -1.0

const _GLOOM := Color(0.10, 0.11, 0.15)
# Wind drift direction for clouds/shadows (mostly rightward, a touch downward). The shaders
# normalize it; wind *strength* speeds cloud evolution rather than steering it.
const _WIND_DIR := Vector2(1.0, 0.12)


func _enter_tree() -> void:
	add_to_group("SkySetting")


func _ready() -> void:
	if base_time == null:
		base_time = TimeOfDay.noon()
	if _w_to == null:
		_w_to = WeatherPreset.clear()
	if _w_from == null:
		_w_from = _w_to
	if sky_material != null:
		sky_material.set_shader_parameter("aspect", size.x / maxf(size.y, 1.0))
	_apply()  # push a correct first frame even before _process runs


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	step(delta)


## Begin the built weather (no transition). Called by the builder.
func set_weather(preset: WeatherPreset) -> void:
	_w_to = preset if preset != null else WeatherPreset.clear()
	_w_from = _w_to
	_w_blend = 1.0
	_w_blend_speed = 0.0


## Smoothly cross-fade from the current weather to [param target] over [param duration] seconds.
func transition_to(target: WeatherPreset, duration := 6.0) -> void:
	if target == null:
		return
	_w_from = current_weather()  # snapshot where we are right now
	_w_to = target
	_w_blend = 0.0
	_w_blend_speed = 1.0 / maxf(duration, 0.0001)


## The weather actually in effect this instant (the blended preset). A fresh copy.
func current_weather() -> WeatherPreset:
	if _w_from == null or _w_to == null:
		return _w_to if _w_to != null else WeatherPreset.clear()
	return _blend_weather(_w_from, _w_to, _w_blend)


## The time of day in effect this instant.
func current_time() -> TimeOfDay:
	if time_cycle_enabled:
		return TimeOfDay.cycle(day01)
	return base_time if base_time != null else TimeOfDay.noon()


## Advance the simulation by [param delta] seconds and push everything to the materials.
## Pure enough to call directly from a headless test.
func step(delta: float) -> void:
	if time_cycle_enabled and day_night_speed != 0.0:
		day01 = fposmod(day01 + day_night_speed * delta, 1.0)
	if _w_blend < 1.0:
		_w_blend = clampf(_w_blend + _w_blend_speed * delta, 0.0, 1.0)
	_update_lightning(delta)
	_apply()


# --- application -----------------------------------------------------------

func _apply() -> void:
	var tod := current_time()
	var w := current_weather()
	var darken: float = w.darken
	var desat: float = w.desaturate

	if sky_material != null:
		sky_material.set_shader_parameter("sky_top", _pal(tod.sky_top, darken, desat))
		sky_material.set_shader_parameter("sky_bottom", _pal(tod.sky_bottom, darken, desat))
		sky_material.set_shader_parameter("sun_uv", tod.sun_uv)
		sky_material.set_shader_parameter("sun_color", tod.sun_color)
		sky_material.set_shader_parameter("star_intensity", tod.star_intensity)

	var cloud01: float = clampf(w.clouds, 0.0, 1.0)
	if cloud_material != null:
		cloud_material.set_shader_parameter("coverage", lerpf(-0.3, 0.7, cloud01))
		cloud_material.set_shader_parameter("cloud_color", _pal(tod.cloud_color, darken, desat))
		cloud_material.set_shader_parameter("sun_tint", tod.sun_color)
		cloud_material.set_shader_parameter("sun_uv", tod.sun_uv)
		cloud_material.set_shader_parameter("wind_dir", _WIND_DIR)
		if cloud_style != null:
			cloud_material.set_shader_parameter("speed", cloud_style.speed * (0.5 + w.wind * 1.5))

	if cloud_shadow_material != null:
		cloud_shadow_material.set_shader_parameter("coverage", cloud01)
		cloud_shadow_material.set_shader_parameter("wind_dir", _WIND_DIR)

	if fog_material != null:
		fog_material.set_shader_parameter("density", w.fog)
		fog_material.set_shader_parameter("fog_color", _pal(tod.fog_color, darken * 0.5, desat))

	if rain_material != null:
		rain_material.set_shader_parameter("amount", w.rain)
		rain_material.set_shader_parameter("snow", w.snow)
		rain_material.set_shader_parameter("slant", -0.02 - w.wind * 0.18)

	if water != null:
		water.sun_uv = tod.sun_uv
		water.sun_color = tod.sun_color
		# The sun only glints on the water by day; the moon barely does.
		water.glint_strength = clampf(0.35 * (1.0 - tod.star_intensity), 0.0, 1.0)
		# When the clock runs, the water palette follows the time of day too.
		if time_cycle_enabled:
			water.set_day_palette(_pal(tod.water_deep, darken, desat), _pal(tod.water_shallow, darken, desat))

	if ambient != null:
		var amb := tod.ambient.lerp(_GLOOM.lightened(0.25), darken * 0.6)
		amb = amb.lerp(Color.WHITE, _flash * 0.7)   # lightning brightens the scene
		ambient.color = amb

	if lightning_rect != null:
		lightning_rect.color = Color(0.9, 0.94, 1.0, _flash * 0.55)

	# Notify subscribers (water reacts, rain overlay already driven above).
	if absf(w.rain - _emitted_rain) > 0.001:
		_emitted_rain = w.rain
		updateRainAmount.emit(w.rain)
	if absf(cloud01 - _emitted_cloud) > 0.001:
		_emitted_cloud = cloud01
		updateCloudAmount.emit(cloud01)


func _update_lightning(delta: float) -> void:
	# Decay any current flash.
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 3.5)
	if not lightning_enabled:
		return
	var rain: float = current_weather().rain
	if rain < 0.5:
		_strike_timer = 0.0
		return
	# Strikes get more frequent as the storm intensifies.
	_strike_timer -= delta
	if _strike_timer <= 0.0:
		_flash = 1.0
		var storm := (rain - 0.5) / 0.5              # 0..1 over the stormy range
		_strike_timer = lerpf(7.0, 2.0, clampf(storm, 0.0, 1.0)) + randf() * 3.0


# --- helpers ---------------------------------------------------------------

## Weather modulation of a base color: darken toward gloom, then grey out. Mirrors WeatherScene.
static func _pal(c: Color, darken: float, desat: float) -> Color:
	var out := c.lerp(_GLOOM, darken * 0.5)
	if desat > 0.0:
		var g := out.get_luminance()
		out = out.lerp(Color(g, g, g), desat * 0.6)
	return out


static func _blend_weather(a: WeatherPreset, b: WeatherPreset, t: float) -> WeatherPreset:
	var r := WeatherPreset.new()
	r.rain = lerpf(a.rain, b.rain, t)
	r.rain_delta = lerpf(a.rain_delta, b.rain_delta, t)
	r.fog = lerpf(a.fog, b.fog, t)
	r.clouds = lerpf(a.clouds, b.clouds, t)
	r.wind = lerpf(a.wind, b.wind, t)
	r.darken = lerpf(a.darken, b.darken, t)
	r.desaturate = lerpf(a.desaturate, b.desaturate, t)
	r.snow = b.snow if t >= 0.5 else a.snow
	return r
