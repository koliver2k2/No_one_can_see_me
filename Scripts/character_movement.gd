extends CharacterBody2D
class_name Player

const RUN_SPEED := 800
const WALK_SPEED := 400
const CLIMB_SPEED := 400
const JUMP_VELOCITY := -550
const JUMP_VELOCITY_X = 12720
const WALL_JUMP_X := 400
const WALL_JUMP_Y := -450
const GRAVITY := 1000
const MAX_JUMPS := 2

var is_climbing := false
var is_running := false
var jumps_left := MAX_JUMPS
var is_double_jumping := false
var was_on_wall

var is_in_light = false
var is_hidden = false

var sound := 0

@onready var animated_sprite = $Animated_Texture
@onready var wall_shapecast = $ShapeCast2D

func check_for_wall() -> bool:
	if is_on_wall():
		return true
		
	return wall_shapecast.is_colliding()

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
	
	var near_wall = check_for_wall()
	
	if near_wall and not is_on_floor():
		if not is_climbing:
			is_climbing = true
			velocity.y = 0
	else:
		if not near_wall or is_on_floor():
			is_climbing = false

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

		if Input.is_action_just_pressed("ui_accept") and jumps_left > 0:
			is_double_jumping = jumps_left < MAX_JUMPS
			jumps_left -= 1
			velocity.y = JUMP_VELOCITY
			velocity.x = direction * JUMP_VELOCITY_X

	if is_running and is_on_floor():
		velocity.x = direction * RUN_SPEED
		sound = 10
	else:
		velocity.x = direction * WALK_SPEED
		sound = 4

	# 3. Apply Animations and Physics Engine
	handle_animations(direction)
	move_and_slide()
	
	if was_on_wall != is_on_wall():
		if is_on_wall():
			print("Climbing...")
		else:
			print("Not climbing...")
	
	is_running = false
	was_on_wall = is_on_wall()

func _on_street_light_player_entered_light() -> void:
	print("Player entered light...")
	is_in_light = true

func _on_street_light_player_left_light() -> void:
	print("Player left the light...")
	is_in_light = false

func _on_hide_object_player_entered_hide() -> void:
	print("Player entered hiding...")
	is_hidden = true

func _on_hide_object_player_left_hide() -> void:
	print("Player left hiding...")
	is_hidden = false
