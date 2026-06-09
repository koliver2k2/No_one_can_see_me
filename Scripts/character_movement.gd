extends CharacterBody2D

const RUN_SPEED := 280
const WALK_SPEED := 180
const CLIMB_SPEED := 150
const JUMP_VELOCITY := -350
const RUN_JUMP_VELOCITY_X = 520
const WALL_JUMP_X := 400
const WALL_JUMP_Y := -450
const GRAVITY := 1000
const MAX_JUMPS := 2

var is_climbing := false
var is_running := false
var jumps_left := MAX_JUMPS
var is_double_jumping := false  # NEW

@onready var animated_sprite = $Animated_Texture

func handle_animations(direction):
	if is_climbing:
		var climb_direction = Input.get_axis("ui_up", "ui_down")
		if climb_direction != 0:
			animated_sprite.play("climb")
		else:
			animated_sprite.pause()
	else:
		if direction != 0:
			animated_sprite.flip_h = (direction < 0)

		if not is_on_floor():
			if velocity.y > 0:
				animated_sprite.play("fall")
			elif is_double_jumping:
				animated_sprite.play("double_jump")
			else:
				animated_sprite.play("jump")
		elif direction != 0:
			if is_running:
				animated_sprite.play("run")
			else:
				animated_sprite.play("walk")
		else:
			animated_sprite.play("idle")

func _physics_process(delta):
	var direction = Input.get_axis("ui_left", "ui_right")

	if (Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right")) and Input.is_action_pressed("run"):
		is_running = true

	if is_on_floor():
		jumps_left = MAX_JUMPS
		is_double_jumping = false

	# 1. Check Wall State
	if is_on_wall() and direction != 0:
		if not is_climbing:
			is_climbing = true
			velocity.y = 0
	else:
		if not is_on_wall() or is_on_floor():
			is_climbing = false

	# 2. Handle Movement Physics
	if is_climbing:
		var climb_direction = Input.get_axis("ui_up", "ui_down")
		velocity.y = climb_direction * CLIMB_SPEED
		velocity.x = 0

		if Input.is_action_just_pressed("ui_accept"):
			is_climbing = false
			jumps_left = MAX_JUMPS
			is_double_jumping = false
			var wall_normal = get_wall_normal()
			velocity.x = wall_normal.x * WALL_JUMP_X
			velocity.y = WALL_JUMP_Y
			animated_sprite.flip_h = (velocity.x < 0)
	else:
		if not is_on_floor():
			velocity.y += GRAVITY * delta

		if Input.is_action_just_pressed("ui_accept") and jumps_left > 0 and not Input.is_action_pressed("crouch"):
			is_double_jumping = jumps_left < MAX_JUMPS
			jumps_left -= 1
			velocity.y = JUMP_VELOCITY
			if is_running:
				velocity.x = direction * RUN_JUMP_VELOCITY_X

		if is_running and is_on_floor():
			velocity.x = direction * RUN_SPEED
		else:
			velocity.x = direction * WALK_SPEED

	# 3. Apply Animations and Physics Engine
	handle_animations(direction)
	move_and_slide()
	is_running = false
