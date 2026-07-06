extends SceneTree
## Headless test runner for the Weather System 2D kit.
##
## Run from the project root:
##   godot --headless --path . --script res://tests/run_tests.gd
##
## Exits with code 0 if all checks pass, 1 otherwise (CI-friendly). No external addon
## required. See tests/README.md. As the kit grows, a GUT/GdUnit4 suite can replace this.
##
## Note: node _enter_tree/_ready callbacks are not guaranteed to have run the instant
## add_child() returns inside _initialize(), so helpers await one process_frame first.

var _passed := 0
var _failed := 0


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	print("== Weather System 2D — tests ==")
	await _test_water_defaults_and_material()
	await _test_water_param_push()
	_test_water_mode_enum()
	await _test_water_mode_push()
	await _test_water_weather_response()
	_test_terrain_layer_factories()
	await _test_terrain_band_shader_selection()
	await _test_beach_demo_controls()
	await _test_weather_scene_builder()
	_test_weather_scene_determinism()
	_test_scene_preset_roundtrip()
	await _test_prop_scatter()
	await _test_prop_animation()
	await _test_painterly_layer()
	await _test_builder_props_and_painterly()
	await _test_rain_overlay()
	await _test_clouds()
	await _test_time_and_weather()
	_test_sun_model()
	await _test_sky_material()
	await _test_water_sun_glint()
	await _test_clouds_sun_wind()
	await _test_live_scene()
	_test_sky_controller_step()
	_test_time_of_day_day()
	await _test_water_day_cycle()
	await _test_low_graphics()
	await _test_scenarios()
	await _test_launcher_loads()

	print("== %d passed, %d failed ==" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


# --- helpers ---------------------------------------------------------------

func _check(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("  [PASS] " + msg)
	else:
		_failed += 1
		print("  [FAIL] " + msg)
		push_error("Test failed: " + msg)


func _approx(a: float, b: float) -> bool:
	return absf(a - b) < 0.0001


# Add a node and let its _enter_tree/_ready run before returning.
func _add_ready(node: Node) -> void:
	root.add_child(node)
	await process_frame


# --- tests -----------------------------------------------------------------

func _test_water_defaults_and_material() -> void:
	print("WaterBody2D — material & noise setup")
	var w := WaterBody2D.new()
	await _add_ready(w)
	var mat := w.material as ShaderMaterial
	_check(mat != null, "creates a ShaderMaterial")
	_check(mat != null and mat.shader != null, "loads the water shader")
	_check(mat != null and mat.get_shader_parameter("noise_tex") != null, "assigns a noise texture")
	w.free()


func _test_water_param_push() -> void:
	print("WaterBody2D — property setters push shader params")
	var w := WaterBody2D.new()
	await _add_ready(w)
	var mat := w.material as ShaderMaterial
	w.level = 0.3
	w.foam_amount = 0.9
	w.wave_height = 0.05
	w.flow_direction = Vector2(0.0, 1.0)
	_check(_approx(mat.get_shader_parameter("level"), 0.3), "level -> shader")
	_check(_approx(mat.get_shader_parameter("foam_amount"), 0.9), "foam_amount -> shader")
	_check(_approx(mat.get_shader_parameter("wave_height"), 0.05), "wave_height -> shader")
	_check(mat.get_shader_parameter("flow_direction") == Vector2(0.0, 1.0), "flow_direction -> shader")
	w.free()


func _test_water_mode_enum() -> void:
	print("WaterBody2D — mode enum values")
	_check(WaterBody2D.Mode.STILL == 0, "STILL == 0")
	_check(WaterBody2D.Mode.RIVER == 1, "RIVER == 1")
	_check(WaterBody2D.Mode.OCEAN_BEACH == 2, "OCEAN_BEACH == 2")


func _test_water_mode_push() -> void:
	print("WaterBody2D — mode pushes to shader")
	var w := WaterBody2D.new()
	await _add_ready(w)
	w.mode = WaterBody2D.Mode.RIVER
	_check(int((w.material as ShaderMaterial).get_shader_parameter("mode")) == 1, "mode -> shader as int")
	w.free()


func _test_water_weather_response() -> void:
	print("WaterBody2D — rain darkens & roughens the water")
	var w := WaterBody2D.new()
	await _add_ready(w)
	w.weather_influence = 1.0
	var dry_deep := w.deep_color
	var dry_foam := w.foam_amount
	var dry_wave := w.wave_height
	w._on_rain_amount(1.0)
	_check(w.deep_color.v < dry_deep.v, "deep water gets darker in rain")
	_check(w.foam_amount > dry_foam, "foam increases in rain")
	_check(w.wave_height > dry_wave, "waves grow in rain")
	w._on_rain_amount(0.0)
	_check(_approx(w.foam_amount, dry_foam), "foam restores when rain clears")
	w.free()


func _test_terrain_layer_factories() -> void:
	print("TerrainLayer — factory presets")
	var m := TerrainLayer.mountains()
	var h := TerrainLayer.hills()
	var g := TerrainLayer.ground()
	_check(m.role == TerrainLayer.Role.MOUNTAIN, "mountains() -> MOUNTAIN role")
	_check(h.role == TerrainLayer.Role.HILL, "hills() -> HILL role")
	_check(g.role == TerrainLayer.Role.GROUND, "ground() -> GROUND role")
	_check(m.roughness > h.roughness, "mountains are jaggeder than hills")
	_check(m.scroll_scale.x < h.scroll_scale.x, "distant mountains scroll slower than hills")


func _test_terrain_band_shader_selection() -> void:
	print("TerrainBand2D — picks the shader for the layer role")
	var ground := TerrainBand2D.new()
	ground.layer = TerrainLayer.ground()
	await _add_ready(ground)
	var gpath: String = (ground.material as ShaderMaterial).shader.resource_path
	_check(gpath.ends_with("terrain_ground.gdshader"), "GROUND role -> terrain_ground shader")
	ground.free()

	var hill := TerrainBand2D.new()
	hill.layer = TerrainLayer.hills()
	await _add_ready(hill)
	var hpath: String = (hill.material as ShaderMaterial).shader.resource_path
	_check(hpath.ends_with("terrain_silhouette.gdshader"), "HILL role -> terrain_silhouette shader")
	hill.free()


# Loads the REAL demo scene and verifies inspector-style edits reach the live material —
# i.e. the "controls actually do something" path.
func _test_beach_demo_controls() -> void:
	print("beach_demo.tscn — controls reach the live material")
	var packed := load("res://demos/beach_demo.tscn") as PackedScene
	_check(packed != null, "beach_demo.tscn loads")
	if packed == null:
		return
	var inst := packed.instantiate()
	await _add_ready(inst)
	var water := inst.get_node("Water") as WaterBody2D
	_check(water != null, "Water node present")
	_check(water != null and water.material is ShaderMaterial, "Water has a live material after scene load")
	if water != null and water.material is ShaderMaterial:
		water.level = 0.25
		var pushed = (water.material as ShaderMaterial).get_shader_parameter("level")
		_check(_approx(pushed, 0.25), "editing Water.level updates the live material")
	inst.free()


func _test_weather_scene_builder() -> void:
	print("WeatherScene — builds a full node tree from code")
	var builder := WeatherScene.new()
	builder.set_seed(42)
	builder.time_of_day(TimeOfDay.noon())
	builder.weather(WeatherPreset.clear())
	builder.terrain([TerrainLayer.mountains(), TerrainLayer.hills(), TerrainLayer.ground()])
	builder.water(WaterBody2D.Mode.OCEAN_BEACH)
	var scene := builder.build()
	await _add_ready(scene)
	_check(scene is Node2D, "build() returns a Node2D")
	_check(scene.get_node_or_null("Camera2D") != null, "has a Camera2D")
	_check(scene.get_node_or_null("Sky") != null, "has a Sky")
	var water := scene.get_node_or_null("Water") as WaterBody2D
	_check(water != null, "has a Water body")
	# 3 terrain bands present.
	var bands := 0
	for c in scene.get_children():
		if c is TerrainBand2D:
			bands += 1
	_check(bands == 3, "built 3 terrain bands")
	# Water aligns just below the ground coast (coast 0.32 + 0.14 = 0.46).
	_check(water != null and _approx(water.level, 0.46), "water level aligned to ground coast")
	# Time of day drives the water palette (clear weather doesn't modulate it).
	_check(water != null and water.deep_color == TimeOfDay.noon().water_deep, "time of day sets water color")
	scene.free()


func _test_weather_scene_determinism() -> void:
	print("WeatherScene — deterministic seeding")
	var layers := [TerrainLayer.mountains(), TerrainLayer.hills(), TerrainLayer.ground()]
	var a := WeatherScene.new().set_seed(7).terrain(layers).build()
	var b := WeatherScene.new().set_seed(7).terrain(layers).build()
	var c := WeatherScene.new().set_seed(99).terrain(layers).build()
	var sa := _band_seeds(a)
	var sb := _band_seeds(b)
	var sc := _band_seeds(c)
	_check(sa == sb, "same seed → identical band seeds")
	_check(sa != sc, "different seed → different band seeds")
	_check(sa.size() == 3 and sa[0] == 7 and sa[2] == 9, "band seeds are base_seed + index")
	a.free()
	b.free()
	c.free()


func _band_seeds(scene: Node) -> Array:
	var out := []
	for c in scene.get_children():
		if c is TerrainBand2D and c.layer != null:
			out.append(c.layer.seed)
	return out


func _test_scene_preset_roundtrip() -> void:
	print("ScenePreset — WeatherScene.from_preset applies it")
	var preset := ScenePreset.new()
	preset.scene_seed = 123
	preset.size = Vector2(800, 600)
	preset.time_of_day = TimeOfDay.noon()
	preset.weather = WeatherPreset.stormy()
	preset.terrain = [TerrainLayer.hills(), TerrainLayer.ground()]
	preset.water_level = 0.5
	var scene := WeatherScene.new().from_preset(preset).build()
	var bands := 0
	for c in scene.get_children():
		if c is TerrainBand2D:
			bands += 1
	_check(bands == 2, "preset's 2 terrain layers built")
	var water := scene.get_node_or_null("Water") as WaterBody2D
	# Stormy weather darkens the noon water palette.
	_check(water != null and water.deep_color.v < TimeOfDay.noon().water_deep.v, "stormy weather darkens water")
	scene.free()


func _test_prop_scatter() -> void:
	print("PropScatter2D — seeded, deterministic scatter")
	var tex := load("res://assets/svg/tree_round.svg") as Texture2D
	_check(tex != null, "tree SVG imports as a texture")
	var a := PropScatter2D.new()
	a.textures = [tex]
	a.count = 10
	a.seed = 3
	await _add_ready(a)
	var n := 0
	for c in a.get_children():
		if c is Sprite2D:
			n += 1
	_check(n == 10, "creates one sprite per count")
	var first_pos: Vector2 = (a.get_child(0) as Sprite2D).position

	var b := PropScatter2D.new()
	b.textures = [tex]
	b.count = 10
	b.seed = 3
	await _add_ready(b)
	_check((b.get_child(0) as Sprite2D).position == first_pos, "same seed → identical layout")
	a.free()
	b.free()


func _test_prop_animation() -> void:
	print("PropScatter2D — SWAY assigns an animation material")
	var tex := load("res://assets/svg/tree_round.svg") as Texture2D
	var s := PropScatter2D.new()
	s.textures = [tex]
	s.count = 3
	s.animation = PropScatter2D.ANIM_SWAY
	await _add_ready(s)
	var first := s.get_child(0) as Sprite2D
	_check(first != null and first.material is ShaderMaterial, "sway sprites get a shader material")
	s.free()


func _test_painterly_layer() -> void:
	print("PainterlyLayer — full-screen overlay with shader")
	var p := PainterlyLayer.new()
	await _add_ready(p)
	var overlay := p.get_node_or_null("Overlay") as ColorRect
	_check(overlay != null, "creates a full-rect Overlay")
	_check(overlay != null and overlay.material is ShaderMaterial, "overlay has a shader material")
	_check(p.layer == 10, "draws on a high canvas layer")
	p.free()


func _test_builder_props_and_painterly() -> void:
	print("WeatherScene — props() and painterly() attach nodes")
	var builder := WeatherScene.new()
	builder.terrain([TerrainLayer.hills(), TerrainLayer.ground()])
	builder.props(true, 8)
	builder.birds(true, 4)
	builder.painterly(true)
	var scene := builder.build()
	await _add_ready(scene)
	var prop_rows := 0
	for c in scene.get_children():
		if c is PropScatter2D and c.name.begins_with("Props"):
			prop_rows += 1
	_check(prop_rows >= 1, "props() adds per-layer PropScatter2D rows")
	_check(scene.get_node_or_null("Birds") is PropScatter2D, "birds() adds a Birds scatter")
	var has_painterly := false
	for c in scene.get_children():
		if c is PainterlyLayer:
			has_painterly = true
	_check(has_painterly, "painterly() adds a PainterlyLayer")
	scene.free()


func _test_rain_overlay() -> void:
	print("WeatherScene — rain() adds a rain overlay")
	var ws := WeatherScene.new()
	ws.terrain([TerrainLayer.ground()])
	ws.rain(0.6)
	var scene := ws.build()
	await _add_ready(scene)
	_check(scene.get_node_or_null("Rain") is CanvasLayer, "rain() adds a Rain CanvasLayer")
	scene.free()


func _test_clouds() -> void:
	print("CloudPreset — cloud styles add / omit the Clouds layer")
	var overcast := WeatherScene.new().time_of_day(TimeOfDay.noon()).cloud_style(CloudPreset.overcast()) \
		.terrain([TerrainLayer.ground()]).build()
	await _add_ready(overcast)
	_check(overcast.get_node_or_null("Clouds") is ColorRect, "overcast adds a Clouds layer")
	overcast.free()

	var clear := WeatherScene.new().time_of_day(TimeOfDay.noon()).cloud_style(CloudPreset.clear()) \
		.terrain([TerrainLayer.ground()]).build()
	await _add_ready(clear)
	_check(clear.get_node_or_null("Clouds") == null, "clear cloud style → no Clouds layer")
	clear.free()

	# Cloud presets are distinct styles.
	_check(CloudPreset.stormy().coverage > CloudPreset.wispy().coverage, "stormy covers more sky than wispy")


func _test_time_and_weather() -> void:
	print("TimeOfDay x WeatherPreset — independent axes")
	var clear := WeatherScene.new().time_of_day(TimeOfDay.noon()).weather(WeatherPreset.clear()) \
		.terrain([TerrainLayer.ground()]).build()
	await _add_ready(clear)
	var storm := WeatherScene.new().time_of_day(TimeOfDay.noon()).weather(WeatherPreset.stormy()) \
		.terrain([TerrainLayer.ground()]).build()
	await _add_ready(storm)
	var w1 := clear.get_node_or_null("Water") as WaterBody2D
	var w2 := storm.get_node_or_null("Water") as WaterBody2D
	_check(w1 != null and w2 != null and w2.deep_color.v < w1.deep_color.v, "same time, stormy weather is darker")
	_check(clear.get_node_or_null("Rain") == null and storm.get_node_or_null("Rain") != null, "storm rains, clear doesn't")
	_check(storm.get_node_or_null("Ambient") is CanvasModulate, "storm dims the scene (ambient)")
	clear.free()
	storm.free()


# --- Phase 5: living simulation --------------------------------------------

func _test_sun_model() -> void:
	print("TimeOfDay — unified sun model & day-night cycle")
	_check(TimeOfDay.noon().star_intensity < TimeOfDay.night().star_intensity, "night is starrier than noon")
	# cycle() interpolates the keyframes: ~noon is bright, midnight is deep night.
	_check(TimeOfDay.cycle(0.46).star_intensity < 0.2, "midday cycle has few stars")
	_check(TimeOfDay.cycle(0.0).star_intensity > 0.6, "midnight cycle is starry")
	var q := TimeOfDay.cycle(0.33) # between dawn and noon
	_check(q.sun_uv.x >= 0.0 and q.sun_uv.x <= 1.0, "cycled sun stays on screen")
	# lerp_to endpoints are exact.
	_check(TimeOfDay.noon().lerp_to(TimeOfDay.night(), 0.0).star_intensity == TimeOfDay.noon().star_intensity, "lerp_to(0) == self")
	_check(TimeOfDay.noon().lerp_to(TimeOfDay.night(), 1.0).star_intensity == TimeOfDay.night().star_intensity, "lerp_to(1) == other")


func _test_sky_material() -> void:
	print("WeatherScene — Sky uses the sky shader with the sun model")
	var scene := WeatherScene.new().time_of_day(TimeOfDay.golden_hour()).terrain([TerrainLayer.ground()]).build()
	await _add_ready(scene)
	var sky := scene.get_node_or_null("Sky")
	_check(sky is ColorRect and (sky as ColorRect).material is ShaderMaterial, "Sky is a ColorRect + ShaderMaterial")
	var mat := (sky as ColorRect).material as ShaderMaterial
	_check(mat.shader != null and mat.shader.resource_path.ends_with("sky.gdshader"), "Sky uses sky.gdshader")
	_check(mat.get_shader_parameter("sun_uv") == TimeOfDay.golden_hour().sun_uv, "sun_uv set from the time of day")
	scene.free()


func _test_water_sun_glint() -> void:
	print("WaterBody2D — sun glint (day) + rain-ripple wiring")
	var day := WeatherScene.new().time_of_day(TimeOfDay.noon()).weather(WeatherPreset.rainy()) \
		.terrain([TerrainLayer.ground()]).water(WaterBody2D.Mode.OCEAN_BEACH).build()
	await _add_ready(day)
	var water := day.get_node_or_null("Water") as WaterBody2D
	var mat := water.material as ShaderMaterial
	_check(water.glint_strength > 0.0, "daytime water has glint")
	_check(mat.get_shader_parameter("sun_uv") == TimeOfDay.noon().sun_uv, "water sun_uv from the time of day")
	_check(water.rain_ripple > 0.0, "rainy weather rings the water")
	day.free()

	var night := WeatherScene.new().time_of_day(TimeOfDay.night()).terrain([TerrainLayer.ground()]).build()
	await _add_ready(night)
	_check((night.get_node_or_null("Water") as WaterBody2D).glint_strength < 0.05, "night water barely glints")
	night.free()


func _test_clouds_sun_wind() -> void:
	print("clouds — sun tint + wind-drift uniforms")
	var scene := WeatherScene.new().time_of_day(TimeOfDay.golden_hour()).cloud_style(CloudPreset.cumulus()) \
		.terrain([TerrainLayer.ground()]).build()
	await _add_ready(scene)
	var mat := (scene.get_node_or_null("Clouds") as ColorRect).material as ShaderMaterial
	_check(mat.get_shader_parameter("sun_uv") == TimeOfDay.golden_hour().sun_uv, "clouds sun_uv from the time of day")
	_check(mat.get_shader_parameter("wind_dir") != null, "clouds have a wind_dir")
	scene.free()


func _test_live_scene() -> void:
	print("WeatherScene.live() — adds a SkyController + always-on overlays")
	var scene := WeatherScene.new().time_of_day(TimeOfDay.noon()).weather(WeatherPreset.clear()) \
		.terrain([TerrainLayer.ground()]).live(true, 0.02).lightning(true).build()
	await _add_ready(scene)
	var ctrl := scene.get_node_or_null("SkyController") as SkyController
	_check(ctrl != null, "live() adds a SkyController")
	_check(ctrl != null and ctrl.is_in_group("SkySetting"), "controller joins the SkySetting group")
	_check(scene.get_node_or_null("Rain") != null, "live scene always has a Rain layer")
	_check(scene.get_node_or_null("Clouds") != null, "live scene always has a Clouds layer")
	_check(scene.get_node_or_null("Fog") != null, "live scene always has a Fog layer")
	_check(scene.get_node_or_null("CloudShadow") != null, "live scene has a CloudShadow pass")
	_check(scene.get_node_or_null("Lightning") != null, "lightning() adds a Lightning layer")
	scene.free()


func _test_sky_controller_step() -> void:
	print("SkyController — day advance, frame-rate independence, weather transition, emit")
	# Day-night advances by speed * delta, and two half-steps == one full step.
	var a := SkyController.new()
	a.time_cycle_enabled = true
	a.day_night_speed = 0.1
	a.day01 = 0.4
	a.sky_material = ShaderMaterial.new()
	a.set_weather(WeatherPreset.clear())
	var got := {"rain": -1.0}
	a.updateRainAmount.connect(func(v): got["rain"] = v)
	a.step(1.0)
	_check(_approx(a.day01, 0.5), "day advances by speed*delta")
	_check(got["rain"] >= 0.0, "controller emits updateRainAmount")
	a.free()

	var b := SkyController.new()
	b.time_cycle_enabled = true
	b.day_night_speed = 0.1
	b.day01 = 0.0
	b.step(0.5)
	b.step(0.5)
	_check(_approx(b.day01, 0.1), "two half-steps advance the day like one full step")
	b.free()

	# Weather transition lerps rain from clear(0) toward stormy(0.9).
	var c := SkyController.new()
	c.rain_material = ShaderMaterial.new()
	c.set_weather(WeatherPreset.clear())
	c.transition_to(WeatherPreset.stormy(), 10.0)
	c.step(5.0)
	var mid: float = c.current_weather().rain
	_check(mid > 0.3 and mid < 0.6, "transition is ~halfway to the storm")
	c.step(5.0)
	_check(absf(c.current_weather().rain - WeatherPreset.stormy().rain) < 0.01, "transition reaches the target")
	c.free()


func _test_time_of_day_day() -> void:
	print("TimeOfDay — canonical day positions")
	_check(TimeOfDay.noon().day > TimeOfDay.dawn().day, "noon is later in the day than dawn")
	_check(TimeOfDay.night().day == 0.0, "night sits at midnight")
	_check(_approx(TimeOfDay.cycle(0.7).day, 0.7), "cycle() carries the day position")


func _test_water_day_cycle() -> void:
	print("Water — day-night cycle re-bases the palette")
	# Direct: with no rain, set_day_palette sets the color straight to the new base.
	var w := WaterBody2D.new()
	await _add_ready(w)
	w.set_day_palette(Color(0.8, 0.1, 0.1), Color(0.1, 0.7, 0.2))
	_check(w.deep_color == Color(0.8, 0.1, 0.1), "set_day_palette re-bases the deep color")
	w.free()

	# Via the controller: a live scene starts at the chosen time and darkens toward night.
	var scene := WeatherScene.new().time_of_day(TimeOfDay.noon()) \
		.terrain([TerrainLayer.ground()]).live(true, 0.02).build()
	await _add_ready(scene)
	var water := scene.get_node_or_null("Water") as WaterBody2D
	var ctrl := scene.get_node_or_null("SkyController") as SkyController
	_check(absf(ctrl.day01 - 0.46) < 0.02, "cycle starts at the chosen time of day (noon)")
	var noon_v := water.deep_color.v
	ctrl.day01 = 0.0   # advance the clock to midnight
	ctrl.step(0.0)
	_check(water.deep_color.v < noon_v, "water is darker at night than at noon")
	scene.free()


func _count_prop_sprites(scene: Node) -> int:
	var n := 0
	for c in scene.get_children():
		if c is PropScatter2D:
			for s in c.get_children():
				if s is Sprite2D:
					n += 1
	return n


func _new_full_scene() -> WeatherScene:
	# A live scene that exercises every overlay (clouds, rain, fog, shadow, painterly, props).
	return WeatherScene.new().time_of_day(TimeOfDay.noon()) \
		.weather(WeatherPreset.rainy()).cloud_style(CloudPreset.overcast()) \
		.terrain([TerrainLayer.hills(), TerrainLayer.ground()]) \
		.props(true, 12).birds(true, 4).painterly(true).live(true)


func _test_low_graphics() -> void:
	print("WeatherScene.low_graphics() — cheap shader paths + skipped overlays")
	var hi := _new_full_scene().build()
	await _add_ready(hi)
	_check(hi.get_node_or_null("CloudShadow") != null, "high graphics keeps the cloud-shadow pass")
	var painterly_hi := false
	for c in hi.get_children():
		if c is PainterlyLayer:
			painterly_hi = true
	_check(painterly_hi, "high graphics keeps the painterly layer")
	var hi_props := _count_prop_sprites(hi)
	hi.free()

	var lo := _new_full_scene().low_graphics(true).build()
	await _add_ready(lo)
	_check(lo.get_node_or_null("CloudShadow") == null, "low graphics skips the cloud-shadow pass")
	var painterly_lo := false
	for c in lo.get_children():
		if c is PainterlyLayer:
			painterly_lo = true
	_check(not painterly_lo, "low graphics skips the painterly layer")
	var water := lo.get_node_or_null("Water") as WaterBody2D
	_check(water != null and water.low_graphics, "low graphics flags the water body")
	_check(water != null and int((water.material as ShaderMaterial).get_shader_parameter("quality")) == 0, "water shader quality = 0")
	var clouds := lo.get_node_or_null("Clouds") as ColorRect
	_check(clouds != null and int((clouds.material as ShaderMaterial).get_shader_parameter("quality")) == 0, "cloud shader quality = 0")
	_check(_count_prop_sprites(lo) < hi_props, "low graphics scatters fewer props")
	lo.free()


func _test_scenarios() -> void:
	print("Scenarios — every recipe builds a valid scene")
	for name in Scenarios.LIST:
		var scene := Scenarios.build(name, {"seed": 3}).build()
		await _add_ready(scene)
		var ok: bool = scene is Node2D \
			and scene.get_node_or_null("Camera2D") != null \
			and scene.get_node_or_null("Sky") != null
		_check(ok, "%s builds" % name)
		scene.free()


func _test_launcher_loads() -> void:
	print("launcher.tscn — instantiates and builds a scene")
	var packed := load("res://demos/launcher.tscn") as PackedScene
	_check(packed != null, "launcher.tscn loads")
	if packed == null:
		return
	var inst := packed.instantiate()
	await _add_ready(inst)
	await process_frame
	var has_scene := false
	for c in inst.get_children():
		if c is Node2D:
			has_scene = true
	_check(has_scene, "launcher builds a scene on ready")
	inst.free()
