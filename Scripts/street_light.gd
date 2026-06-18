extends Node2D

signal player_entered_light
signal player_left_light

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		player_entered_light.emit()


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Player:
		player_left_light.emit()
