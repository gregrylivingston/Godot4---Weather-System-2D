@tool
class_name Regions
extends RefCounted
## Region backdrops for Lost Settlement, driven by the same basic settings the game has.
##
## A backdrop is a [b]region[/b] (its palette, props and default mood — one per world biome,
## plus open ocean and the European ports) composed with a [b]scenario[/b] (the landform:
## Coast / River / Lake / Mountains / Island / Wetland / Open Sea). The region supplies the
## style; the scenario supplies the geography; time-of-day and weather ride on top. So the
## game can hand over exactly what a destination site already knows — biome + terrain shape +
## season/time — and get a fitting scene.
##
## [codeblock]
## # Amazon flavour, but as a lake at dawn in the rain:
## Regions.build("Amazon Jungle", {
##     "scenario": "Lake",
##     "time_of_day": TimeOfDay.dawn(),
##     "weather": WeatherPreset.rainy(),
##     "seed": 7,
## }).build()
##
## # Straight from a site's data (MapSettings.Biome + the terrain dials):
## Regions.for_biome(site.biome, {
##     "scenario": Regions.scenario_for_terrain(site.ocean_sides, site.rivers, site.lakes, site.relief),
##     "seed": run_seed,
## }).build()
## [/codeblock]
##
## `opts` (all optional): seed:int, scenario:String, time_of_day:TimeOfDay, weather:WeatherPreset,
## props:bool, birds:bool, painterly:bool (default true), live:bool, day_night_speed:float,
## low_graphics:bool. Omit scenario / time_of_day / weather to use the region's signature.

# Period grade shared by every region: mute the naturalistic frame a touch and warm it, so it
# reads as an aged painted plate. Tuned "slight" on purpose — this is a nudge, not a restyle.
const _GRADE_SATURATION := 0.82
const _GRADE_WARMTH := 0.03

# Regions (first five == the game's biomes; then open ocean and the European ports).
const LIST := [
	"Temperate Woodland",
	"Amazon Jungle",
	"Swamp",
	"Caribbean",
	"Arid Coast",
	"Open Ocean",
	"Seville (Iberia)",
	"England Coast",
	"France Coast",
]

# Landforms a region can be rendered as. A region's default is used when none is given.
const SCENARIOS := ["Coast", "River", "Lake", "Mountains", "Island", "Wetland", "Open Sea"]

# MapSettings.Biome ordering in Lost Settlement: TEMPERATE, JUNGLE, SWAMP, CARIBBEAN, ARID.
const _BIOME_REGION := [
	"Temperate Woodland",
	"Amazon Jungle",
	"Swamp",
	"Caribbean",
	"Arid Coast",
]

const _PALM := "res://addons/weather2d/assets/svg/tree_palm.svg"
const _ROUND := "res://addons/weather2d/assets/svg/tree_round.svg"
const _PINE := "res://addons/weather2d/assets/svg/tree_pine.svg"
const _BUSH := "res://addons/weather2d/assets/svg/bush.svg"
const _FERN := "res://addons/weather2d/assets/svg/fern.svg"
const _BANANA := "res://addons/weather2d/assets/svg/banana.svg"
const _MANGROVE := "res://addons/weather2d/assets/svg/mangrove.svg"
const _CACTUS := "res://addons/weather2d/assets/svg/cactus.svg"
const _REED := "res://addons/weather2d/assets/svg/reed.svg"
const _DEAD := "res://addons/weather2d/assets/svg/dead_tree.svg"


static func build(region: String, opts: Dictionary = {}) -> WeatherScene:
	var f := _flavor(region)
	var ws := WeatherScene.new()
	ws.set_seed(int(opts.get("seed", 1)))
	ws.time_of_day(opts.get("time_of_day", f["tod"]))
	ws.weather(opts.get("weather", f["weather"]))
	# Naturalistic look + the light period grade (muted, warm) so plates fit the game's UI.
	ws.painterly(bool(opts.get("painterly", true)), _GRADE_SATURATION, _GRADE_WARMTH)
	if bool(opts.get("live", false)):
		ws.live(true, float(opts.get("day_night_speed", 0.0)))
	if bool(opts.get("low_graphics", false)):
		ws.low_graphics(true)

	var scenario := String(opts.get("scenario", f["scenario"]))
	var count := _apply_scenario(ws, f, scenario)

	var foliage: Array = f["foliage"]
	if bool(opts.get("props", true)) and count > 0 and not foliage.is_empty():
		ws.props(true, count, _load_foliage(foliage))
	else:
		ws.props(false)
	if bool(opts.get("birds", true)):
		ws.birds(true, int(f["birds"]))
	return ws


## The region name for a Lost Settlement biome id (MapSettings.Biome). Out-of-range → temperate.
static func region_for_biome(biome: int) -> String:
	if biome >= 0 and biome < _BIOME_REGION.size():
		return _BIOME_REGION[biome]
	return _BIOME_REGION[0]


## Build straight from a biome id — the entry point the game itself would call.
static func for_biome(biome: int, opts: Dictionary = {}) -> WeatherScene:
	return build(region_for_biome(biome), opts)


## Pick a landform scenario from a destination site's terrain dials (the enums on
## DeparturePort): ocean_sides 0..4, rivers 0..4, lakes 0..2, relief 0..3 (Flat..Mountainous).
## A convenience so the game can turn what a site already knows into a fitting scene.
static func scenario_for_terrain(ocean_sides: int, rivers: int, lakes: int, relief: int) -> String:
	if ocean_sides >= 4:
		return "Island"
	if relief >= 3:
		return "Mountains"
	if lakes >= 2:
		return "Lake"
	if rivers >= 3:
		return "River"
	if ocean_sides >= 1:
		return "Coast"
	if lakes >= 1:
		return "Lake"
	if rivers >= 1:
		return "River"
	return "Lake"


# ── Scenario geometry (region-flavoured) ────────────────────────────────────────
# Each lays down a terrain stack + water using the region flavour's colours, and returns the
# base prop count for the scene (0 = plant nothing, e.g. open sea). MOUNTAIN bands never get
# props (see WeatherScene._ROW_CONFIG), so the distant peaks always stay bare.

static func _apply_scenario(ws: WeatherScene, f: Dictionary, scenario: String) -> int:
	match scenario:
		"River":
			var far := TerrainLayer.hills(f["hill"])
			far.height = 0.9
			ws.terrain([
				TerrainLayer.mountains(f["mountain"]),
				far,
				TerrainLayer.foreground(f["foreground"]),
			])
			ws.water(WaterBody2D.Mode.RIVER)
			return 18
		"Lake":
			ws.terrain([
				TerrainLayer.mountains(f["mountain"]),
				TerrainLayer.hills(f["hill"]),
				TerrainLayer.treeline(f["treeline"]),
				TerrainLayer.ground(f["ground"]),
			])
			ws.water(WaterBody2D.Mode.STILL)
			return 18
		"Mountains":
			ws.terrain([
				TerrainLayer.mountains(f["mountain"]),
				TerrainLayer.mountains((f["mountain"] as Color).darkened(0.08)),
				TerrainLayer.hills(f["hill"]),
				TerrainLayer.ground(f["ground"]),
			])
			ws.water(WaterBody2D.Mode.STILL)
			return 15
		"Island":
			ws.terrain([
				TerrainLayer.hills(f["hill"]),
				TerrainLayer.ground(f["sand"]),
			])
			ws.water(WaterBody2D.Mode.OCEAN_BEACH)
			return 14
		"Wetland":
			ws.terrain([
				TerrainLayer.treeline(f["treeline"]),
				TerrainLayer.hills(f["hill"]),
				TerrainLayer.ground(f["ground"]),
			])
			ws.water(WaterBody2D.Mode.STILL)
			return 18
		"Open Sea":
			# No land — an open-sea horizon built from receding wave bands: a hazy far sea that
			# fades into the sky, and a fuller near sea with bigger waves lapping in front.
			ws.terrain([])
			ws.no_water()
			ws.sea_band(0.44, 0.74, {"wave_scale": 14.0, "wave_height": 0.010, "opacity": 0.94, "haze": 0.5})
			ws.sea_band(0.58, 1.0, {"wave_scale": 7.0, "wave_height": 0.030, "opacity": 0.96, "haze": 0.0})
			return 0
		_:  # "Coast"
			ws.terrain([
				TerrainLayer.mountains(f["mountain"]),
				TerrainLayer.hills(f["hill"]),
				TerrainLayer.ground(f["sand"]),
			])
			ws.water(WaterBody2D.Mode.OCEAN_BEACH)
			return 16


# ── Region flavour ──────────────────────────────────────────────────────────────
# Palette per terrain role + the region's foliage set, signature time/weather, default
# landform, and how many birds. Fresh TimeOfDay/WeatherPreset instances per call.

static func _flavor(region: String) -> Dictionary:
	match region:
		"Amazon Jungle":
			return {
				"mountain": Color(0.42, 0.52, 0.44), "hill": Color(0.30, 0.46, 0.30),
				"treeline": Color(0.24, 0.42, 0.26), "ground": Color(0.28, 0.44, 0.28),
				"foreground": Color(0.20, 0.38, 0.22), "sand": Color(0.80, 0.78, 0.56),
				"foliage": [_PALM, _BANANA, _FERN, _ROUND],
				"tod": TimeOfDay.noon(), "weather": WeatherPreset.foggy(),
				"birds": 6, "scenario": "River",
			}
		"Swamp":
			return {
				"mountain": Color(0.40, 0.44, 0.42), "hill": Color(0.30, 0.40, 0.30),
				"treeline": Color(0.26, 0.34, 0.28), "ground": Color(0.42, 0.46, 0.34),
				"foreground": Color(0.24, 0.36, 0.26), "sand": Color(0.66, 0.64, 0.48),
				"foliage": [_MANGROVE, _REED, _DEAD, _BUSH],
				"tod": TimeOfDay.dawn(), "weather": WeatherPreset.foggy(),
				"birds": 4, "scenario": "Wetland",
			}
		"Caribbean":
			return {
				"mountain": Color(0.44, 0.58, 0.46), "hill": Color(0.42, 0.60, 0.42),
				"treeline": Color(0.30, 0.48, 0.32), "ground": Color(0.50, 0.62, 0.42),
				"foreground": Color(0.34, 0.52, 0.34), "sand": Color(0.92, 0.86, 0.68),
				"foliage": [_PALM, _ROUND, _BUSH],
				"tod": TimeOfDay.noon(), "weather": WeatherPreset.clear(),
				"birds": 5, "scenario": "Island",
			}
		"Arid Coast":
			return {
				"mountain": Color(0.62, 0.50, 0.40), "hill": Color(0.62, 0.54, 0.36),
				"treeline": Color(0.50, 0.46, 0.30), "ground": Color(0.70, 0.64, 0.44),
				"foreground": Color(0.58, 0.52, 0.34), "sand": Color(0.80, 0.70, 0.48),
				"foliage": [_CACTUS, _DEAD, _BUSH],
				"tod": TimeOfDay.golden_hour(), "weather": WeatherPreset.clear(),
				"birds": 3, "scenario": "Coast",
			}
		"Open Ocean":
			return {
				"mountain": Color(0.58, 0.62, 0.66), "hill": Color(0.52, 0.60, 0.56),
				"treeline": Color(0.44, 0.52, 0.50), "ground": Color(0.50, 0.56, 0.54),
				"foreground": Color(0.42, 0.50, 0.48), "sand": Color(0.78, 0.78, 0.70),
				"foliage": [],
				"tod": TimeOfDay.noon(), "weather": WeatherPreset.cloudy(),
				"birds": 7, "scenario": "Open Sea",
			}
		"Seville (Iberia)":
			return {
				"mountain": Color(0.58, 0.54, 0.48), "hill": Color(0.48, 0.52, 0.34),
				"treeline": Color(0.34, 0.44, 0.30), "ground": Color(0.60, 0.60, 0.42),
				"foreground": Color(0.40, 0.50, 0.34), "sand": Color(0.84, 0.74, 0.52),
				"foliage": [_ROUND, _BUSH],
				"tod": TimeOfDay.golden_hour(), "weather": WeatherPreset.clear(),
				"birds": 4, "scenario": "Coast",
			}
		"England Coast":
			return {
				"mountain": Color(0.52, 0.56, 0.60), "hill": Color(0.36, 0.46, 0.38),
				"treeline": Color(0.24, 0.34, 0.28), "ground": Color(0.42, 0.50, 0.38),
				"foreground": Color(0.30, 0.44, 0.32), "sand": Color(0.72, 0.72, 0.60),
				"foliage": [_PINE, _ROUND, _BUSH],
				"tod": TimeOfDay.dawn(), "weather": WeatherPreset.foggy(),
				"birds": 5, "scenario": "Coast",
			}
		"France Coast":
			return {
				"mountain": Color(0.54, 0.58, 0.62), "hill": Color(0.34, 0.50, 0.36),
				"treeline": Color(0.24, 0.38, 0.28), "ground": Color(0.40, 0.54, 0.38),
				"foreground": Color(0.30, 0.48, 0.32), "sand": Color(0.80, 0.76, 0.56),
				"foliage": [_ROUND, _PINE, _BUSH],
				"tod": TimeOfDay.noon(), "weather": WeatherPreset.cloudy(),
				"birds": 5, "scenario": "River",
			}
		_:  # "Temperate Woodland"
			return {
				"mountain": Color(0.50, 0.54, 0.62), "hill": Color(0.34, 0.48, 0.34),
				"treeline": Color(0.22, 0.36, 0.24), "ground": Color(0.52, 0.60, 0.44),
				"foreground": Color(0.30, 0.48, 0.32), "sand": Color(0.84, 0.78, 0.58),
				"foliage": [_PINE, _ROUND, _BUSH],
				"tod": TimeOfDay.golden_hour(), "weather": WeatherPreset.cloudy(),
				"birds": 5, "scenario": "Lake",
			}


# ── internals ────────────────────────────────────────────────────────────────

static func _load_foliage(paths: Array) -> Array:
	var out: Array = []
	for p in paths:
		var t := load(p)
		if t is Texture2D:
			out.append(t)
	return out
