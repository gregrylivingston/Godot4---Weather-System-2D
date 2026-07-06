@tool
class_name WeatherScene
extends RefCounted
## Fluent, code-first builder for Weather System 2D scenes.
##
## Assemble a sky + parallax terrain bands + water in a few chained calls, then [method
## build] a ready-to-add node tree. Everything is deterministic for a given seed, so the
## same call reproduces the same scene across runs and projects.
##
## [codeblock]
## var scene := WeatherScene.new() \
##     .set_seed(1234) \
##     .weather(WeatherPreset.overcast_dusk()) \
##     .terrain([
##         TerrainLayer.mountains(),
##         TerrainLayer.hills(),
##         TerrainLayer.ground(),
##     ]) \
##     .water(WaterBody2D.Mode.OCEAN_BEACH) \
##     .build()
## add_child(scene)
## [/codeblock]

var _seed := 0
var _size := Vector2(1920, 1080)
var _sky_top := Color(0.40, 0.62, 0.85)
var _sky_bottom := Color(0.72, 0.85, 0.94)
var _layers: Array[TerrainLayer] = []
var _weather: WeatherPreset = null
var _include_water := true
var _water_mode := WaterBody2D.Mode.OCEAN_BEACH
var _water_level := 0.66


func set_seed(s: int) -> WeatherScene:
	_seed = s
	return self


func set_size(sz: Vector2) -> WeatherScene:
	_size = sz
	return self


## Override the sky gradient colors directly (otherwise taken from the weather preset).
func sky(top: Color, bottom: Color) -> WeatherScene:
	_sky_top = top
	_sky_bottom = bottom
	return self


## Apply an atmosphere preset (also sets the sky + water palette).
func weather(preset: WeatherPreset) -> WeatherScene:
	_weather = preset
	if preset != null:
		_sky_top = preset.sky_top
		_sky_bottom = preset.sky_bottom
	return self


## Replace the terrain stack (back-to-front: mountains first … foreground last).
func terrain(layers: Array) -> WeatherScene:
	_layers.clear()
	for l in layers:
		if l is TerrainLayer:
			_layers.append(l)
	return self


func add_terrain(layer: TerrainLayer) -> WeatherScene:
	if layer != null:
		_layers.append(layer)
	return self


func water(mode: int = WaterBody2D.Mode.OCEAN_BEACH, level: float = 0.66) -> WeatherScene:
	_include_water = true
	_water_mode = mode
	_water_level = level
	return self


func no_water() -> WeatherScene:
	_include_water = false
	return self


## Load an entire composition from a saved [ScenePreset].
func from_preset(preset: ScenePreset) -> WeatherScene:
	if preset == null:
		return self
	_seed = preset.scene_seed
	_size = preset.size
	if preset.weather != null:
		weather(preset.weather)
	terrain(preset.terrain)
	_include_water = preset.include_water
	_water_mode = preset.water_mode
	_water_level = preset.water_level
	return self


## Build the node tree. Returns a [Node2D] you can add to your scene.
func build() -> Node2D:
	var w := _size.x
	var h := _size.y

	var root := Node2D.new()
	root.name = "GeneratedWeatherScene"

	var cam := Camera2D.new()
	cam.name = "Camera2D"
	root.add_child(cam)

	var sky := TextureRect.new()
	sky.name = "Sky"
	sky.texture = _make_sky_gradient()
	sky.position = Vector2(-w * 0.5, -h * 0.5)
	sky.size = _size
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(sky)

	# Find a ground layer so the water can share its coastline.
	var ground: TerrainLayer = null
	for l in _layers:
		if l != null and l.role == TerrainLayer.Role.GROUND:
			ground = l
			break

	var idx := 0
	for src in _layers:
		if src == null:
			continue
		var layer := src.duplicate() as TerrainLayer
		layer.seed = _seed + idx # deterministic per-band variation
		var band := TerrainBand2D.new()
		band.name = "Band%d_%s" % [idx, _role_name(layer.role)]
		band.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var r := _band_rect(layer.role, w, h)
		band.position = r.position
		band.size = r.size
		band.layer = layer
		root.add_child(band)
		idx += 1

	if _include_water:
		var body := WaterBody2D.new()
		body.name = "Water"
		body.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.mode = _water_mode
		var wr := _band_rect(TerrainLayer.Role.GROUND, w, h)
		body.position = wr.position
		body.size = wr.size
		if ground != null:
			# Waterline sits below the sand top so a beach shows; share the wave shape.
			body.level = clampf(ground.coast_level + 0.26, 0.0, 1.0)
			body.wave_height = ground.wave_height
			body.wave_frequency = ground.wave_frequency
		else:
			body.level = _water_level
		if _weather != null:
			body.deep_color = _weather.water_deep
			body.shallow_color = _weather.water_shallow
			body.foam_amount = clampf(0.55 + _weather.rain * 0.35, 0.0, 1.0)
			body.wave_height += _weather.rain * 0.02
		root.add_child(body)

	return root


# --- internals -------------------------------------------------------------

## Vertical placement per role, in the centered coordinate space the Camera2D sits in.
func _band_rect(role: int, w: float, h: float) -> Rect2:
	match role:
		TerrainLayer.Role.MOUNTAIN:
			return Rect2(-w * 0.5, -h * 0.35, w, h * 0.47)
		TerrainLayer.Role.HILL:
			return Rect2(-w * 0.5, -h * 0.08, w, h * 0.32)
		TerrainLayer.Role.TREELINE:
			return Rect2(-w * 0.5, -h * 0.02, w, h * 0.30)
		TerrainLayer.Role.FOREGROUND:
			return Rect2(-w * 0.5, h * 0.05, w, h * 0.45)
		_: # GROUND and default
			return Rect2(-w * 0.5, -h * 0.05, w, h * 0.55)


func _role_name(role: int) -> String:
	match role:
		TerrainLayer.Role.GROUND: return "ground"
		TerrainLayer.Role.HILL: return "hill"
		TerrainLayer.Role.MOUNTAIN: return "mountain"
		TerrainLayer.Role.TREELINE: return "treeline"
		TerrainLayer.Role.FOREGROUND: return "foreground"
	return "band"


func _make_sky_gradient() -> GradientTexture2D:
	var grad := Gradient.new()
	grad.set_color(0, _sky_top)
	grad.set_color(1, _sky_bottom)
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 8
	tex.height = 256
	tex.fill_from = Vector2(0.0, 0.0)
	tex.fill_to = Vector2(0.0, 1.0)
	return tex
