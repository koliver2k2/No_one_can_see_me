extends Node2D

signal player_entered_hide
signal player_left_hide

@onready var sprite: Sprite2D = $Sprite2D

func set_transparency(alpha_value: float) -> void:
	# alpha_value should be between 0.0 (invisible) and 1.0 (fully opaque)
	
	sprite.modulate.a = alpha_value

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		set_transparency(0.4)
		player_entered_hide.emit()


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Player:
		set_transparency(1.0)
		player_left_hide.emit()
