@tool
class_name WaterBody2D
extends ColorRect
## A configurable 2D water surface for the Weather System 2D kit.
##
## Pick a [member mode] — [b]STILL[/b] pond, flowing [b]RIVER[/b], or [b]OCEAN_BEACH[/b]
## lapping a shore — and tune the palette, waves, flow and foam from the inspector or from
## code. The node owns its [ShaderMaterial] and a seamless noise texture, so dropping one
## into a scene "just works" without wiring up a material by hand.
##
## Code example:
## [codeblock]
## var water := WaterBody2D.new()
## water.mode = WaterBody2D.Mode.RIVER
## water.flow_direction = Vector2(1, 0.15)
## water.size = Vector2(1920, 400)
## add_child(water)
## [/codeblock]

## How the surface behaves. See the class description.
enum Mode {
	STILL,       ## Pond/lake below [member level]; ripples + reflections.
	RIVER,       ## Whole rect is water, streaming along [member flow_direction].
	OCEAN_BEACH, ## Animated waterline laps up a beach with a foam band.
}

const _SHADER_PATH := "res://addons/weather2d/shaders/water_body.gdshader"

@export var mode: Mode = Mode.STILL:
	set(v):
		mode = v
		_set_param("mode", int(v))

@export_group("Palette")
## Water color far from the shore.
@export var deep_color := Color(0.06, 0.26, 0.44):
	set(v):
		deep_color = v
		_set_param("deep_color", v)
## Water color in the shallows near the shoreline.
@export var shallow_color := Color(0.26, 0.56, 0.66):
	set(v):
		shallow_color = v
		_set_param("shallow_color", v)
@export var foam_color := Color(0.95, 0.98, 1.0):
	set(v):
		foam_color = v
		_set_param("foam_color", v)
## Overall surface opacity (lets background show through slightly).
@export_range(0.0, 1.0) var water_opacity := 0.85:
	set(v):
		water_opacity = v
		_set_param("water_opacity", v)

@export_group("Surface")
## Density of the wave/ripple pattern. Larger = finer, more numerous ripples.
@export var wave_scale := 6.0:
	set(v):
		wave_scale = v
		_set_param("wave_scale", v)
@export_range(0.0, 1.0) var wave_speed := 0.15:
	set(v):
		wave_speed = v
		_set_param("wave_speed", v)
## How much waves distort the reflection.
@export_range(0.0, 1.0) var wave_distortion := 0.15:
	set(v):
		wave_distortion = v
		_set_param("wave_distortion", v)
## Amplitude (in UV) of the rolling sine waves that undulate the surface/shoreline.
@export_range(0.0, 0.2) var wave_height := 0.03:
	set(v):
		wave_height = v
		_set_param("wave_height", v)
## Spatial frequency of the sine waves across the surface. Match the sand ground to align coasts.
@export var wave_frequency := 8.0:
	set(v):
		wave_frequency = v
		_set_param("wave_frequency", v)

@export_group("Waterline")
## Water fills below this UV.y (0 = top, 1 = bottom). Used by STILL and OCEAN_BEACH.
@export_range(0.0, 1.0) var level := 0.5:
	set(v):
		level = v
		_set_param("level", v)

@export_group("River flow")
## Direction the RIVER surface streams toward (need not be normalized).
@export var flow_direction := Vector2(1.0, 0.0):
	set(v):
		flow_direction = v
		_set_param("flow_direction", v)
@export_range(0.0, 2.0) var flow_speed := 0.25:
	set(v):
		flow_speed = v
		_set_param("flow_speed", v)

@export_group("Foam")
## Amount of foam (0 = none). Drives the shoreline band and river streaks.
@export_range(0.0, 1.0) var foam_amount := 0.5:
	set(v):
		foam_amount = v
		_set_param("foam_amount", v)
## Thickness (in UV) of the foam band along the shoreline.
@export_range(0.0, 0.5) var foam_width := 0.06:
	set(v):
		foam_width = v
		_set_param("foam_width", v)

@export_group("Ocean run-up")
## How far (in UV) OCEAN_BEACH waves swell up and down the shore.
@export_range(0.0, 0.3) var swell_height := 0.05:
	set(v):
		swell_height = v
		_set_param("swell_height", v)
@export_range(0.0, 3.0) var swell_speed := 0.5:
	set(v):
		swell_speed = v
		_set_param("swell_speed", v)

@export_group("Reflection")
@export var reflection_enabled := true:
	set(v):
		reflection_enabled = v
		_set_param("reflection_enabled", v)
@export_range(0.0, 1.0) var reflection_strength := 0.22:
	set(v):
		reflection_strength = v
		_set_param("reflection_strength", v)
## Fine-tune alignment of the mirrored reflection.
@export var reflection_offset := Vector2.ZERO:
	set(v):
		reflection_offset = v
		_set_param("reflection_offset", v)

@export_group("Sun glint (Phase 5)")
## Sun/moon position in screen UV — the glint streak sits under this x. Set from the
## TimeOfDay; [SkyController] re-pushes it as the sun moves.
@export var sun_uv := Vector2(0.5, 0.2):
	set(v):
		sun_uv = v
		_set_param("sun_uv", v)
## Tint of the glint (the sun/moon light color).
@export var sun_color := Color(1.0, 0.97, 0.9):
	set(v):
		sun_color = v
		_set_param("sun_color", v)
## Strength of the shimmering specular streak under the sun (0 = none). Lowered at night.
@export_range(0.0, 1.0) var glint_strength := 0.3:
	set(v):
		glint_strength = v
		_set_param("glint_strength", v)
## Intensity of rain-ripple rings on the surface. Usually driven by rain (see below).
@export_range(0.0, 1.0) var rain_ripple := 0.0:
	set(v):
		rain_ripple = v
		_set_param("rain_ripple", v)

@export_group("Weather response")
## When true (at runtime), connect to a SkySetting in the "SkySetting" group so rain darkens
## and roughens the water. Editor preview is unaffected.
@export var react_to_weather := true
## How strongly rain affects the water (0 = ignore, 1 = full storm at max rain).
@export_range(0.0, 1.0) var weather_influence := 0.6

@export_group("Terrain (Phase 2)")
## When true, sample [member terrain_mask] so water only appears where there is no land.
@export var use_terrain_mask := false:
	set(v):
		use_terrain_mask = v
		_set_param("use_terrain_mask", v)
## Optional mask: red > 0.5 marks land. Lets water align with real terrain (Phase 2).
@export var terrain_mask: Texture2D:
	set(v):
		terrain_mask = v
		_set_param("terrain_mask", v)


## Storm target the palette darkens toward at full rain.
const _STORM_COLOR := Color(0.06, 0.10, 0.16)

# Base values captured at runtime so weather modulation is always computed from the
# authored look rather than drifting each frame.
var _base_deep: Color
var _base_shallow: Color
var _base_foam: float
var _base_wave_height: float
var _last_rain := 0.0  # most recent rain amount, so a day-palette change re-modulates correctly


func _enter_tree() -> void:
	_ensure_material()
	_apply_all()


func _ready() -> void:
	if Engine.is_editor_hint() or not react_to_weather:
		return
	_base_deep = deep_color
	_base_shallow = shallow_color
	_base_foam = foam_amount
	_base_wave_height = wave_height
	var sky := get_tree().get_first_node_in_group("SkySetting")
	if sky != null and sky.has_signal("updateRainAmount"):
		sky.updateRainAmount.connect(_on_rain_amount)


## Rain darkens/desaturates the palette, raises foam + wave height, and rings the surface.
func _on_rain_amount(rain_amount: float) -> void:
	_last_rain = clampf(rain_amount, 0.0, 1.0)
	var r := _last_rain * weather_influence
	deep_color = _base_deep.lerp(_STORM_COLOR, 0.5 * r)
	shallow_color = _base_shallow.lerp(_STORM_COLOR, 0.4 * r)
	foam_amount = clampf(_base_foam + 0.4 * r, 0.0, 1.0)
	wave_height = _base_wave_height + 0.03 * r
	rain_ripple = _last_rain   # ripple density tracks how hard it's raining


## Re-base the authored water palette (used by the day-night cycle) and immediately re-apply
## the current rain modulation, so the water color tracks the time of day. See [SkyController].
func set_day_palette(new_deep: Color, new_shallow: Color) -> void:
	_base_deep = new_deep
	_base_shallow = new_shallow
	var r := _last_rain * weather_influence
	deep_color = _base_deep.lerp(_STORM_COLOR, 0.5 * r)
	shallow_color = _base_shallow.lerp(_STORM_COLOR, 0.4 * r)


func _ensure_material() -> void:
	var mat := material as ShaderMaterial
	if mat == null:
		mat = ShaderMaterial.new()
		material = mat
	if mat.shader == null:
		mat.shader = load(_SHADER_PATH)
	if mat.get_shader_parameter("noise_tex") == null:
		mat.set_shader_parameter("noise_tex", _make_noise_texture())


## Build the seamless noise the shader uses for waves and foam.
func _make_noise_texture() -> NoiseTexture2D:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = 0.015
	var tex := NoiseTexture2D.new()
	tex.width = 256
	tex.height = 256
	tex.seamless = true
	tex.noise = n
	return tex


func _set_param(param: String, value: Variant) -> void:
	var mat := material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter(param, value)


## Push every exported value to the shader (used once the material exists).
func _apply_all() -> void:
	_set_param("mode", int(mode))
	_set_param("deep_color", deep_color)
	_set_param("shallow_color", shallow_color)
	_set_param("foam_color", foam_color)
	_set_param("water_opacity", water_opacity)
	_set_param("wave_scale", wave_scale)
	_set_param("wave_speed", wave_speed)
	_set_param("wave_distortion", wave_distortion)
	_set_param("wave_height", wave_height)
	_set_param("wave_frequency", wave_frequency)
	_set_param("level", level)
	_set_param("flow_direction", flow_direction)
	_set_param("flow_speed", flow_speed)
	_set_param("foam_amount", foam_amount)
	_set_param("foam_width", foam_width)
	_set_param("swell_height", swell_height)
	_set_param("swell_speed", swell_speed)
	_set_param("reflection_enabled", reflection_enabled)
	_set_param("reflection_strength", reflection_strength)
	_set_param("reflection_offset", reflection_offset)
	_set_param("sun_uv", sun_uv)
	_set_param("sun_color", sun_color)
	_set_param("glint_strength", glint_strength)
	_set_param("rain_ripple", rain_ripple)
	_set_param("use_terrain_mask", use_terrain_mask)
	if terrain_mask != null:
		_set_param("terrain_mask", terrain_mask)
