extends Control

signal resume_requested

func _on_resume_pressed() -> void:
	print("resume")
	resume_requested.emit()


func _on_save_pressed() -> void:
	pass # Replace with function body.


func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/settings.tscn")


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
