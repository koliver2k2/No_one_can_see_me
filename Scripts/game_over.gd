extends Node2D

func _on_play_again_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://main_scene.tscn")


func _on_main_menu_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://Presets/menu.tscn")
