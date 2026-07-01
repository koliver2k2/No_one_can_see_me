extends Label

@onready var ui = $"."

func _process(_delta) -> void:
	ui.text = "Collectibles: " + str(PlayerStats.collectibles)
