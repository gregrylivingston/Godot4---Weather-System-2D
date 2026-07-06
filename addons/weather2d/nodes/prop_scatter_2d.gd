@tool
class_name PropScatter2D
extends Node2D
## Scatters vector props (trees, rocks, grass tufts …) along a horizontal band with seeded
## randomness — the same seed always produces the same arrangement. Part of the Weather
## System 2D kit's hybrid art pipeline (SVG assets + shaders).
##
## Assign a few [member textures] (e.g. the SVGs under [code]assets/svg/[/code]) and a
## [member count]. Generated sprites are internal (not saved with the scene) and rebuild
## from the seed on load, so scenes stay tiny and reproducible.
##
## [codeblock]
## var trees := PropScatter2D.new()
## trees.textures = [load("res://assets/svg/tree_round.svg")]
## trees.count = 16
## trees.width = 1800.0
## add_child(trees)
## [/codeblock]

# Animation modes (plain ints so other scripts can set them without cross-class enum refs).
const ANIM_NONE := 0
const ANIM_SWAY := 1
const ANIM_FLY := 2

const _SWAY_SHADER := "res://addons/weather2d/shaders/foliage_wind.gdshader"
const _FLY_SHADER := "res://addons/weather2d/shaders/bird_fly.gdshader"

@export var textures: Array[Texture2D] = []:
	set(v):
		textures = v
		_queue_rebuild()
## How many props to place.
@export var count := 12:
	set(v):
		count = maxi(0, v)
		_queue_rebuild()
## Horizontal spread (props are placed across [-width/2, width/2]).
@export var width := 1800.0:
	set(v):
		width = v
		_queue_rebuild()
## Vertical scatter around the node's baseline, for a natural line.
@export var band_height := 40.0:
	set(v):
		band_height = v
		_queue_rebuild()
@export var seed := 0:
	set(v):
		seed = v
		_queue_rebuild()
@export var scale_min := 0.6:
	set(v):
		scale_min = v
		_queue_rebuild()
@export var scale_max := 1.1:
	set(v):
		scale_max = v
		_queue_rebuild()
## 0 = props snap to an even grid, 1 = fully random within each grid cell. A middle value
## spreads props evenly while still looking natural (no clumps, no gaps).
@export_range(0.0, 1.0) var jitter := 0.7:
	set(v):
		jitter = v
		_queue_rebuild()
## Scale props by depth: those higher in the band (further away) render smaller.
@export var depth_scale := true:
	set(v):
		depth_scale = v
		_queue_rebuild()
## Random per-prop darkening (0 = uniform, up to this fraction darker) for depth variation.
@export_range(0.0, 0.5) var tint_variation := 0.12:
	set(v):
		tint_variation = v
		_queue_rebuild()
## Atmospheric haze: far (higher) props are tinted toward [member haze_color] by this amount.
@export_range(0.0, 1.0) var haze_amount := 0.0:
	set(v):
		haze_amount = v
		_queue_rebuild()
@export var haze_color := Color(0.72, 0.80, 0.88):
	set(v):
		haze_color = v
		_queue_rebuild()
@export var flip_random := true:
	set(v):
		flip_random = v
		_queue_rebuild()

## Animation applied to the scattered sprites: 0 = None, 1 = Sway (foliage), 2 = Fly (birds).
@export_enum("None", "Sway", "Fly") var animation: int = 0:
	set(v):
		animation = v
		_queue_rebuild()
## Random lean, in degrees, for a natural look (ignored for FLY).
@export_range(0.0, 20.0) var rotation_jitter := 3.0:
	set(v):
		rotation_jitter = v
		_queue_rebuild()
## Draw a soft ground shadow under each prop so it reads as planted.
@export var cast_shadows := false:
	set(v):
		cast_shadows = v
		_queue_rebuild()

var _rebuild_queued := false
var _shadows: Array = [] # [{pos: Vector2, r: float}]


func _ready() -> void:
	_rebuild()


func _enter_tree() -> void:
	_queue_rebuild()


func _queue_rebuild() -> void:
	if _rebuild_queued:
		return
	_rebuild_queued = true
	call_deferred("_rebuild")


## Regenerate the sprites deterministically from the seed. Sprites are added with no owner,
## so saving the scene will not serialize them.
func _rebuild() -> void:
	_rebuild_queued = false
	if not is_inside_tree():
		return
	for c in get_children():
		c.queue_free()
	if textures.is_empty() or count <= 0:
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# Stratified placement: one prop per evenly-sized column, jittered within it. This
	# avoids the clumps and gaps of pure-random scattering.
	var slot := width / float(count)
	var items: Array = []
	for i in count:
		var slot_center := -width * 0.5 + (float(i) + 0.5) * slot
		var x := slot_center + rng.randf_range(-0.5, 0.5) * slot * jitter
		var depth := rng.randf() # 0 = far (top of band) … 1 = near (bottom)
		var y := -band_height * 0.5 + depth * band_height
		var s := lerpf(scale_min, scale_max, depth) if depth_scale else rng.randf_range(scale_min, scale_max)
		items.append({
			"x": x,
			"y": y,
			"depth": depth,
			"s": s,
			"tex": textures[rng.randi() % textures.size()],
			"flip": flip_random and rng.randf() < 0.5,
			"tint": 1.0 - rng.randf_range(0.0, tint_variation),
			"rot": deg_to_rad(rng.randf_range(-rotation_jitter, rotation_jitter)),
		})
	# Draw far (higher) props first so nearer ones overlap them.
	items.sort_custom(func(a, b): return a["y"] < b["y"])

	# One shared animation material for the whole scatter (per-sprite variation comes from
	# world position inside the shader).
	var anim_mat: ShaderMaterial = null
	if animation == ANIM_SWAY:
		anim_mat = ShaderMaterial.new()
		anim_mat.shader = load(_SWAY_SHADER)
	elif animation == ANIM_FLY:
		anim_mat = ShaderMaterial.new()
		anim_mat.shader = load(_FLY_SHADER)

	_shadows.clear()
	for it in items:
		var tex: Texture2D = it["tex"]
		if tex == null:
			continue
		var sp := Sprite2D.new()
		sp.texture = tex
		sp.flip_h = it["flip"]
		# Pivot at the base of the sprite so it "stands" on its placement point.
		sp.offset = Vector2(0.0, -tex.get_height() * 0.5)
		sp.position = Vector2(it["x"], it["y"])
		sp.scale = Vector2.ONE * it["s"]
		if animation != ANIM_FLY:
			sp.rotation = it["rot"]
		if anim_mat != null:
			sp.material = anim_mat
		var t: float = it["tint"]
		var col := Color(t, t, t, 1.0)
		# Far props fade toward the haze color.
		col = col.lerp(haze_color, haze_amount * (1.0 - it["depth"]))
		sp.modulate = col
		add_child(sp)
		if cast_shadows and animation != ANIM_FLY:
			_shadows.append({"pos": sp.position, "r": tex.get_width() * it["s"] * 0.42})
	queue_redraw()


func _draw() -> void:
	if not cast_shadows:
		return
	# Soft flattened ellipse under each prop. Drawn before children, so behind the sprites.
	for sh in _shadows:
		draw_set_transform(sh["pos"], 0.0, Vector2(1.0, 0.3))
		draw_circle(Vector2.ZERO, sh["r"], Color(0.0, 0.0, 0.0, 0.12))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
