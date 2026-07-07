extends Control
## Lost Settlement — Event Backdrops playground.
##
## Two ways to drive a scene, split across tabs:
##   • Region  — the game-facing settings: pick a Region (one per world biome, plus open ocean
##     and the European ports) and a Scenario landform (Coast / River / Lake / Mountains /
##     Island / Wetland / Open Sea). This is exactly what the game would hand over.
##   • Kit (advanced) — the raw scene kit: a generic scenario plus fine controls (cloud style,
##     rain / fog / wind, snow, simulation) that don't apply in region mode.
## Time of day, weather and seed sit above the tabs and work with either. The active tab is the
## mode. The scene rebuilds live. Set as the main scene.

const TIME_NAMES := ["Region default", "Dawn", "Noon", "Golden Hour", "Dusk", "Night"]
const WEATHER_NAMES := ["Region default", "Clear", "Cloudy", "Foggy", "Rainy", "Stormy", "Snowy"]
const CLOUD_NAMES := ["Auto (from weather)", "Clear", "Wispy", "Scattered", "Cumulus", "Overcast", "Stormy"]

var _scene: Node2D
var _mode := 0          # 0 = Region tab, 1 = Kit (advanced) tab
var _region := 1        # Amazon Jungle
var _scenario := 1      # Regions.SCENARIOS index; 1 = River (Amazon's default)
var _kit_scenario := 0  # Scenarios.LIST index
var _time := 0          # 0 = region default; 1..5 = concrete
var _weather := 0       # 0 = region default; 1..6 = concrete
var _cloud := 0         # Auto
var _props := true
var _birds := true
var _painterly := true
var _snow := false
var _rain := 0.0
var _fog := 0.0
var _wind := 0.2
var _seed := 7
var _live := false
var _day_speed := 0.0
var _lightning := false
var _low_graphics := false

var _seed_spin: SpinBox
var _rain_slider: HSlider
var _fog_slider: HSlider
var _wind_slider: HSlider
var _snow_check: CheckBox


func _ready() -> void:
	_build_ui()
	_rebuild()


# Index 0 is "region default" (region mode omits the override; kit mode falls back to noon/clear).
func _time_preset() -> TimeOfDay:
	match _time:
		1: return TimeOfDay.dawn()
		3: return TimeOfDay.golden_hour()
		4: return TimeOfDay.dusk()
		5: return TimeOfDay.night()
		_: return TimeOfDay.noon()


func _weather_preset() -> WeatherPreset:
	match _weather:
		2: return WeatherPreset.cloudy()
		3: return WeatherPreset.foggy()
		4: return WeatherPreset.rainy()
		5: return WeatherPreset.stormy()
		6: return WeatherPreset.snowy()
		_: return WeatherPreset.clear()


func _cloud_preset() -> CloudPreset:
	match _cloud:
		1: return CloudPreset.clear()
		2: return CloudPreset.wispy()
		3: return CloudPreset.scattered()
		4: return CloudPreset.cumulus()
		5: return CloudPreset.overcast()
		6: return CloudPreset.stormy()
		_:
			match _weather: # Auto (weather index 2=cloudy … 6=snowy)
				2: return CloudPreset.scattered()
				3: return CloudPreset.overcast()
				4: return CloudPreset.overcast()
				5: return CloudPreset.stormy()
				6: return CloudPreset.overcast()
				_: return CloudPreset.clear()


func _rebuild() -> void:
	if is_instance_valid(_scene):
		_scene.queue_free()
	var ws: WeatherScene
	if _mode == 0:
		ws = Regions.build(Regions.LIST[_region], _region_opts())
	else:
		ws = Scenarios.build(Scenarios.LIST[_kit_scenario], _scenario_opts())
	_scene = ws.build()
	add_child(_scene)
	move_child(_scene, 0) # keep the scene behind the UI CanvasLayer


# Region mode: the basic settings the game would pass. Time/weather only override the region's
# signature when the player picks a concrete one (index 0 = leave the region's default).
func _region_opts() -> Dictionary:
	var opts := {
		"seed": _seed,
		"scenario": Regions.SCENARIOS[_scenario],
		"props": _props,
		"birds": _birds,
		"painterly": _painterly,
	}
	if _time > 0:
		opts["time_of_day"] = _time_preset()
	if _weather > 0:
		opts["weather"] = _weather_preset()
	return opts


func _scenario_opts() -> Dictionary:
	return {
		"seed": _seed,
		"time_of_day": _time_preset(),
		"weather": _weather_preset(),
		"cloud_style": _cloud_preset(),
		"props": _props,
		"birds": _birds,
		"painterly": _painterly,
		"rain": _rain,
		"fog": _fog,
		"wind": _wind,
		"snow": _snow,
		"live": _live,
		"day_night_speed": _day_speed,
		"lightning": _lightning,
		"low_graphics": _low_graphics,
	}


# Picking a concrete weather in Kit mode fills the sliders with its conditions.
func _on_weather_selected(i: int) -> void:
	_weather = i
	var p := _weather_preset()
	_rain = p.rain
	_fog = p.fog
	_wind = p.wind
	_snow = p.snow
	if _rain_slider:
		_rain_slider.set_value_no_signal(_rain)
		_fog_slider.set_value_no_signal(_fog)
		_wind_slider.set_value_no_signal(_wind)
		_snow_check.set_pressed_no_signal(_snow)
	_rebuild()


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)

	var panel := PanelContainer.new()
	panel.position = Vector2(24, 24)
	panel.custom_minimum_size = Vector2(320, 0)
	layer.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	panel.add_child(margin)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 9)
	margin.add_child(vb)

	var title := Label.new()
	title.text = "Lost Settlement — Backdrops"
	title.add_theme_font_size_override("font_size", 19)
	vb.add_child(title)

	# ── Shared basics (work in either mode) ──
	vb.add_child(_section_label("Time of day"))
	var time_ob := OptionButton.new()
	for name in TIME_NAMES:
		time_ob.add_item(name)
	time_ob.selected = _time
	time_ob.item_selected.connect(func(i): _time = i; _rebuild())
	vb.add_child(time_ob)

	vb.add_child(_section_label("Weather"))
	var weather_ob := OptionButton.new()
	for name in WEATHER_NAMES:
		weather_ob.add_item(name)
	weather_ob.selected = _weather
	weather_ob.item_selected.connect(_on_weather_selected)
	vb.add_child(weather_ob)

	vb.add_child(_section_label("Seed"))
	var seed_row := HBoxContainer.new()
	seed_row.add_theme_constant_override("separation", 8)
	_seed_spin = SpinBox.new()
	_seed_spin.min_value = 0
	_seed_spin.max_value = 999999
	_seed_spin.value = _seed
	_seed_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_seed_spin.value_changed.connect(func(v): _seed = int(v); _rebuild())
	seed_row.add_child(_seed_spin)
	var rnd := Button.new()
	rnd.text = "Randomize"
	rnd.pressed.connect(_on_randomize)
	seed_row.add_child(rnd)
	vb.add_child(seed_row)

	# ── Mode tabs ──
	var tabs := TabContainer.new()
	tabs.custom_minimum_size = Vector2(300, 430)
	tabs.current_tab = _mode
	tabs.tab_changed.connect(func(i): _mode = i; _rebuild())
	vb.add_child(tabs)
	tabs.add_child(_build_region_tab())
	tabs.add_child(_build_kit_tab())


func _build_region_tab() -> Control:
	var t := VBoxContainer.new()
	t.name = "Region"
	t.add_theme_constant_override("separation", 9)

	t.add_child(_section_label("Region"))
	var region_ob := OptionButton.new()
	for name in Regions.LIST:
		region_ob.add_item(name)
	region_ob.selected = _region
	region_ob.item_selected.connect(func(i): _region = i; _rebuild())
	t.add_child(region_ob)

	t.add_child(_section_label("Scenario (landform)"))
	var scen_ob := OptionButton.new()
	for name in Regions.SCENARIOS:
		scen_ob.add_item(name)
	scen_ob.selected = _scenario
	scen_ob.item_selected.connect(func(i): _scenario = i; _rebuild())
	t.add_child(scen_ob)

	t.add_child(_toggle("Props (trees, rocks)", _props, func(on): _props = on; _rebuild()))
	t.add_child(_toggle("Birds", _birds, func(on): _birds = on; _rebuild()))

	var hint := Label.new()
	hint.text = "Region = biome flavour, Scenario = landform.\nTime & weather above ride on top."
	hint.add_theme_font_size_override("font_size", 11)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color(1, 1, 1, 0.6)
	t.add_child(hint)
	return t


func _build_kit_tab() -> Control:
	var scroll := ScrollContainer.new()
	scroll.name = "Kit (advanced)"
	var t := VBoxContainer.new()
	t.add_theme_constant_override("separation", 9)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(t)

	t.add_child(_section_label("Generic scenario"))
	var scenario_ob := OptionButton.new()
	for name in Scenarios.LIST:
		scenario_ob.add_item(name)
	scenario_ob.selected = _kit_scenario
	scenario_ob.item_selected.connect(func(i): _kit_scenario = i; _rebuild())
	t.add_child(scenario_ob)

	t.add_child(_section_label("Clouds"))
	var cloud_ob := OptionButton.new()
	for name in CLOUD_NAMES:
		cloud_ob.add_item(name)
	cloud_ob.selected = _cloud
	cloud_ob.item_selected.connect(func(i): _cloud = i; _rebuild())
	t.add_child(cloud_ob)

	_rain_slider = _slider(t, "Rain", _rain, func(v): _rain = v; _rebuild())
	_fog_slider = _slider(t, "Fog", _fog, func(v): _fog = v; _rebuild())
	_wind_slider = _slider(t, "Wind", _wind, func(v): _wind = v; _rebuild())

	_snow_check = _toggle("Snow", _snow, func(on): _snow = on; _rebuild())
	t.add_child(_snow_check)
	t.add_child(_toggle("Painterly look", _painterly, func(on): _painterly = on; _rebuild()))

	t.add_child(_section_label("Simulation"))
	t.add_child(_toggle("Animate (live sun + weather)", _live, func(on): _live = on; _rebuild()))
	t.add_child(_toggle("Lightning (storms)", _lightning, func(on): _lightning = on; _rebuild()))
	t.add_child(_toggle("Low graphics (faster)", _low_graphics, func(on): _low_graphics = on; _rebuild()))
	t.add_child(_section_label("Day–night speed"))
	var day_slider := HSlider.new()
	day_slider.min_value = 0.0
	day_slider.max_value = 0.05
	day_slider.step = 0.002
	day_slider.value = _day_speed
	day_slider.custom_minimum_size = Vector2(0, 18)
	day_slider.value_changed.connect(func(v): _day_speed = v; _rebuild())
	t.add_child(day_slider)

	var hint := Label.new()
	hint.text = "The raw scene kit. These fine controls don't apply in Region mode."
	hint.add_theme_font_size_override("font_size", 11)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color(1, 1, 1, 0.6)
	t.add_child(hint)
	return scroll


func _on_randomize() -> void:
	_seed = randi() % 1000000
	_seed_spin.set_value_no_signal(_seed)
	_rebuild()


func _slider(parent: VBoxContainer, text: String, value: float, cb: Callable) -> HSlider:
	parent.add_child(_section_label(text))
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(0, 18)
	s.value_changed.connect(cb)
	parent.add_child(s)
	return s


func _section_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 12)
	l.modulate = Color(1, 1, 1, 0.7)
	return l


func _toggle(text: String, pressed: bool, cb: Callable) -> CheckBox:
	var cb_node := CheckBox.new()
	cb_node.text = text
	cb_node.button_pressed = pressed
	cb_node.toggled.connect(cb)
	return cb_node
