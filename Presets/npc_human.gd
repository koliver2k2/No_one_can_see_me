extends CharacterBody2D
class_name NPC_Human

const WALK_SPEED := 180
const TIME_PER_STATE: float = 2.0

@onready var animated_sprite = $AnimatedSprite2D

@export var hearing_range: float = 400.0 
var player: Node2D = null

enum State { WALK_LEFT, IDLE_1, WALK_RIGHT, IDLE_2 }
var current_state: State = State.IDLE_2

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

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	else:
		push_warning("NPC couldn't find a player node in the 'player' group!")

func _physics_process(_delta: float) -> void:
	_handle_patrol_movement()
	_check_for_player_sound()

func _handle_patrol_movement() -> void:
	match current_state:
		State.WALK_LEFT:
			velocity.x = -WALK_SPEED
			$AnimatedSprite2D.flip_h = true
			handle_animations(velocity.x)
		State.WALK_RIGHT:
			velocity.x = WALK_SPEED
			$AnimatedSprite2D.flip_h = false
			handle_animations(velocity.x)
		State.IDLE_1, State.IDLE_2:
			velocity.x = 0
			handle_animations(velocity.x)
	move_and_slide()

func _check_for_player_sound() -> void:
	if not player:
		return
		
	var distance_to_player: float = global_position.distance_to(player.global_position)
	
	if distance_to_player <= hearing_range:
		var player_sound_level = player.sound
		
		if player_sound_level > 5:
			print("Player detected! Heard sound level: ", player_sound_level)

func _on_timer_timeout() -> void:
	match current_state:
		State.WALK_LEFT: current_state = State.IDLE_1
		State.IDLE_1: current_state = State.WALK_RIGHT
		State.WALK_RIGHT: current_state = State.IDLE_2
		State.IDLE_2: current_state = State.WALK_LEFT
