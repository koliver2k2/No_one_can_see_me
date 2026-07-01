extends Node2D

signal player_close_to_trapdoor
signal player_not_close_to_trapdoor

var player: Node2D = null
var distance_to_player: float
var crouch_player: float = 420.0
var counter: int = 1

func _ready() -> void:
	call_deferred("_find_player")

func _process(delta):
	distance_to_player = global_position.distance_to(player.global_position)
	_handle_player_crouch()

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	else:
		push_warning("trapdoor couldn't find a player node in the 'player' group!")

func _handle_player_crouch() -> void:
	if distance_to_player <= crouch_player:
		player_close_to_trapdoor.emit()
	else:
		player_not_close_to_trapdoor.emit()
