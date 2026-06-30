extends CharacterBody2D
class_name NPC_Human

signal player_entered_light
signal player_left_light

const WALK_SPEED := 400
const TIME_PER_STATE: float = 2.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var flashlight_collision = $Area2D/CollisionPolygon2D
@onready var flashlight = $Area2D
@onready var seen_alert = $Seen_Alert
@onready var heard_alert = $Heard_Alert

@export var hearing_range: float = 2000.0
@export var flashlight_range: float = 1200.0
@export var closest_range: float = 300.0
@export var street_light_range: = 3200.0
var player: Node2D = null
var is_player_in_light := false

enum State { WALK_LEFT, IDLE_1, WALK_RIGHT, IDLE_2, INVESTIGATING, SEARCHING, RETURNING }
var current_state: State = State.IDLE_2

var starting_position: Vector2
var target_position: Vector2 = Vector2.ZERO

var is_running := false
var is_idle := false

var state_timer: Timer

func handle_animations(direction):
	if direction != 0:
		animated_sprite.play("walk")
	else:
		animated_sprite.play("idle")

func _ready() -> void:
	state_timer = Timer.new()
	state_timer.wait_time = TIME_PER_STATE
	state_timer.autostart = true
	add_child(state_timer)
	state_timer.timeout.connect(_on_timer_timeout)
	
	get_tree().root.ready.connect(_find_player)
	
	flashlight.rotation = 70.0
	seen_alert.visible = false
	starting_position = global_position

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	else:
		push_warning("NPC couldn't find a player node in the 'player' group!")

func _process(delta):
	# Closest range -> game over
	_check_for_player_in_eyesight()
	
	# Flashlight range -> 2 seconds to escape, or game over
	_check_for_player_in_flashlight_range()
	
	# Sight range, if Player under street light
	_check_for_player_under_street_light()
	
	# Longest range -> NPC goes to check, if player is there
	_check_for_player_sound()

func _physics_process(_delta: float) -> void:
	match current_state:
		State.WALK_LEFT, State.IDLE_1, State.WALK_RIGHT, State.IDLE_2:
			_handle_patrol_movement()
		State.INVESTIGATING, State.RETURNING:
			_handle_target_movement()
		State.SEARCHING:
			velocity = Vector2.ZERO
			handle_animations(0)
			move_and_slide()

func _handle_patrol_movement() -> void:
	match current_state:
		State.WALK_LEFT:
			velocity.x = -WALK_SPEED
			animated_sprite.flip_h = true
			flashlight.rotation_degrees = 140.0
			handle_animations(velocity.x)
		State.WALK_RIGHT:
			velocity.x = WALK_SPEED
			animated_sprite.flip_h = false
			flashlight.rotation = 70.0
			handle_animations(velocity.x)
		State.IDLE_1, State.IDLE_2:
			velocity.x = 0
			handle_animations(velocity.x)
	move_and_slide()

func _handle_target_movement() -> void:
	var x_direction = sign(target_position.x - global_position.x)
	
	velocity.x = x_direction * WALK_SPEED
	
	if x_direction != 0:
		animated_sprite.flip_h = x_direction < 0
		if x_direction < 0:
			flashlight.rotation_degrees = 180.0
		else:
			flashlight.rotation_degrees = 0.0
	
	handle_animations(abs(velocity.x))
	move_and_slide()
	
	if abs(global_position.x - target_position.x) < 50.0:
		velocity.x = 0
		
		if current_state == State.INVESTIGATING:
			current_state = State.SEARCHING
			state_timer.start(TIME_PER_STATE)
		elif current_state == State.RETURNING:
			current_state = State.IDLE_2
			state_timer.start(TIME_PER_STATE)

func _check_for_player_sound() -> void:
	if not player:
		return
		
	var distance_to_player: float = global_position.distance_to(player.global_position)
	var player_sound_level = player.sound
	
	if distance_to_player <= hearing_range and player_sound_level > 5 and not player.is_hidden:
		heard_alert.visible = true
		target_position = player.global_position
		current_state = State.INVESTIGATING
		state_timer.stop()
	else:
		heard_alert.visible = false

func _check_for_player_in_eyesight() -> void:
	if not player or player.is_hidden:
		return
		
	var distance_to_player: float = global_position.distance_to(player.global_position)
	
	if distance_to_player <= closest_range:
		print("---")
		print("game over...")

func _check_for_player_in_flashlight_range() -> void:
	if not player or player.is_hidden:
		return
	
	var distance_to_player: float = global_position.distance_to(player.global_position)
	
	if is_player_in_light and flashlight.visible and distance_to_player <= flashlight_range:
		seen_alert.visible = true

func _check_for_player_under_street_light() -> void:
	is_player_in_light = player.is_in_light
	
	if not player or player.is_hidden:
		if not (is_player_in_light and flashlight.visible and not player.is_hidden):
			seen_alert.visible = false
		return
		
	var distance_to_player: float = global_position.distance_to(player.global_position)
	
	var is_facing_left: bool = animated_sprite.flip_h
	var player_is_left: bool = player.global_position.x < global_position.x
	
	var is_facing_player: bool = (is_facing_left == player_is_left)
	
	if distance_to_player <= street_light_range and is_player_in_light and is_facing_player:
		seen_alert.visible = true
		target_position = player.global_position
		current_state = State.INVESTIGATING
		state_timer.stop()
	else:
		if not (is_player_in_light and flashlight.visible):
			seen_alert.visible = false

func _on_timer_timeout() -> void:
	match current_state:
		State.WALK_LEFT: current_state = State.IDLE_1
		State.IDLE_1: current_state = State.WALK_RIGHT
		State.WALK_RIGHT: current_state = State.IDLE_2
		State.IDLE_2: current_state = State.WALK_LEFT
		State.SEARCHING:
			heard_alert.visible = false
			target_position = starting_position
			current_state = State.RETURNING
			state_timer.stop()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		is_player_in_light = true
		player_entered_light.emit()

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Player:
		is_player_in_light = false
		player_left_light.emit()
