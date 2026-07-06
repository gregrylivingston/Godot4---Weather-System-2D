@tool
class_name TerrainLayer
extends Resource
## Describes one parallax terrain band for the Weather System 2D kit.
##
## A [TerrainBand2D] renders from a [TerrainLayer]: distant mountains and hills as noise
## silhouettes, or a sandy [b]ground[/b] that a [WaterBody2D] can wash over. The static
## factory helpers ([method mountains], [method hills], [method treeline], [method ground])
## give tuned starting points for the Phase 3 scene-builder API.

## What the band represents. GROUND uses the sand shader; the rest use the silhouette shader.
enum Role { GROUND, HILL, MOUNTAIN, TREELINE, FOREGROUND }

@export var role: Role = Role.HILL
## Color at the base / nearest edge of the band.
@export var near_color := Color(0.36, 0.45, 0.38)
## Color at the top / most distant edge (atmospheric haze fades toward this).
@export var far_color := Color(0.62, 0.70, 0.78)
## Silhouette height as a fraction of the band (0 = flat bottom, 1 = fills the band).
@export_range(0.0, 1.0) var height := 0.4
## Ruggedness of the silhouette (0 = smooth rolling, 1 = jagged peaks).
@export_range(0.0, 1.0) var roughness := 0.5
## Parallax scroll scale, forwarded to the containing Parallax2D when built.
@export var scroll_scale := Vector2(0.6, 0.8)
## Seed so a layer regenerates identically (Phase 3 determinism).
@export var seed := 0

# --- Ground-only coastline (shared with WaterBody2D so land + water align) ---
## For GROUND: the UV.y where sand begins (the coastline). Match a WaterBody2D's `level`.
@export_range(0.0, 1.0) var coast_level := 0.55
## For GROUND: sine amplitude of the coastline. Match a WaterBody2D's `wave_height`.
@export_range(0.0, 0.2) var wave_height := 0.02
## For GROUND: sine frequency of the coastline. Match a WaterBody2D's `wave_frequency`.
@export var wave_frequency := 8.0


static func mountains(tint := Color(0.42, 0.48, 0.58)) -> TerrainLayer:
	var l := TerrainLayer.new()
	l.role = Role.MOUNTAIN
	l.near_color = tint
	l.far_color = tint.lerp(Color(0.78, 0.83, 0.90), 0.55)
	l.height = 0.5
	l.roughness = 0.8
	l.scroll_scale = Vector2(0.3, 0.4)
	return l


static func hills(tint := Color(0.34, 0.5, 0.36)) -> TerrainLayer:
	var l := TerrainLayer.new()
	l.role = Role.HILL
	l.near_color = tint
	l.far_color = tint.lerp(Color(0.6, 0.72, 0.6), 0.5)
	l.height = 0.6
	l.roughness = 0.35
	l.scroll_scale = Vector2(0.6, 0.75)
	return l


static func treeline(tint := Color(0.2, 0.34, 0.24)) -> TerrainLayer:
	var l := TerrainLayer.new()
	l.role = Role.TREELINE
	l.near_color = tint
	l.far_color = tint.lightened(0.15)
	l.height = 0.3
	l.roughness = 0.6
	l.scroll_scale = Vector2(0.8, 0.9)
	return l


static func foreground(tint := Color(0.28, 0.46, 0.30)) -> TerrainLayer:
	var l := TerrainLayer.new()
	l.role = Role.FOREGROUND
	l.near_color = tint.darkened(0.15)
	l.far_color = tint
	l.height = 0.7
	l.roughness = 0.3
	l.scroll_scale = Vector2(1.2, 1.1)
	return l


static func ground(sand := Color(0.86, 0.78, 0.6)) -> TerrainLayer:
	var l := TerrainLayer.new()
	l.role = Role.GROUND
	l.near_color = sand.darkened(0.2)
	l.far_color = sand
	l.scroll_scale = Vector2(1.0, 1.0)
	l.coast_level = 0.32
	l.wave_height = 0.03
	return l
