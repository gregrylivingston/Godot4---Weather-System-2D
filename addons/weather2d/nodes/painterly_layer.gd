@tool
class_name PainterlyLayer
extends CanvasLayer
## A full-screen painterly post-process for the Weather System 2D kit.
##
## Drop one into a scene (or let [WeatherScene] add it) and everything drawn beneath it gets
## a soft-focus blur, a hint of warmth, a faint paper grain, and a gentle vignette — nudging
## the whole frame toward a soft painting. It owns an internal full-rect overlay, so no setup
## is needed. Sits on a high [member CanvasLayer.layer] so it draws last.

const _SHADER := "res://addons/weather2d/shaders/painterly.gdshader"

@export_range(0.0, 3.0) var softness := 1.0:
	set(v):
		softness = v
		_set_param("softness", v)
@export_range(0.0, 1.0) var blur_mix := 0.55:
	set(v):
		blur_mix = v
		_set_param("blur_mix", v)
@export_range(0.0, 0.15) var grain := 0.035:
	set(v):
		grain = v
		_set_param("grain", v)
@export_range(0.0, 1.0) var vignette := 0.22:
	set(v):
		vignette = v
		_set_param("vignette", v)
@export_range(-0.08, 0.08) var warmth := 0.015:
	set(v):
		warmth = v
		_set_param("warmth", v)


func _enter_tree() -> void:
	layer = 10 # draw on top of the scene
	_ensure_overlay()
	_apply_all()


func _ensure_overlay() -> void:
	var rect := get_node_or_null("Overlay") as ColorRect
	if rect == null:
		rect = ColorRect.new()
		rect.name = "Overlay"
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mat := ShaderMaterial.new()
		mat.shader = load(_SHADER)
		rect.material = mat
		add_child(rect)


func _overlay_material() -> ShaderMaterial:
	var rect := get_node_or_null("Overlay") as ColorRect
	if rect != null:
		return rect.material as ShaderMaterial
	return null


func _set_param(param: String, value: Variant) -> void:
	var mat := _overlay_material()
	if mat != null:
		mat.set_shader_parameter(param, value)


func _apply_all() -> void:
	_set_param("softness", softness)
	_set_param("blur_mix", blur_mix)
	_set_param("grain", grain)
	_set_param("vignette", vignette)
	_set_param("warmth", warmth)
