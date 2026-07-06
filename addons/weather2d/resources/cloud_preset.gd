@tool
class_name CloudPreset
extends Resource
## Cloud style for the Weather System 2D kit — coverage, scale, drift, shading, softness and
## detail for the layered volumetric cloud shader. Its color comes from the [TimeOfDay], and
## weather can darken it, so the same cloud style reads right at any hour and in any storm.
##
## Use the static factories (clear/wispy/scattered/cumulus/overcast/stormy), pass one to
## [method WeatherScene.cloud_style], or pick one in the launcher.

@export_range(-0.4, 1.0) var coverage := 0.2
@export var scale := 1.4
@export_range(0.0, 0.2) var speed := 0.03
@export_range(0.0, 1.0) var dark := 0.45
@export_range(0.0, 1.0) var light := 0.85
@export_range(0.0, 1.0) var density := 0.85
@export_range(0.0, 1.0) var softness := 0.5
@export_range(0.0, 1.0) var detail := 0.5


static func clear() -> CloudPreset:
	var c := CloudPreset.new()
	c.coverage = -0.4 # below the render threshold → an empty sky
	c.density = 0.4
	c.softness = 0.8
	return c


static func wispy() -> CloudPreset:
	var c := CloudPreset.new()
	c.coverage = -0.12
	c.scale = 2.4
	c.speed = 0.045
	c.density = 0.55
	c.softness = 0.9
	c.detail = 0.3
	c.light = 0.95
	return c


static func scattered() -> CloudPreset:
	var c := CloudPreset.new()
	c.coverage = -0.04
	c.scale = 1.2
	c.density = 0.85
	c.softness = 0.5
	c.detail = 0.5
	return c


static func cumulus() -> CloudPreset:
	var c := CloudPreset.new()
	c.coverage = 0.06
	c.scale = 0.8
	c.speed = 0.02
	c.density = 0.97
	c.softness = 0.2
	c.detail = 0.7
	c.dark = 0.4
	c.light = 0.95
	return c


static func overcast() -> CloudPreset:
	var c := CloudPreset.new()
	c.coverage = 0.4
	c.scale = 1.5
	c.density = 0.92
	c.softness = 0.55
	c.detail = 0.4
	c.dark = 0.55
	c.light = 0.72
	return c


static func stormy() -> CloudPreset:
	var c := CloudPreset.new()
	c.coverage = 0.55
	c.scale = 1.2
	c.speed = 0.06
	c.density = 1.0
	c.softness = 0.45
	c.detail = 0.85
	c.dark = 0.24
	c.light = 0.5
	return c
