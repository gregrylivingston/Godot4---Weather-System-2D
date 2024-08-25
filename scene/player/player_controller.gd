extends Node

@onready var pawn = get_parent() as Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	var direction : float= Input.get_axis("move_left", "move_right") * pawn.WALK_SPEED
	pawn.velocity.x = move_toward(pawn.velocity.x, direction, pawn.ACCELERATION_SPEED * delta)

	var directionxy : float= Input.get_axis("move_up", "move_down") * pawn.WALK_SPEED
	pawn.velocity.y = move_toward(pawn.velocity.y, directionxy, pawn.ACCELERATION_SPEED * delta)
