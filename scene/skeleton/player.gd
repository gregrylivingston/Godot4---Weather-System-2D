class_name Player
extends CharacterBody2D

# Keep this in sync with the AnimationTree's state names.
const States = {
	IDLE = "idle",
	WALK = "walk",
	RUN = "run",
	FLY = "fly",
	FALL = "fall",
}

@export var WALK_SPEED := 200.0
var ACCELERATION_SPEED := WALK_SPEED * 6.0
const JUMP_VELOCITY = -400.0
## Maximum speed at which the player can fall.
const TERMINAL_VELOCITY = 400

var falling_slow = false
var falling_fast = false
var no_move_horizontal_time = 0.0

@onready var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var sprite = $Sprite2D
@onready var sprite_scale = sprite.scale.x


@export_category("Textures")
@export var backTexture: Texture2D
@onready var frontTexture = %Body.texture
@export var backOfHeadTexture: Texture2D
@onready var headTexture = %Head.texture
var isFrontFacing: bool = true

func _ready():
	$AnimationTree.active = true


func _physics_process(delta: float) -> void:
	var is_jumping = false
	if Input.is_action_just_pressed("jump"):
		is_jumping = try_jump()
	elif Input.is_action_just_released("jump") and velocity.y < 0.0:
		# The player let go of jump early, reduce vertical momentum.
		velocity.y *= 0.6
	# Fall.
	#velocity.y = minf(TERMINAL_VELOCITY, velocity.y + gravity * delta)

	var direction := Input.get_axis("move_left", "move_right") * WALK_SPEED
	velocity.x = move_toward(velocity.x, direction, ACCELERATION_SPEED * delta)

	var directionxy := Input.get_axis("move_up", "move_down") * WALK_SPEED
	velocity.y = move_toward(velocity.y, directionxy, ACCELERATION_SPEED * delta)


	if no_move_horizontal_time > 0.0:
		# After doing a hard fall, don't move for a short time.
		velocity.x = 0.0
		no_move_horizontal_time -= delta

	#make sure the art is facing the right direction - x
	if not is_zero_approx(velocity.x):
		if velocity.x > 0.0:
			if isFrontFacing:
				sprite.scale.x = 1.0 * sprite_scale
				if is_instance_valid(%Mouth):if %Mouth.scale.x < 0: %Mouth.scale.x *= -1.0
			else: sprite.scale.x = -1.0 * sprite_scale

		else:
			if isFrontFacing:
				sprite.scale.x = -1.0 * sprite_scale
				if is_instance_valid(%Mouth):if %Mouth.scale.x < 0: %Mouth.scale.x *= 1.0
			else: sprite.scale.x = 1.0 * sprite_scale

			
	#make sure the art is facing the right direction - x
	if (not is_zero_approx(velocity.y) or not is_zero_approx(velocity.x)) && is_instance_valid(backTexture):
		if velocity.y < 0.0:
			set_textures(false)
		else:
			set_textures(true)

			
	move_and_slide()

	# After applying our motion, update our animation to match.

	# Calculate falling speed for animation purposes.
	if velocity.y >= TERMINAL_VELOCITY:
		falling_fast = true
		falling_slow = false
	elif velocity.y > 300:
		falling_slow = true

	if is_jumping:
		$AnimationTree["parameters/jump/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE

	if true:#is_on_floor():
		# Most animations change when we run, land, or take off.
		if falling_fast:
			$AnimationTree["parameters/land_hard/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
			no_move_horizontal_time = 0.4
		elif falling_slow:
			$AnimationTree["parameters/land/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE

		if abs(velocity.x) > 50 or abs(velocity.y) > 50:
			$AnimationTree["parameters/state/transition_request"] = States.WALK#States.RUN
			$AnimationTree["parameters/run_timescale/scale"] = abs(velocity.x) / 60
		elif velocity.x:
			$AnimationTree["parameters/state/transition_request"] = States.WALK
			$AnimationTree["parameters/walk_timescale/scale"] = abs(velocity.x) / 12
		else:
			$AnimationTree["parameters/state/transition_request"] = States.IDLE

		falling_fast = false
		falling_slow = false
	else:
		if velocity.y > 0:
			$AnimationTree["parameters/state/transition_request"] = States.FALL
		else:
			$AnimationTree["parameters/state/transition_request"] = States.FLY

func set_textures(isFront: bool) -> void:
	if isFront:
		%Mouth.visible = true
		%Head.texture = headTexture
	else:
		%Mouth.visible = false
		%Head.texture = backOfHeadTexture

	for i in [$Sprite2D/Polygons/RightArm, $Sprite2D/Polygons/RightLeg, $Sprite2D/Polygons/Body, $Sprite2D/Polygons/LeftLeg, $Sprite2D/Polygons/Chin, $Sprite2D/Polygons/LeftArm]:
		if isFront:
			i.texture = frontTexture
		else:
			i.texture = backTexture
			
	for i in [%LeftArm, %RightArm, %RightLeg, %LeftLeg]:
		pass
#		if isFront && i.scale.x < 0 :i.scale.x *= -1
#		elif not isFront &&  i.scale.x > 0:i.scale.x *= -1



func try_jump() -> bool:
	if is_on_floor():
		velocity.y = JUMP_VELOCITY
		return true
	return false
