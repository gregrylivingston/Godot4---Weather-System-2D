@tool
class_name Scenarios
extends RefCounted
## Ready-made scene recipes for the Weather System 2D kit. Each returns a configured (but
## not yet built) [WeatherScene], so callers can `.build()` it. The launcher uses these.
##
## [codeblock]
## var ws := Scenarios.build("River", {"seed": 7, "time_of_day": TimeOfDay.dusk(), "weather": WeatherPreset.stormy()})
## add_child(ws.build())
## [/codeblock]
##
## `opts` keys (all optional): seed:int, time_of_day:TimeOfDay, weather:WeatherPreset,
## cloud_style:CloudPreset, props:bool, birds:bool, painterly:bool, snow:bool, rain/fog/
## wind/clouds:float (0..1, negative follows the weather preset), and — for a living scene
## (Phase 5) — live:bool, day_night_speed:float (days/sec), lightning:bool.

const LIST := ["Beach", "Small Island", "River", "Lake", "Mountains"]

const _PALM := "res://assets/svg/tree_palm.svg"
const _ROUND := "res://assets/svg/tree_round.svg"
const _PINE := "res://assets/svg/tree_pine.svg"
const _BUSH := "res://assets/svg/bush.svg"


static func build(scenario: String, opts: Dictionary = {}) -> WeatherScene:
	match scenario:
		"Small Island": return island(opts)
		"River": return river(opts)
		"Lake": return lake(opts)
		"Mountains": return mountains(opts)
		_: return beach(opts)


static func beach(opts: Dictionary = {}) -> WeatherScene:
	var ws := _base(opts)
	ws.terrain([
		TerrainLayer.mountains(Color(0.56, 0.60, 0.70)),
		TerrainLayer.mountains(),
		TerrainLayer.hills(),
		TerrainLayer.ground(),
	])
	ws.water(WaterBody2D.Mode.OCEAN_BEACH)
	_maybe_props(ws, opts, 20)
	_maybe_birds(ws, opts, 5)
	return ws


static func island(opts: Dictionary = {}) -> WeatherScene:
	var ws := _base(opts)
	ws.terrain([
		TerrainLayer.hills(Color(0.40, 0.62, 0.44)),
		TerrainLayer.ground(Color(0.92, 0.85, 0.66)),
	])
	ws.water(WaterBody2D.Mode.OCEAN_BEACH)
	if bool(opts.get("props", true)):
		ws.props(true, 12, [load(_PALM), load(_ROUND), load(_BUSH)])
	_maybe_birds(ws, opts, 4)
	return ws


static func river(opts: Dictionary = {}) -> WeatherScene:
	var ws := _base(opts)
	# A tall hill fills the space above the river as the green far bank the props stand on.
	var bank := TerrainLayer.hills(Color(0.36, 0.56, 0.40))
	bank.height = 0.95
	ws.terrain([
		TerrainLayer.mountains(Color(0.54, 0.58, 0.68)),
		bank,
		TerrainLayer.foreground(),
	])
	ws.water(WaterBody2D.Mode.RIVER)
	_maybe_props(ws, opts, 16)
	_maybe_birds(ws, opts, 4)
	return ws


static func lake(opts: Dictionary = {}) -> WeatherScene:
	var ws := _base(opts)
	ws.terrain([
		TerrainLayer.mountains(Color(0.50, 0.55, 0.66)),
		TerrainLayer.mountains(),
		TerrainLayer.hills(),
		TerrainLayer.ground(Color(0.52, 0.60, 0.44)),
	])
	ws.water(WaterBody2D.Mode.STILL)
	if bool(opts.get("props", true)):
		ws.props(true, 18, [load(_PINE), load(_ROUND), load(_BUSH)])
	_maybe_birds(ws, opts, 4)
	return ws


static func mountains(opts: Dictionary = {}) -> WeatherScene:
	var ws := _base(opts)
	ws.terrain([
		TerrainLayer.mountains(Color(0.50, 0.54, 0.64)),
		TerrainLayer.mountains(Color(0.44, 0.48, 0.58)),
		TerrainLayer.hills(Color(0.30, 0.50, 0.36)),
		TerrainLayer.ground(Color(0.55, 0.62, 0.46)),
	])
	ws.water(WaterBody2D.Mode.STILL)
	if bool(opts.get("props", true)):
		ws.props(true, 20, [load(_PINE), load(_ROUND)])
	_maybe_birds(ws, opts, 5)
	return ws


# --- internals -------------------------------------------------------------

static func _base(opts: Dictionary) -> WeatherScene:
	var ws := WeatherScene.new()
	ws.set_seed(int(opts.get("seed", 1)))
	ws.time_of_day(opts.get("time_of_day", TimeOfDay.noon()))
	ws.weather(opts.get("weather", WeatherPreset.clear()))
	ws.painterly(bool(opts.get("painterly", true)))
	ws.rain(float(opts.get("rain", -1.0)))
	ws.fog(float(opts.get("fog", -1.0)))
	ws.wind(float(opts.get("wind", -1.0)))
	ws.clouds(float(opts.get("clouds", -1.0)))
	if opts.get("cloud_style") is CloudPreset:
		ws.cloud_style(opts["cloud_style"])
	if opts.has("snow"):
		ws.snow(bool(opts["snow"]))
	if bool(opts.get("live", false)):
		ws.live(true, float(opts.get("day_night_speed", 0.0)))
	if bool(opts.get("lightning", false)):
		ws.lightning(true)
	if bool(opts.get("low_graphics", false)):
		ws.low_graphics(true)
	return ws


static func _maybe_props(ws: WeatherScene, opts: Dictionary, count: int) -> void:
	if bool(opts.get("props", true)):
		ws.props(true, count)


static func _maybe_birds(ws: WeatherScene, opts: Dictionary, count: int) -> void:
	if bool(opts.get("birds", true)):
		ws.birds(true, count)
