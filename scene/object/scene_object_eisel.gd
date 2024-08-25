@tool extends Sprite2D

@export var update:= false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup_material()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if update:
		update = false
		setup_material()


func setup_material():
	$TEisel.material = material
