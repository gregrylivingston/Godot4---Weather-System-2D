@tool
class_name TerrainBand2D
extends ColorRect
## Renders one parallax terrain band from a [TerrainLayer].
##
## GROUND layers use the sand shader ([code]terrain_ground.gdshader[/code]); every other
## role uses the silhouette shader ([code]terrain_silhouette.gdshader[/code]). Like
## [WaterBody2D], it owns its material, so dropping one in and assigning a [member layer]
## is all that's needed.
##
## [codeblock]
## var hills := TerrainBand2D.new()
## hills.layer = TerrainLayer.hills()
## hills.size = Vector2(1920, 300)
## add_child(hills)
## [/codeblock]

const _SILHOUETTE_SHADER := "res://addons/weather2d/shaders/terrain_silhouette.gdshader"
const _GROUND_SHADER := "res://addons/weather2d/shaders/terrain_ground.gdshader"

## The data describing this band. Assign a [TerrainLayer] (or use its static factories).
@export var layer: TerrainLayer:
	set(v):
		if layer != null and layer.changed.is_connected(_rebuild):
			layer.changed.disconnect(_rebuild)
		layer = v
		if layer != null and not layer.changed.is_connected(_rebuild):
			layer.changed.connect(_rebuild)
		_rebuild()


func _enter_tree() -> void:
	_rebuild()


## (Re)build the material for the current layer's role and push its parameters.
func _rebuild() -> void:
	if layer == null:
		return
	var is_ground := layer.role == TerrainLayer.Role.GROUND
	var wanted_path := _GROUND_SHADER if is_ground else _SILHOUETTE_SHADER

	var mat := material as ShaderMaterial
	if mat == null:
		mat = ShaderMaterial.new()
		material = mat
	# Swap the shader only when the role changes shader type.
	if mat.shader == null or mat.shader.resource_path != wanted_path:
		mat.shader = load(wanted_path)

	mat.set_shader_parameter("near_color", layer.near_color)
	mat.set_shader_parameter("far_color", layer.far_color)
	mat.set_shader_parameter("seed", float(layer.seed))
	if is_ground:
		mat.set_shader_parameter("coast_level", layer.coast_level)
		mat.set_shader_parameter("wave_height", layer.wave_height)
		mat.set_shader_parameter("wave_frequency", layer.wave_frequency)
	else:
		mat.set_shader_parameter("height", layer.height)
		mat.set_shader_parameter("roughness", layer.roughness)
