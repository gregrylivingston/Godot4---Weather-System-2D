extends Control
## Weather System 2D — playground launcher.
##
## Pick a scenario (Beach / Small Island / River / Lake / Mountains) and a weather mood, tweak
## rain / fog / wind / snow, and toggle props / birds / painterly — the scene rebuilds live.
## Selecting a weather preset fills the sliders with its values, which you can then adjust.
## The UI is built in code so the .tscn stays a one-liner. Set as the project's main scene.

const WEATHER_NAMES := ["Clear Noon", "Golden Hour", "Overcast Dusk", "Foggy", "Storm", "Snowy Dusk", "Night"]

var _scene: Node2D
var _scenario := 0
var _weather := 0
var _props := true
var _birds := true
var _painterly := true
var _snow := false
var _rain := 0.0
var _fog := 0.0
var _wind := 0.25
var _seed := 7

var _seed_spin: SpinBox
var _rain_slider: HSlider
var _fog_slider: HSlider
var _wind_slider: HSlider
var _snow_check: CheckBox


func _ready() -> void:
	_build_ui()
	_rebuild()


func _weather_preset() -> WeatherPreset:
	match _weather:
		1: return WeatherPreset.golden_hour()
		2: return WeatherPreset.overcast_dusk()
		3: return WeatherPreset.foggy()
		4: return WeatherPreset.storm()
		5: return WeatherPreset.snowy_dusk()
		6: return WeatherPreset.night()
		_: return WeatherPreset.clear_noon()


func _rebuild() -> void:
	if is_instance_valid(_scene):
		_scene.queue_free()
	var opts := {
		"seed": _seed,
		"weather": _weather_preset(),
		"props": _props,
		"birds": _birds,
		"painterly": _painterly,
		"rain": _rain,
		"fog": _fog,
		"wind": _wind,
		"snow": _snow,
	}
	_scene = Scenarios.build(Scenarios.LIST[_scenario], opts).build()
	add_child(_scene)
	move_child(_scene, 0) # keep the scene behind the UI CanvasLayer


# Selecting a preset fills the sliders with its mood, then rebuilds.
func _on_weather_selected(i: int) -> void:
	_weather = i
	var p := _weather_preset()
	_rain = p.rain
	_fog = p.fog
	_wind = p.wind
	_snow = p.snow
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
	panel.custom_minimum_size = Vector2(300, 0)
	layer.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	panel.add_child(margin)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 9)
	margin.add_child(vb)

	var title := Label.new()
	title.text = "Weather System 2D"
	title.add_theme_font_size_override("font_size", 20)
	vb.add_child(title)

	vb.add_child(_section_label("Scenario"))
	var scenario_ob := OptionButton.new()
	for name in Scenarios.LIST:
		scenario_ob.add_item(name)
	scenario_ob.selected = _scenario
	scenario_ob.item_selected.connect(func(i): _scenario = i; _rebuild())
	vb.add_child(scenario_ob)

	vb.add_child(_section_label("Weather"))
	var weather_ob := OptionButton.new()
	for name in WEATHER_NAMES:
		weather_ob.add_item(name)
	weather_ob.selected = _weather
	weather_ob.item_selected.connect(_on_weather_selected)
	vb.add_child(weather_ob)

	_rain_slider = _slider(vb, "Rain", _rain, func(v): _rain = v; _rebuild())
	_fog_slider = _slider(vb, "Fog", _fog, func(v): _fog = v; _rebuild())
	_wind_slider = _slider(vb, "Wind", _wind, func(v): _wind = v; _rebuild())

	_snow_check = _toggle("Snow", _snow, func(on): _snow = on; _rebuild())
	vb.add_child(_snow_check)
	vb.add_child(_toggle("Props (trees, rocks)", _props, func(on): _props = on; _rebuild()))
	vb.add_child(_toggle("Birds", _birds, func(on): _birds = on; _rebuild()))
	vb.add_child(_toggle("Painterly look", _painterly, func(on): _painterly = on; _rebuild()))

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

	var hint := Label.new()
	hint.text = "Mix and match — the scene updates live."
	hint.add_theme_font_size_override("font_size", 11)
	hint.modulate = Color(1, 1, 1, 0.6)
	vb.add_child(hint)


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
