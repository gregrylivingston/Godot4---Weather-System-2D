extends CharacterBody2D


@export var SPEED = 300.0


func _physics_process(delta: float) -> void:

	velocity.x =  SPEED
	move_and_slide()
