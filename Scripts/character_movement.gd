extends CharacterBody2D

class_name Player

const RUN_SPEED := 800
const WALK_SPEED := 400
const CLIMB_SPEED := WALK_SPEED / 2
const JUMP_VELOCITY := -850

@export var is_in_light = false
@export var is_hidden = false
@export var climb_trapdoor_down_duration: float = 1.0

var used_interaction := false
var is_climbing_trapdoor:= false
var is_tile_trapdoor := false
var climb_down_tween: Tween
var wall_direction := 0.0
var sound := 0

enum MOVEMENT_STATES {WALK, RUN, CROUCH, WALL}
var movement_state = MOVEMENT_STATES.WALK

@onready var animated_sprite = $Animated_Texture
@onready var make_sound_sprite = $Make_Sound
@onready var player_collision = $Main_Collision
@onready var crouch_collision = $Crouch_Collision
@onready var climb_collision = $Climb_Collision
@onready var head_raycast = $Head_ray_cast
@onready var waist_raycast = $Waist_Ray_Cast
@onready var vertical_raycast = $Vertical_Ray_Cast
@onready var down_raycast = $Down_Ray_Cast
@onready var trapdoor_hint = $Label

func handle_animations(direction):
	if direction != 0:
		animated_sprite.flip_h = (direction < 0)
	
	if is_climbing_trapdoor:
		if animated_sprite.animation != "trapdoor_up":
			animated_sprite.play("trapdoor_up")
	elif not is_on_floor():
		if velocity.y > 0 and movement_state != MOVEMENT_STATES.WALL:
			animated_sprite.play("fall")
		elif movement_state == MOVEMENT_STATES.WALL:
			animated_sprite.play("climb")
		else:
			animated_sprite.play("jump")
	elif direction != 0:
		if movement_state == MOVEMENT_STATES.RUN:
			animated_sprite.play("run")
		elif movement_state == MOVEMENT_STATES.CROUCH:
			animated_sprite.play("crouch_walk")
		else:
			animated_sprite.play("walk")
	elif movement_state == MOVEMENT_STATES.CROUCH:
		animated_sprite.play("crouch")
	else:
		animated_sprite.play("idle")
	
func _physics_process(delta: float) -> void:
	if movement_state == MOVEMENT_STATES.WALK or movement_state == MOVEMENT_STATES.RUN or movement_state == MOVEMENT_STATES.CROUCH:
		walk_state(delta)
	elif movement_state == MOVEMENT_STATES.WALL: 
		wall_state(delta)
	
	used_interaction = false
	
	_handle_collision_size()
	_update_raycast_directions()
	_scan_environment()
	move_and_slide()
	
	
func walk_state(delta):
	var direction := Input.get_axis("ui_left", "ui_right")
	
	if is_on_wall_only() and direction == -get_wall_normal().x: 
		movement_state = MOVEMENT_STATES.WALL
		wall_direction = -get_wall_normal().x
		velocity.x = wall_direction * 15.0 
		velocity.y = 0.0 
		return
	
	if is_on_floor() and is_tile_trapdoor:
		movement_state = MOVEMENT_STATES.CROUCH
	
	if not is_on_floor(): velocity += get_gravity() * delta
	
	if (Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right")) and Input.is_action_pressed("run") and is_on_floor() and movement_state != MOVEMENT_STATES.CROUCH:
		movement_state = MOVEMENT_STATES.RUN
	elif (Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right")) and movement_state != MOVEMENT_STATES.CROUCH:
		movement_state = MOVEMENT_STATES.WALK
	
	# Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		movement_state = MOVEMENT_STATES.WALK
		
	if direction == 0 and not movement_state == MOVEMENT_STATES.WALL and not movement_state == MOVEMENT_STATES.CROUCH:
		movement_state = MOVEMENT_STATES.WALK
	
	if direction:
		if movement_state == MOVEMENT_STATES.RUN:
			velocity.x = direction * RUN_SPEED
		else:
			velocity.x = direction * WALK_SPEED
	else:
		if movement_state == MOVEMENT_STATES.RUN:
			velocity.x = move_toward(velocity.x, 0, RUN_SPEED)
		else:
			velocity.x = move_toward(velocity.x, 0, WALK_SPEED)
	
	if movement_state == MOVEMENT_STATES.RUN:
		make_sound_sprite.visible = true
		sound = 10
	else:
		make_sound_sprite.visible = false
		sound = 4
	
	_update_raycast_directions()
	handle_animations(direction)

func wall_state(_delta):
	if not is_on_wall():
		movement_state = MOVEMENT_STATES.WALK
		return
	if is_tile_trapdoor:
		return
	
	velocity = Vector2.ZERO
	velocity.x = wall_direction * 15.0
	
	if Input.is_action_just_pressed("ui_accept"):
		velocity.y = JUMP_VELOCITY
		movement_state = MOVEMENT_STATES.WALK
		return
	
	if (not head_raycast.is_colliding() or not waist_raycast.is_colliding()) and vertical_raycast.is_colliding():
		movement_state = MOVEMENT_STATES.CROUCH
		velocity.x = wall_direction * WALK_SPEED
		print("Position earlier: ", global_position)
		global_position.x = global_position.x + (wall_direction * 100)
		global_position.y = global_position.y - 120
		print("Position after: ", global_position)
		return
	
	var v_direction := Input.get_axis("ui_up", "ui_down")
	
	if v_direction:
		velocity.y = v_direction * CLIMB_SPEED
	else:
		velocity.y = move_toward(velocity.y, 0, WALK_SPEED) 
	
	handle_animations(wall_direction)

func _handle_collision_size():
	if movement_state == MOVEMENT_STATES.CROUCH:
		#print("crouching")
		crouch_collision.disabled = false
		crouch_collision.visible = true
		
		climb_collision.disabled = true
		climb_collision.visible = false
	elif movement_state == MOVEMENT_STATES.WALL:		
		print("climbing")
		crouch_collision.disabled = true
		crouch_collision.visible = false
		
		climb_collision.disabled = false
		climb_collision.visible = true
	else:		
		crouch_collision.disabled = true
		crouch_collision.visible = false
		
		climb_collision.disabled = false
		climb_collision.visible = true

func _check_for_trapdoor():
	trapdoor_hint.visible = false
	
	if not waist_raycast.is_colliding() and not head_raycast.is_colliding() and not vertical_raycast.is_colliding() and not down_raycast.is_colliding():
		movement_state = MOVEMENT_STATES.WALK
		return
	
	if waist_raycast.is_colliding():
		var collider = waist_raycast.get_collider()
		
		if collider is TileMapLayer:
			var hit_point = waist_raycast.get_collision_point()
			var push_direction = waist_raycast.target_position.normalized()
			
			var tile_point = hit_point + (push_direction * 2.0)
			
			var map_coords = collider.local_to_map(collider.to_local(tile_point))
			var tile_data = collider.get_cell_tile_data(map_coords)
			
			if (tile_data and tile_data.get_custom_data("is_trapdoor") == true):
				trapdoor_hint.visible = true
				is_tile_trapdoor = true
				
				if Input.is_action_just_pressed("interact"):
					collider.set_cell(map_coords, 0, Vector2i(2, 0))
					trapdoor_hint.visible = false
					used_interaction = true
			else:
				is_tile_trapdoor = false
	
	if head_raycast.is_colliding():
		var collider = head_raycast.get_collider()
		
		if collider is TileMapLayer:
			var hit_point = head_raycast.get_collision_point()
			var push_direction = head_raycast.target_position.normalized()
			
			var tile_point = hit_point + (push_direction * 2.0)
			
			var map_coords = collider.local_to_map(collider.to_local(tile_point))
			var tile_data = collider.get_cell_tile_data(map_coords)
			
			if (tile_data and tile_data.get_custom_data("is_trapdoor") == true):
				trapdoor_hint.visible = true
				is_tile_trapdoor = true
				
				if Input.is_action_just_pressed("interact"):
					collider.set_cell(map_coords, 0, Vector2i(2, 0))
					trapdoor_hint.visible = false
					used_interaction = true
			else:
				is_tile_trapdoor = false
		
	#if vertical_raycast.is_colliding():
		#var collider = vertical_raycast.get_collider()
		#
		#if collider is TileMapLayer:
			#var hit_point = vertical_raycast.get_collision_point()
			#var push_direction = vertical_raycast.target_position.normalized()
			#var tile_point = hit_point + (push_direction * 2.0)
			#
			#var map_coords = collider.local_to_map(collider.to_local(tile_point))
			#var tile_data = collider.get_cell_tile_data(map_coords)
			#
			#if (tile_data and tile_data.get_custom_data("is_trapdoor") == true):
				#trapdoor_hint.visible = true
				#is_tile_trapdoor = true
				#
				#if Input.is_action_just_pressed("interact"):
					#collider.set_cell(map_coords, 0, Vector2i(2, 0))
					#trapdoor_hint.visible = false
					#used_interaction = true
			#else:
				#is_tile_trapdoor = false

	if down_raycast.is_colliding():
		var collider = down_raycast.get_collider()

		if collider is TileMapLayer:
			var hit_point = down_raycast.get_collision_point()
			var push_direction = down_raycast.target_position.normalized()
			
			var tile_point = hit_point + (push_direction * 2.0)
			
			var map_coords = collider.local_to_map(collider.to_local(tile_point))
			var tile_data = collider.get_cell_tile_data(map_coords)
			
			if (tile_data and tile_data.get_custom_data("is_trapdoor") == true):
				trapdoor_hint.visible = true
				is_tile_trapdoor = true
				
				if Input.is_action_just_pressed("interact"):
					collider.set_cell(map_coords, 0, Vector2i(2, 0))
					trapdoor_hint.visible = false
					used_interaction = true
			else:
				is_tile_trapdoor = false

func _update_raycast_directions():
	if movement_state == MOVEMENT_STATES.WALL:
		var cast_distance = 15 * sign(wall_direction) 
		head_raycast.target_position.x = cast_distance
		waist_raycast.target_position.x = cast_distance
	else:
		var horizontal_direction := Input.get_axis("ui_left", "ui_right")
		if horizontal_direction != 0:
			var cast_distance = 15 * sign(horizontal_direction)
			head_raycast.target_position.x = cast_distance
			waist_raycast.target_position.x = cast_distance

func _scan_environment():
	if (head_raycast.is_colliding() and not waist_raycast.is_colliding()) and is_on_floor():
		movement_state = MOVEMENT_STATES.CROUCH
	else:
		#_check_for_collision_above_player()
		trapdoor_hint.visible = false
	_check_for_trapdoor()

func _check_for_collision_above_player():
	if not vertical_raycast.is_colliding() and not movement_state == MOVEMENT_STATES.WALL and movement_state == MOVEMENT_STATES.CROUCH:
		print("forcing walk")
		movement_state = MOVEMENT_STATES.WALK

func _on_hide_object_player_entered_hide() -> void:
	is_hidden = true

func _on_hide_object_player_left_hide() -> void:
	is_hidden = false

func _on_npc_human_player_entered_light() -> void:
	is_in_light = true

func _on_npc_human_player_left_light() -> void:
	is_in_light = false

func _on_street_light_player_entered_street_light() -> void:
	is_in_light = true

func _on_street_light_player_left_street_light() -> void:
	is_in_light = false

func _on_hook_player_hooks_themselves() -> void:
	animated_sprite.play("grapple")

func _on_collectible_player_collected_collectible() -> void:
	pass # Replace with function body.
