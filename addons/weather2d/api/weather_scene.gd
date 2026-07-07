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
##     .time_of_day(TimeOfDay.golden_hour()) \
##     .weather(WeatherPreset.stormy()) \
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
var _layers: Array[TerrainLayer] = []
var _tod: TimeOfDay = null
var _weather: WeatherPreset = null
var _include_water := true
var _water_mode := WaterBody2D.Mode.OCEAN_BEACH
var _water_level := 0.66
var _sea_bands: Array = []  # extra distant open-water bands (back-to-front) for open-sea scenes
var _scatter_props := false
var _prop_count := 16
var _prop_textures: Array[Texture2D] = []
var _scatter_birds := false
var _bird_count := 5
var _painterly := false
var _painterly_saturation := 1.0   # <1 mutes the frame toward an aged, period-illustration grade
var _painterly_warmth := 0.015     # gentle warm cast (matches the painterly shader default)
var _rain_amount := -1.0  # <0 = follow the weather preset
var _fog_amount := -1.0
var _wind_amount := -1.0
var _cloud_amount := -1.0
var _snow_force := -1     # -1 follow preset, 0 off, 1 on
var _cloud_style: CloudPreset = null
var _wind_effective := 0.3
var _live := false          # add a SkyController so the scene animates at runtime
var _day_night_speed := 0.0
var _lightning := false
var _low_graphics := false  # cheap shader paths + skip pricey overlays (weak/software renderers)
var _haze_color := Color(0.72, 0.80, 0.88) # depth-fade color for props (from the ToD sky)
var _fog_color := Color(0.82, 0.85, 0.88)

const _DEFAULT_FOLIAGE_PATHS := [
	"res://assets/svg/tree_round.svg",
	"res://assets/svg/tree_pine.svg",
	"res://assets/svg/tree_palm.svg",
	"res://assets/svg/bush.svg",
]
const _DEFAULT_ACCENT_PATHS := [
	"res://assets/svg/rock.svg",
	"res://assets/svg/driftwood.svg",
]
const _BIRD_PATH := "res://assets/svg/bird.svg"
const _RAIN_SHADER := "res://addons/weather2d/shaders/rain.gdshader"
const _FOG_SHADER := "res://addons/weather2d/shaders/fog.gdshader"
const _CLOUD_SHADER := "res://addons/weather2d/shaders/clouds.gdshader"
const _SKY_SHADER := "res://addons/weather2d/shaders/sky.gdshader"
const _CLOUD_SHADOW_SHADER := "res://addons/weather2d/shaders/cloud_shadow.gdshader"


func set_seed(s: int) -> WeatherScene:
	_seed = s
	return self


func set_size(sz: Vector2) -> WeatherScene:
	_size = sz
	return self


## Set the time of day — sky & water palette, cloud/fog tint, ambient light. See [TimeOfDay].
func time_of_day(tod: TimeOfDay) -> WeatherScene:
	_tod = tod
	return self


## Set the weather conditions — rain / snow / fog / clouds / wind. See [WeatherPreset].
func weather(preset: WeatherPreset) -> WeatherScene:
	_weather = preset
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


## Add a distant band of open water (waves only, no shore) behind the near water — layer a few
## to build an open-sea horizon out of receding wave bands instead of flat land. [param top] /
## [param bottom] are screen fractions (0 top … 1 bottom); add back-to-front. `opts`: level
## (0 = fill the whole band), wave_scale, wave_height, opacity, haze (0..1, fade toward the sky
## for atmospheric distance), glint:bool.
func sea_band(top: float, bottom: float, opts: Dictionary = {}) -> WeatherScene:
	_sea_bands.append({
		"top": top, "bottom": bottom,
		"level": float(opts.get("level", 0.0)),
		"wave_scale": float(opts.get("wave_scale", 8.0)),
		"wave_height": float(opts.get("wave_height", 0.02)),
		"opacity": float(opts.get("opacity", 0.92)),
		"haze": float(opts.get("haze", 0.0)),
		"glint": bool(opts.get("glint", true)),
	})
	return self


## Scatter vector props (trees/rocks) along the shoreline. Pass your own textures, or leave
## empty to use the kit's default SVG set.
func props(enable := true, count := 16, textures: Array = []) -> WeatherScene:
	_scatter_props = enable
	_prop_count = count
	_prop_textures.clear()
	for t in textures:
		if t is Texture2D:
			_prop_textures.append(t)
	return self


## Scatter a few birds across the upper sky.
func birds(enable := true, count := 5) -> WeatherScene:
	_scatter_birds = enable
	_bird_count = count
	return self


## Force a rain overlay amount (0 = none, 1 = downpour). Negative follows the weather preset.
func rain(amount: float) -> WeatherScene:
	_rain_amount = amount
	return self


## Override fog density (0..1). Negative follows the weather preset.
func fog(amount: float) -> WeatherScene:
	_fog_amount = amount
	return self


## Override wind (0..1) — drives foliage sway and rain slant. Negative follows the preset.
func wind(amount: float) -> WeatherScene:
	_wind_amount = amount
	return self


## Override cloud coverage (0..1). Negative follows the cloud style / weather preset.
func clouds(amount: float) -> WeatherScene:
	_cloud_amount = amount
	return self


## Set the cloud style — coverage, scale, shading, softness, detail. See [CloudPreset].
func cloud_style(preset: CloudPreset) -> WeatherScene:
	_cloud_style = preset
	return self


## Force snow on/off. By default snow follows the weather preset.
func snow(on: bool) -> WeatherScene:
	_snow_force = 1 if on else 0
	return self


## Add the painterly post-process (soft focus + grain + vignette) on top of the scene.
## [param saturation] below 1.0 mutes the frame and [param warmth] warms it, giving an aged,
## period-illustration grade — a gentle nudge toward Lost Settlement's look without restyling
## the scene into a flat map. The defaults reproduce the plain painterly pass.
func painterly(enable := true, saturation := 1.0, warmth := 0.015) -> WeatherScene:
	_painterly = enable
	_painterly_saturation = saturation
	_painterly_warmth = warmth
	return self


## Make the scene [b]live[/b] (Phase 5): add a [SkyController] that animates the sky, weather
## and water at runtime. [param day_night_speed] is whole days per second (0 = a fixed hour,
## the sun still glints and clouds/rain still move). Enabling this also always builds the
## cloud / fog / rain overlays so a weather transition can bring them in.
func live(enable := true, day_night_speed := 0.0) -> WeatherScene:
	_live = enable
	_day_night_speed = day_night_speed
	return self


## Emit occasional lightning flashes while it storms (only meaningful with [method live]).
func lightning(enable := true) -> WeatherScene:
	_lightning = enable
	return self


## Low-graphics mode for weak or software (no-GPU) renderers. The clouds/water/rain/fog shaders
## take cheap paths (fewer octaves, no screen reflection, thinner rain, flat fog), the cloud
## shadow and painterly post-process are skipped, and fewer props are scattered. The look is
## simplified but the composition is the same.
func low_graphics(enable := true) -> WeatherScene:
	_low_graphics = enable
	return self


## Capture this builder's current configuration as a [ScenePreset] — the inverse of
## [method from_preset]. Round-trips exactly: `WeatherScene.new().from_preset(ws.to_preset())`
## rebuilds the same scene. (To capture an already-built or hand-authored tree instead, use
## [method ScenePreset.from_scene].)
func to_preset() -> ScenePreset:
	var p := ScenePreset.new()
	p.scene_seed = _seed
	p.size = _size
	p.time_of_day = _tod
	p.weather = _weather
	var out: Array[TerrainLayer] = []
	for l in _layers:
		out.append(l)
	p.terrain = out
	p.include_water = _include_water
	p.water_mode = _water_mode
	p.water_level = _water_level
	return p


## Load an entire composition from a saved [ScenePreset].
func from_preset(preset: ScenePreset) -> WeatherScene:
	if preset == null:
		return self
	_seed = preset.scene_seed
	_size = preset.size
	if preset.time_of_day != null:
		time_of_day(preset.time_of_day)
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

	# Time of day sets the palette; weather modulates it (storms darken & grey it out).
	var tod: TimeOfDay = _tod if _tod != null else TimeOfDay.noon()
	var darken: float = _weather.darken if _weather != null else 0.0
	var desat: float = _weather.desaturate if _weather != null else 0.0

	_haze_color = _pal(tod.sky_bottom, darken, desat)
	_fog_color = tod.fog_color

	# Material/node refs the SkyController drives when the scene is live (Phase 5).
	var sky_mat: ShaderMaterial = null
	var cloud_mat: ShaderMaterial = null
	var cloud_shadow_mat: ShaderMaterial = null
	var fog_mat: ShaderMaterial = null
	var rain_mat: ShaderMaterial = null
	var ambient_node: CanvasModulate = null
	var lightning_rect: ColorRect = null
	var water_body: WaterBody2D = null
	var q := 0 if _low_graphics else 1  # shader quality (0 = low graphics)

	# Scene-wide ambient tint (night dims everything; storms darken it further).
	var ambient := tod.ambient.lerp(Color(0.35, 0.37, 0.44), darken * 0.6)
	if _live or ambient != Color.WHITE:
		ambient_node = CanvasModulate.new()
		ambient_node.name = "Ambient"
		ambient_node.color = ambient
		root.add_child(ambient_node)

	# Sky: a shader (not a flat gradient) with a sun/moon disc, glow, and night stars, all
	# from the unified sun model on the TimeOfDay.
	var sky := ColorRect.new()
	sky.name = "Sky"
	sky.position = Vector2(-w * 0.5, -h * 0.5)
	sky.size = _size
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky_mat = ShaderMaterial.new()
	sky_mat.shader = load(_SKY_SHADER)
	sky_mat.set_shader_parameter("sky_top", _pal(tod.sky_top, darken, desat))
	sky_mat.set_shader_parameter("sky_bottom", _pal(tod.sky_bottom, darken, desat))
	sky_mat.set_shader_parameter("sun_uv", tod.sun_uv)
	sky_mat.set_shader_parameter("sun_color", tod.sun_color)
	sky_mat.set_shader_parameter("star_intensity", tod.star_intensity)
	sky_mat.set_shader_parameter("aspect", w / maxf(h, 1.0))
	sky_mat.set_shader_parameter("horizon", 0.62)
	sky.material = sky_mat
	root.add_child(sky)

	# Effective weather values (explicit override, else the preset, else a default).
	var eff_fog: float = _fog_amount if _fog_amount >= 0.0 else (_weather.fog if _weather != null else 0.0)
	var eff_snow: bool = (_snow_force == 1) if _snow_force >= 0 else (_weather.snow if _weather != null else false)
	_wind_effective = _wind_amount if _wind_amount >= 0.0 else (_weather.wind if _weather != null else 0.3)
	var rain_amt: float = _rain_amount if _rain_amount >= 0.0 else (_weather.rain if _weather != null else 0.0)

	# Clouds: style from the cloud preset (default scattered); coverage from the style, or an
	# explicit .clouds() override, or the weather's cloud amount. Color from the time of day,
	# darkened by the weather. Layered fBm shader, drawn over the sky and behind the terrain.
	var style: CloudPreset = _cloud_style if _cloud_style != null else CloudPreset.scattered()
	var cloud_cov := style.coverage
	if _cloud_amount >= 0.0:
		cloud_cov = lerpf(-0.3, 0.7, _cloud_amount)
	elif _cloud_style == null and _weather != null:
		cloud_cov = lerpf(-0.3, 0.7, _weather.clouds)
	# Rain implies an overcast sky — you don't get heavy rain from clear blue, so raise the cloud
	# cover to at least match the rain. This makes the weather read as *caused* by the sky.
	cloud_cov = maxf(cloud_cov, lerpf(-0.3, 0.7, clampf(rain_amt, 0.0, 1.0)))
	# Normalized 0..1 coverage (inverse of the lerp above) for the cloud-shadow pass.
	var cloud01 := clampf(cloud_cov + 0.3, 0.0, 1.0)
	if _live or cloud_cov > -0.3:
		var cloud_rect := ColorRect.new()
		cloud_rect.name = "Clouds"
		cloud_rect.position = Vector2(-w * 0.5, -h * 0.5)
		cloud_rect.size = _size
		cloud_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cloud_mat = ShaderMaterial.new()
		cloud_mat.shader = load(_CLOUD_SHADER)
		cloud_mat.set_shader_parameter("coverage", cloud_cov)
		cloud_mat.set_shader_parameter("cloud_scale", style.scale)
		cloud_mat.set_shader_parameter("speed", style.speed)
		cloud_mat.set_shader_parameter("cloud_dark", style.dark * (1.0 - darken * 0.3))
		cloud_mat.set_shader_parameter("cloud_light", style.light * (1.0 - darken * 0.45))
		cloud_mat.set_shader_parameter("density", style.density)
		cloud_mat.set_shader_parameter("softness", style.softness)
		cloud_mat.set_shader_parameter("detail", style.detail)
		cloud_mat.set_shader_parameter("horizon", 0.62)
		cloud_mat.set_shader_parameter("cloud_color", _pal(tod.cloud_color, darken, desat))
		cloud_mat.set_shader_parameter("sun_uv", tod.sun_uv)
		cloud_mat.set_shader_parameter("sun_tint", tod.sun_color)
		cloud_mat.set_shader_parameter("wind_dir", Vector2(1.0, 0.12))
		cloud_mat.set_shader_parameter("quality", q)
		cloud_rect.material = cloud_mat
		root.add_child(cloud_rect)

	# Find a ground layer so the water can share its coastline.
	var ground: TerrainLayer = null
	for l in _layers:
		if l != null and l.role == TerrainLayer.Role.GROUND:
			ground = l
			break

	# Background terrain (everything except FOREGROUND, which is placed in front of water).
	var role_seen := {}
	for i in _layers.size():
		var src: TerrainLayer = _layers[i]
		if src == null or src.role == TerrainLayer.Role.FOREGROUND:
			continue
		var occ: int = role_seen.get(src.role, 0)
		role_seen[src.role] = occ + 1
		_add_band(root, src, i, occ, w, h)

	if _include_water:
		var body := WaterBody2D.new()
		body.name = "Water"
		body.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.mode = _water_mode
		# A river is a horizontal band with land above and below; others fill to the bottom.
		var wr := _band_rect(TerrainLayer.Role.GROUND, w, h)
		if _water_mode == WaterBody2D.Mode.RIVER:
			wr = _rect_f(0.62, 0.82, w, h)
		body.position = wr.position
		body.size = wr.size
		if ground != null:
			# Waterline sits just below the sand top so a beach shows; share the wave shape.
			body.level = clampf(ground.coast_level + 0.14, 0.0, 1.0)
			body.wave_height = ground.wave_height
			body.wave_frequency = ground.wave_frequency
			body.foam_width = 0.045
		else:
			body.level = _water_level
		body.deep_color = _pal(tod.water_deep, darken, desat)
		body.shallow_color = _pal(tod.water_shallow, darken, desat)
		# Sun glint tracks the sun; the moon barely glints, so fade it out at night.
		body.sun_uv = tod.sun_uv
		body.sun_color = tod.sun_color
		body.glint_strength = clampf(0.35 * (1.0 - tod.star_intensity), 0.0, 1.0)
		body.low_graphics = _low_graphics
		if _weather != null:
			body.foam_amount = clampf(0.45 + _weather.rain * 0.35, 0.0, 1.0)
			body.wave_height += _weather.rain * 0.02
			body.rain_ripple = _weather.rain
		if _live:
			body.weather_source = NodePath("../SkyController")  # explicit, not group-timing dependent
		root.add_child(body)
		water_body = body

	# Distant open-sea wave bands: added back-to-front so each near band laps over the one
	# behind it, building a layered-wave horizon (used by the Open Sea scenario).
	var sky_haze := _pal(tod.sky_top, darken, desat)
	for b in _sea_bands:
		var sea := WaterBody2D.new()
		sea.name = "SeaBand"
		sea.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sea.mode = WaterBody2D.Mode.STILL
		var sr := _rect_f(float(b["top"]), float(b["bottom"]), w, h)
		sea.position = sr.position
		sea.size = sr.size
		sea.level = float(b["level"])
		sea.wave_scale = float(b["wave_scale"])
		sea.wave_height = float(b["wave_height"])
		sea.water_opacity = float(b["opacity"])
		var haze := float(b["haze"])
		sea.deep_color = _pal(tod.water_deep, darken, desat).lerp(sky_haze, haze)
		sea.shallow_color = _pal(tod.water_shallow, darken, desat).lerp(sky_haze, haze)
		sea.sun_uv = tod.sun_uv
		sea.sun_color = tod.sun_color
		sea.glint_strength = clampf(0.35 * (1.0 - tod.star_intensity), 0.0, 1.0) if bool(b["glint"]) else 0.0
		sea.foam_amount = 0.15
		sea.foam_width = 0.03
		sea.low_graphics = _low_graphics
		if _weather != null:
			sea.rain_ripple = _weather.rain
		if _live:
			sea.weather_source = NodePath("../SkyController")
		root.add_child(sea)
		if water_body == null:
			water_body = sea  # let the SkyController drive at least the nearest band when live

	# Foreground terrain draws in front of the water (e.g. a near river bank).
	for i in _layers.size():
		var src: TerrainLayer = _layers[i]
		if src == null or src.role != TerrainLayer.Role.FOREGROUND:
			continue
		var occ: int = role_seen.get(src.role, 0)
		role_seen[src.role] = occ + 1
		_add_band(root, src, i, occ, w, h)

	if _scatter_props:
		_add_prop_rows(root, w, h)

	if _scatter_birds:
		var flock := PropScatter2D.new()
		flock.name = "Birds"
		flock.seed = _seed + 200
		flock.count = _bird_count if not _low_graphics else maxi(1, int(_bird_count / 2))
		flock.width = w * 0.8
		flock.band_height = h * 0.16
		flock.position = Vector2(-w * 0.05, (0.28 - 0.5) * h)
		flock.scale_min = 0.25
		flock.scale_max = 0.55
		flock.depth_scale = false
		flock.flip_random = false
		flock.tint_variation = 0.25
		flock.haze_amount = 0.5
		flock.haze_color = _pal(tod.sky_top, darken, desat)
		flock.animation = PropScatter2D.ANIM_FLY
		var bird := load(_BIRD_PATH)
		if bird is Texture2D:
			flock.textures = [bird]
		root.add_child(flock)

	# Moving cloud shadows dapple the land & water (drift with the wind, below the horizon).
	# Skipped entirely in low graphics (a full-screen noise pass).
	if not _low_graphics and (_live or cloud01 > 0.25):
		var shadow_rect := ColorRect.new()
		shadow_rect.name = "CloudShadow"
		shadow_rect.position = Vector2(-w * 0.5, -h * 0.5)
		shadow_rect.size = _size
		shadow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cloud_shadow_mat = ShaderMaterial.new()
		cloud_shadow_mat.shader = load(_CLOUD_SHADOW_SHADER)
		cloud_shadow_mat.set_shader_parameter("coverage", cloud01)
		cloud_shadow_mat.set_shader_parameter("wind_dir", Vector2(1.0, 0.12))
		cloud_shadow_mat.set_shader_parameter("horizon", 0.5)
		shadow_rect.material = cloud_shadow_mat
		root.add_child(shadow_rect)

	# Fog / distance haze over the scene (under rain and painterly).
	if _live or eff_fog > 0.02:
		var fog_layer := CanvasLayer.new()
		fog_layer.name = "Fog"
		fog_layer.layer = 7
		var fog_rect := ColorRect.new()
		fog_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		fog_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fog_mat = ShaderMaterial.new()
		fog_mat.shader = load(_FOG_SHADER)
		fog_mat.set_shader_parameter("density", eff_fog)
		fog_mat.set_shader_parameter("fog_color", _fog_color)
		fog_mat.set_shader_parameter("quality", q)
		fog_rect.material = fog_mat
		fog_layer.add_child(fog_rect)
		root.add_child(fog_layer)

	# Rain / snow overlay (uses the effective rain computed above).
	if _live or rain_amt > 0.02:
		var rain_layer := CanvasLayer.new()
		rain_layer.name = "Rain"
		rain_layer.layer = 8
		var rain_rect := ColorRect.new()
		rain_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		rain_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rain_mat = ShaderMaterial.new()
		rain_mat.shader = load(_RAIN_SHADER)
		rain_mat.set_shader_parameter("amount", rain_amt)
		rain_mat.set_shader_parameter("snow", eff_snow)
		rain_mat.set_shader_parameter("slant", -0.02 - _wind_effective * 0.18)
		rain_mat.set_shader_parameter("quality", q)
		rain_rect.material = rain_mat
		rain_layer.add_child(rain_rect)
		root.add_child(rain_layer)

	# Lightning flash layer (driven by the SkyController while it storms).
	if _live and _lightning:
		var l_layer := CanvasLayer.new()
		l_layer.name = "Lightning"
		l_layer.layer = 9
		lightning_rect = ColorRect.new()
		lightning_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		lightning_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lightning_rect.color = Color(0.9, 0.94, 1.0, 0.0)
		l_layer.add_child(lightning_rect)
		root.add_child(l_layer)

	# Painterly is a full-screen multi-tap blur — skipped in low graphics. The optional grade
	# (muted saturation + warmth) rides on the same pass, so the period look is free.
	if _painterly and not _low_graphics:
		var paint := PainterlyLayer.new()
		paint.saturation = _painterly_saturation
		paint.warmth = _painterly_warmth
		root.add_child(paint)

	# The runtime brain: animates sky/weather/water and (via the "SkySetting" group) drives
	# the water's weather reaction. See SkyController.
	if _live:
		var ctrl := SkyController.new()
		ctrl.name = "SkyController"
		ctrl.size = _size
		ctrl.base_time = tod
		ctrl.cloud_style = style
		ctrl.day_night_speed = _day_night_speed
		ctrl.time_cycle_enabled = _day_night_speed != 0.0
		ctrl.day01 = tod.day  # start the cycle at the chosen time of day
		ctrl.lightning_enabled = _lightning
		ctrl.sky_material = sky_mat
		ctrl.cloud_material = cloud_mat
		ctrl.cloud_shadow_material = cloud_shadow_mat
		ctrl.fog_material = fog_mat
		ctrl.rain_material = rain_mat
		ctrl.water = water_body
		ctrl.ambient = ambient_node
		ctrl.lightning_rect = lightning_rect
		ctrl.set_weather(_weather if _weather != null else WeatherPreset.clear())
		root.add_child(ctrl)

	return root


# --- build helpers ---------------------------------------------------------

func _add_band(root: Node2D, src: TerrainLayer, i: int, occ: int, w: float, h: float) -> void:
	var layer := src.duplicate() as TerrainLayer
	layer.seed = _seed + i # deterministic per-band variation
	var band := TerrainBand2D.new()
	band.name = "Band%d_%s" % [i, _role_name(layer.role)]
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var r := _band_rect(layer.role, w, h)
	# Later bands of the same role sit a little lower (nearer) for layered depth.
	r.position.y += float(occ) * h * 0.055
	band.position = r.position
	band.size = r.size
	band.layer = layer
	root.add_child(band)


func _load_textures(paths: Array) -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	for p in paths:
		var t := load(p)
		if t is Texture2D:
			out.append(t)
	return out


# Per-role planting: where props sit on each layer, how big, how hazy, and how many. Depth is
# the through-line — the further back a row is, the SMALLER and DENSER (higher count_mul) and
# hazier its props, so the back reads as a fine distant forest and the front as a few big
# trees. MOUNTAIN is deliberately absent: the distant peaks stay bare (no props on them).
# `anchor` rows (the silhouette hills / treeline) plant on the band's actual ridge instead of
# a flat screen line, so nothing floats above the terrain where the ridge dips.
const _ROW_CONFIG := {
	TerrainLayer.Role.HILL:       {"line": 0.520, "smin": 0.13, "smax": 0.24, "haze": 0.60, "band": 0.030, "count_mul": 2.0, "accents": false, "anchor": true},
	TerrainLayer.Role.TREELINE:   {"line": 0.560, "smin": 0.24, "smax": 0.40, "haze": 0.48, "band": 0.035, "count_mul": 1.5, "accents": false, "anchor": true},
	TerrainLayer.Role.GROUND:     {"line": 0.655, "smin": 0.52, "smax": 0.92, "haze": 0.25, "band": 0.050, "count_mul": 0.85, "accents": true, "anchor": false},
	TerrainLayer.Role.FOREGROUND: {"line": 0.850, "smin": 0.90, "smax": 1.35, "haze": 0.10, "band": 0.050, "count_mul": 0.55, "accents": true, "anchor": false},
}


## Plant props on each terrain layer, anchored to that layer's surface and scaled by depth.
func _add_prop_rows(root: Node2D, w: float, h: float) -> void:
	var haze_col: Color = _haze_color
	var override: Array[Texture2D] = _prop_textures.duplicate()
	var foliage: Array[Texture2D] = override if not override.is_empty() else _load_textures(_DEFAULT_FOLIAGE_PATHS)
	var accents: Array[Texture2D] = _load_textures(_DEFAULT_ACCENT_PATHS)

	# The lowest y (deepest on screen) an anchored back-row prop may reach: the waterline.
	# A back band's ridge can sit *below* the water (hidden under it), and planting a prop on
	# that hidden ridge would stand it in open water — so clamp anchored rows to the shore.
	var land_floor_y := INF
	if _include_water:
		if _water_mode == WaterBody2D.Mode.RIVER:
			land_floor_y = _rect_f(0.62, 0.82, w, h).position.y - h * 0.006
		else:
			var gnd: TerrainLayer = null
			for l in _layers:
				if l != null and l.role == TerrainLayer.Role.GROUND:
					gnd = l
					break
			var wr := _band_rect(TerrainLayer.Role.GROUND, w, h)
			var lvl: float = (gnd.coast_level + 0.14) if gnd != null else _water_level
			land_floor_y = wr.position.y + clampf(lvl, 0.0, 1.0) * wr.size.y - h * 0.006

	# Track how many bands of each role we've seen, matching _add_band's per-role offset, so a
	# row's ridge sampler lines up with the band it plants on (e.g. a scene's two hill bands).
	var role_occ := {}
	var row_n := 0
	for i in _layers.size():
		var src: TerrainLayer = _layers[i]
		if src == null or not _ROW_CONFIG.has(src.role):
			continue
		var occ: int = role_occ.get(src.role, 0)
		role_occ[src.role] = occ + 1
		var cfg: Dictionary = _ROW_CONFIG[src.role]
		var dens := 0.6 if _low_graphics else 1.0
		var count := maxi(2, int(round(_prop_count * float(cfg["count_mul"]) * dens)))
		var scatter_y := (float(cfg["line"]) - 0.5) * h
		# Keep coast/back rows out of the water. The FOREGROUND is exempt — it's the near bank,
		# which in a river scene sits in front of (below) the water on purpose.
		if src.role != TerrainLayer.Role.FOREGROUND:
			scatter_y = minf(scatter_y, land_floor_y)
		# For silhouette back rows, build a curve that returns the ridge y at a given x, so
		# props plant on the terrain rather than a flat line. Mirrors the band geometry.
		var surface := Callable()
		if bool(cfg["anchor"]):
			var band := _band_rect(src.role, w, h)
			band.position.y += float(occ) * h * 0.055     # same nudge _add_band applies
			var lseed := float(_seed + i)                 # matches the band layer's seed
			var lheight: float = src.height
			var lrough: float = src.roughness
			surface = func(local_x: float) -> float:
				var ux := clampf((local_x - band.position.x) / band.size.x, 0.0, 1.0)
				var top := WeatherScene._silhouette_top(lheight, lrough, lseed, ux)
				# Sit just below the crest so trees read as planted on the slope, not balanced
				# on the exact edge; clamp to the shore so none stand in open water; then
				# rebase into the scatter node's local space.
				var sy := band.position.y + top * band.size.y + h * 0.010
				return minf(sy, land_floor_y) - scatter_y
		root.add_child(_make_row("Props%d_%s" % [row_n, _role_name(src.role)],
			_seed + 100 + i * 7, count, w, h, foliage, haze_col, cfg, PropScatter2D.ANIM_SWAY, surface))
		# Rocks/driftwood on the nearer rows (only with the default prop set).
		if override.is_empty() and bool(cfg["accents"]) and not accents.is_empty():
			root.add_child(_make_row("Accents%d" % row_n,
				_seed + 150 + i * 7, maxi(1, count / 5), w, h, accents, haze_col, cfg, PropScatter2D.ANIM_NONE, surface))
		row_n += 1


func _make_row(node_name: String, s: int, count: int, w: float, h: float,
		textures: Array[Texture2D], haze_col: Color, cfg: Dictionary, anim: int,
		surface := Callable()) -> PropScatter2D:
	var scatter := PropScatter2D.new()
	scatter.name = node_name
	scatter.seed = s
	scatter.count = count
	scatter.width = w * 0.94
	scatter.band_height = h * float(cfg["band"])
	scatter.position = Vector2(0.0, (float(cfg["line"]) - 0.5) * h)
	scatter.surface_sampler = surface
	scatter.scale_min = float(cfg["smin"])
	scatter.scale_max = float(cfg["smax"])
	scatter.haze_amount = float(cfg["haze"])
	scatter.haze_color = haze_col
	scatter.cast_shadows = true
	scatter.animation = anim
	scatter.sway_strength = 2.5 + _wind_effective * 8.0
	scatter.sway_speed = 0.8 + _wind_effective * 1.3
	scatter.textures = textures
	return scatter


# --- internals -------------------------------------------------------------

## Vertical placement per role. Bands are expressed as screen fractions (0 top … 1 bottom)
## and converted to the centered coordinate space the Camera2D sits in. Tuned so the horizon
## sits a little below centre: mountains behind, then hills, a sandy beach, and the sea.
func _band_rect(role: int, w: float, h: float) -> Rect2:
	# Band bottoms run deep so each layer's flat base hides behind the layer in front of it
	# (no hard horizontal seam against the sky). The visible ridge is set by the top edge.
	match role:
		TerrainLayer.Role.MOUNTAIN:
			return _rect_f(0.28, 0.85, w, h)
		TerrainLayer.Role.HILL:
			return _rect_f(0.44, 0.85, w, h)
		TerrainLayer.Role.TREELINE:
			return _rect_f(0.50, 0.85, w, h)
		TerrainLayer.Role.FOREGROUND:
			return _rect_f(0.74, 1.0, w, h)
		_: # GROUND and default (also used by the water body)
			return _rect_f(0.46, 1.0, w, h)


func _rect_f(top_f: float, bottom_f: float, w: float, h: float) -> Rect2:
	var y0 := (top_f - 0.5) * h
	var y1 := (bottom_f - 0.5) * h
	return Rect2(-w * 0.5, y0, w, y1 - y0)


func _role_name(role: int) -> String:
	match role:
		TerrainLayer.Role.GROUND: return "ground"
		TerrainLayer.Role.HILL: return "hill"
		TerrainLayer.Role.MOUNTAIN: return "mountain"
		TerrainLayer.Role.TREELINE: return "treeline"
		TerrainLayer.Role.FOREGROUND: return "foreground"
	return "band"


## Apply weather modulation to a base (time-of-day) color: darken toward gloom, then grey out.
func _pal(c: Color, darken: float, desat: float) -> Color:
	var out := c.lerp(Color(0.10, 0.11, 0.15), darken * 0.5)
	if desat > 0.0:
		var g := out.get_luminance()
		out = out.lerp(Color(g, g, g), desat * 0.6)
	return out


# --- silhouette surface sampling (mirrors terrain_silhouette.gdshader) ----------
# So a prop row can be planted ON a band's ridge line instead of a flat screen line. The
# noise here is a 1:1 port of the shader's hash/vnoise/fbm, so the sampled surface matches
# the rendered ridge exactly for the same seed. Evaluated once per prop at build time — no
# per-frame cost, so dense back rows stay cheap.

static func _sfract(x: float) -> float:
	return x - floor(x)


static func _shash2(p: Vector2) -> float:
	p = Vector2(_sfract(p.x * 123.34), _sfract(p.y * 456.21))
	var d := p.x * (p.x + 45.32) + p.y * (p.y + 45.32)
	p += Vector2(d, d)
	return _sfract(p.x * p.y)


static func _svnoise(p: Vector2) -> float:
	var i := Vector2(floor(p.x), floor(p.y))
	var f := Vector2(_sfract(p.x), _sfract(p.y))
	var u := Vector2(
		f.x * f.x * f.x * (f.x * (f.x * 6.0 - 15.0) + 10.0),
		f.y * f.y * f.y * (f.y * (f.y * 6.0 - 15.0) + 10.0))
	var a := _shash2(i)
	var b := _shash2(i + Vector2(1.0, 0.0))
	var c := _shash2(i + Vector2(0.0, 1.0))
	var d := _shash2(i + Vector2(1.0, 1.0))
	return lerpf(lerpf(a, b, u.x), lerpf(c, d, u.x), u.y)


static func _sfbm(p: Vector2) -> float:
	var s := 0.0
	var a := 0.5
	for _i in 6:
		s += a * _svnoise(p)
		p = p * 2.0 + Vector2(1.7, 1.7)
		a *= 0.5
	return s


## The ridge line — band UV.y (0 = top … 1 = bottom) where the silhouette surface sits — at
## horizontal position [param ux] (0..1 across the band). Matches the terrain shader's ridge.
static func _silhouette_top(height: float, roughness: float, seed_v: float, ux: float) -> float:
	var sd := fmod(seed_v, 997.0)
	var freq := 2.0 + roughness * 8.0
	var warp := _sfbm(Vector2(ux * freq * 0.5, sd))
	var ridge := _sfbm(Vector2(ux * freq + warp * 1.5, sd * 1.3))
	var base_top := 1.0 - height
	return base_top - (ridge - 0.5) * height * (0.5 + roughness)
