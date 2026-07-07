@tool
class_name Regions
extends RefCounted
## Region recipes for Lost Settlement backdrops.
##
## Where [Scenarios] gives generic scene types (Beach / River / Mountains …), [Regions] gives
## the flavoured places the colonial game actually visits — one per world biome, an open-ocean
## scene for at-sea events, and the European departure ports. Each returns a configured (not
## yet built) [WeatherScene] with bespoke geography (terrain stack, water, planted props) and
## a default time-of-day / weather mood. The naturalistic look is kept, with a light period
## grade (muted, slightly warm painterly) so the plates sit as aged illustrations in the
## game's UI rather than fully-saturated screenshots.
##
## [codeblock]
## # By name (the launcher / a preview):
## add_child(Regions.build("Amazon Jungle", {"seed": 7}).build())
## # From a Lost Settlement destination site's biome (0..4 == MapSettings.Biome):
## add_child(Regions.for_biome(site.biome, {"seed": run_seed}).build())
## [/codeblock]
##
## `opts` keys (all optional): seed:int, time_of_day:TimeOfDay, weather:WeatherPreset,
## props:bool, birds:bool, painterly:bool (default true), live:bool, day_night_speed:float,
## low_graphics:bool.

# Period grade shared by every region: mute the naturalistic frame a touch and warm it, so it
# reads as an aged painted plate. Tuned "slight" on purpose — this is a nudge, not a restyle.
const _GRADE_SATURATION := 0.82
const _GRADE_WARMTH := 0.03

# Order matches the launcher's picker. The first five line up with the game's biomes; then
# open ocean (journey events) and the three European departure ports (departure events).
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

# MapSettings.Biome ordering in Lost Settlement: TEMPERATE, JUNGLE, SWAMP, CARIBBEAN, ARID.
const _BIOME_REGION := [
	"Temperate Woodland",
	"Amazon Jungle",
	"Swamp",
	"Caribbean",
	"Arid Coast",
]

const _PALM := "res://assets/svg/tree_palm.svg"
const _ROUND := "res://assets/svg/tree_round.svg"
const _PINE := "res://assets/svg/tree_pine.svg"
const _BUSH := "res://assets/svg/bush.svg"
const _FERN := "res://assets/svg/fern.svg"
const _BANANA := "res://assets/svg/banana.svg"
const _MANGROVE := "res://assets/svg/mangrove.svg"
const _CACTUS := "res://assets/svg/cactus.svg"
const _REED := "res://assets/svg/reed.svg"
const _DEAD := "res://assets/svg/dead_tree.svg"


static func build(region: String, opts: Dictionary = {}) -> WeatherScene:
	match region:
		"Amazon Jungle": return jungle(opts)
		"Swamp": return swamp(opts)
		"Caribbean": return caribbean(opts)
		"Arid Coast": return arid(opts)
		"Open Ocean": return ocean(opts)
		"Seville (Iberia)": return seville(opts)
		"England Coast": return england(opts)
		"France Coast": return france(opts)
		_: return temperate(opts)


## The region name for a Lost Settlement biome id (MapSettings.Biome). Out-of-range → temperate.
static func region_for_biome(biome: int) -> String:
	if biome >= 0 and biome < _BIOME_REGION.size():
		return _BIOME_REGION[biome]
	return _BIOME_REGION[0]


## Build straight from a biome id — the entry point the game itself would call.
static func for_biome(biome: int, opts: Dictionary = {}) -> WeatherScene:
	return build(region_for_biome(biome), opts)


# ── Regions ─────────────────────────────────────────────────────────────────────

static func temperate(opts: Dictionary = {}) -> WeatherScene:
	var ws := _base(opts, TimeOfDay.golden_hour(), WeatherPreset.cloudy())
	ws.terrain([
		TerrainLayer.mountains(Color(0.50, 0.54, 0.62)),
		TerrainLayer.hills(Color(0.34, 0.48, 0.34)),
		TerrainLayer.treeline(Color(0.22, 0.36, 0.24)),
		TerrainLayer.ground(Color(0.58, 0.62, 0.44)),
	])
	ws.water(WaterBody2D.Mode.RIVER)
	if _want(opts, "props"):
		ws.props(true, 18, [load(_PINE), load(_ROUND), load(_BUSH)])
	_maybe_birds(ws, opts, 5)
	return ws


static func jungle(opts: Dictionary = {}) -> WeatherScene:
	# Dense, humid, hemmed in — a broad brown river running back into green country. Fog on.
	var ws := _base(opts, TimeOfDay.noon(), WeatherPreset.foggy())
	var far := TerrainLayer.hills(Color(0.30, 0.46, 0.30))
	far.height = 0.85
	var bank := TerrainLayer.hills(Color(0.24, 0.42, 0.26))
	bank.height = 0.95
	ws.terrain([
		TerrainLayer.mountains(Color(0.42, 0.52, 0.44)),
		far,
		bank,
		TerrainLayer.foreground(Color(0.20, 0.38, 0.22)),
	])
	ws.water(WaterBody2D.Mode.RIVER)
	if _want(opts, "props"):
		ws.props(true, 18, [load(_PALM), load(_BANANA), load(_FERN), load(_ROUND)])
	_maybe_birds(ws, opts, 6)
	return ws


static func swamp(opts: Dictionary = {}) -> WeatherScene:
	# Flat, low, still black water; mangroves on prop-roots and reed beds; morning mist.
	var ws := _base(opts, TimeOfDay.dawn(), WeatherPreset.foggy())
	ws.terrain([
		TerrainLayer.treeline(Color(0.26, 0.34, 0.28)),
		TerrainLayer.hills(Color(0.30, 0.40, 0.30)),
		TerrainLayer.ground(Color(0.42, 0.46, 0.34)),
	])
	ws.water(WaterBody2D.Mode.STILL)
	if _want(opts, "props"):
		ws.props(true, 16, [load(_MANGROVE), load(_REED), load(_DEAD), load(_BUSH)])
	_maybe_birds(ws, opts, 4)
	return ws


static func caribbean(opts: Dictionary = {}) -> WeatherScene:
	# Bright low island, white sand, clear turquoise shallows, palms — the classic landfall.
	var ws := _base(opts, TimeOfDay.noon(), WeatherPreset.clear())
	ws.terrain([
		TerrainLayer.hills(Color(0.42, 0.60, 0.42)),
		TerrainLayer.ground(Color(0.92, 0.86, 0.68)),
	])
	ws.water(WaterBody2D.Mode.OCEAN_BEACH)
	if _want(opts, "props"):
		ws.props(true, 14, [load(_PALM), load(_ROUND), load(_BUSH)])
	_maybe_birds(ws, opts, 5)
	return ws


static func arid(opts: Dictionary = {}) -> WeatherScene:
	# Dry coast: bare stony relief, sparse cactus and rock, a hard clear light.
	var ws := _base(opts, TimeOfDay.golden_hour(), WeatherPreset.clear())
	ws.terrain([
		TerrainLayer.mountains(Color(0.62, 0.50, 0.40)),
		TerrainLayer.mountains(Color(0.66, 0.54, 0.42)),
		TerrainLayer.hills(Color(0.62, 0.54, 0.36)),
		TerrainLayer.ground(Color(0.80, 0.70, 0.48)),
	])
	ws.water(WaterBody2D.Mode.OCEAN_BEACH)
	if _want(opts, "props"):
		ws.props(true, 12, [load(_CACTUS), load(_DEAD), load(_BUSH)])
	_maybe_birds(ws, opts, 3)
	return ws


static func ocean(opts: Dictionary = {}) -> WeatherScene:
	# The open sea — the journey phase. Distant haze bank, wide water, a wheeling flock.
	var ws := _base(opts, TimeOfDay.noon(), WeatherPreset.cloudy())
	var haze := TerrainLayer.mountains(Color(0.58, 0.62, 0.66))
	haze.height = 0.16
	ws.terrain([haze])
	ws.water(WaterBody2D.Mode.STILL, 0.42)
	ws.props(false)
	_maybe_birds(ws, opts, 7)
	return ws


static func seville(opts: Dictionary = {}) -> WeatherScene:
	# The Mediterranean departure — warm hills, olive-grove greens, a calm harbour.
	var ws := _base(opts, TimeOfDay.golden_hour(), WeatherPreset.clear())
	ws.terrain([
		TerrainLayer.mountains(Color(0.58, 0.54, 0.48)),
		TerrainLayer.hills(Color(0.48, 0.52, 0.34)),
		TerrainLayer.ground(Color(0.72, 0.66, 0.46)),
	])
	ws.water(WaterBody2D.Mode.STILL)
	if _want(opts, "props"):
		ws.props(true, 14, [load(_ROUND), load(_BUSH)])
	_maybe_birds(ws, opts, 4)
	return ws


static func england(opts: Dictionary = {}) -> WeatherScene:
	# A grey northern departure — cool cliffs, pines, a low mist off the Channel.
	var ws := _base(opts, TimeOfDay.dawn(), WeatherPreset.foggy())
	ws.terrain([
		TerrainLayer.mountains(Color(0.52, 0.56, 0.60)),
		TerrainLayer.hills(Color(0.36, 0.46, 0.38)),
		TerrainLayer.treeline(Color(0.24, 0.34, 0.28)),
		TerrainLayer.ground(Color(0.50, 0.56, 0.42)),
	])
	ws.water(WaterBody2D.Mode.OCEAN_BEACH)
	if _want(opts, "props"):
		ws.props(true, 16, [load(_PINE), load(_ROUND), load(_BUSH)])
	_maybe_birds(ws, opts, 5)
	return ws


static func france(opts: Dictionary = {}) -> WeatherScene:
	# A temperate Atlantic departure — soft green country and a wide river mouth.
	var ws := _base(opts, TimeOfDay.noon(), WeatherPreset.cloudy())
	var bank := TerrainLayer.hills(Color(0.34, 0.50, 0.36))
	bank.height = 0.95
	ws.terrain([
		TerrainLayer.mountains(Color(0.54, 0.58, 0.62)),
		bank,
		TerrainLayer.foreground(Color(0.30, 0.48, 0.32)),
	])
	ws.water(WaterBody2D.Mode.RIVER)
	if _want(opts, "props"):
		ws.props(true, 16, [load(_ROUND), load(_PINE), load(_BUSH)])
	_maybe_birds(ws, opts, 5)
	return ws


# ── internals ────────────────────────────────────────────────────────────────

static func _base(opts: Dictionary, default_tod: TimeOfDay, default_weather: WeatherPreset) -> WeatherScene:
	var ws := WeatherScene.new()
	ws.set_seed(int(opts.get("seed", 1)))
	ws.time_of_day(opts.get("time_of_day", default_tod))
	ws.weather(opts.get("weather", default_weather))
	# Naturalistic look + the light period grade (muted, warm) so plates fit the game's UI.
	ws.painterly(bool(opts.get("painterly", true)), _GRADE_SATURATION, _GRADE_WARMTH)
	if bool(opts.get("live", false)):
		ws.live(true, float(opts.get("day_night_speed", 0.0)))
	if bool(opts.get("low_graphics", false)):
		ws.low_graphics(true)
	return ws


static func _want(opts: Dictionary, key: String) -> bool:
	return bool(opts.get(key, true))


static func _maybe_birds(ws: WeatherScene, opts: Dictionary, count: int) -> void:
	if bool(opts.get("birds", true)):
		ws.birds(true, count)
