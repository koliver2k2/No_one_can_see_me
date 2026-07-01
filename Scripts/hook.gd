extends Node2D

@onready var notification = $Notification

signal player_hooks_themselves

var player: Node2D = null
var hook_distance: float = 1000.0

var player_attached: bool = false
var is_pulling: bool = false
var is_climbing: bool = false

var pull_tween: Tween
var climb_tween: Tween
@export var pull_duration: float = 0.25
@export var climb_trapdoor_duration: float = 1.0

func _ready() -> void:
	call_deferred("_find_player")
	notification.visible = false

func _process(_delta: float) -> void:
	_check_if_player_is_near()
	_handle_hook_input()
	_hold_player_if_hooked()

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	else:
		push_warning("Hook couldn't find a player node in the 'player' group!")

func _check_if_player_is_near() -> void:
	if not player:
		return
		
	var distance_to_player: float = global_position.distance_to(player.global_position)
	
	if distance_to_player <= hook_distance and not player_attached and not is_pulling:
		notification.visible = true
	elif player.global_position.y < global_position.y:
		notification.visible = false
	else:
		notification.visible = false

func _handle_hook_input() -> void:
	if not player:
		return
		
	if Input.is_action_just_pressed("interact"):
		if player.used_interaction or player.global_position.y < global_position.y:
			return
		if player_attached or is_pulling:
			_unhook_player()
		elif global_position.distance_to(player.global_position) <= hook_distance:
			player_hooks_themselves.emit()
			_start_hooking_player()
	
	if Input.is_action_just_pressed("ui_accept") and player_attached:
		player.is_climbing_trapdoor = true
		_climb_horizontal_trapdoor()

func _start_hooking_player() -> void:
	is_pulling = true
	
	player.velocity = Vector2.ZERO 
	
	if pull_tween:
		pull_tween.kill()
		
	pull_tween = create_tween()
	pull_tween.tween_property(player, "global_position", Vector2(global_position.x, global_position.y + 200), pull_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	pull_tween.tween_callback(_on_player_reached_hook)

func _on_player_reached_hook() -> void:
	is_pulling = false
	player_attached = true
	
func _on_player_climbed_trapdoor() -> void:
	is_climbing = false
	player_attached = true

func _unhook_player() -> void:
	player_attached = false
	is_climbing = false
	is_pulling = false
	player.global_position = Vector2(global_position.x, global_position.y - 200)
	
	if pull_tween:
		pull_tween.kill()
		
func _end_climbing_trapdoor() -> void:
	player_attached = false
	is_climbing = false
	player.global_position = Vector2(global_position.x, global_position.y - 250)
	
	if player:
		player.is_climbing_trapdoor = false
	
	if climb_tween:
		climb_tween.kill()

func _climb_horizontal_trapdoor():
	player_attached = false
	is_climbing = true
	
	player.velocity = Vector2.ZERO
	
	if climb_tween:
		climb_tween.kill()
		
	climb_tween = create_tween()
	climb_tween.tween_property(player, "global_position", Vector2(global_position.x, global_position.y - 250), climb_trapdoor_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	climb_tween.tween_callback(_on_player_climbed_trapdoor)
	climb_tween.finished.connect(_end_climbing_trapdoor)

func _hold_player_if_hooked() -> void:
	if player_attached:
		player.global_position = global_position
		player.global_position.y = global_position.y + 200
