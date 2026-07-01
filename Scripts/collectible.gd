extends Node2D

@onready var animator = $AnimatedSprite2D
@onready var collision = $Area2D/CollisionShape2D

func _ready() -> void:
	animator.play("idle")

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		PlayerStats.collectibles += 1
		animator.visible = false
		collision.disabled = true
