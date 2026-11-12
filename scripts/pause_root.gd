extends Control

signal resume_requested

func _on_resume_pressed() -> void:
	print("resume")
	resume_requested.emit()


func _on_save_pressed() -> void:
	var game = get_tree().current_scene
	
	if game and game.has_method("save_game"):
		if game.save_game():
			print("Game saved.")
			await game.resume_game_input()
		else:
			print("Save failed.")

func _on_load_pressed() -> void:
	var game = get_tree().current_scene
	
	if game and game.has_method("load_game"):
		if game.load_game():
			print("Game loaded.")
			await game.resume_game_input()
		else:
			print("Load failed.")


func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/settings.tscn")


func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
