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
	var settings_scene = preload("res://scenes/settings.tscn")
	var settings = settings_scene.instantiate()

	settings.opened_from_pause = true
	settings.process_mode = Node.PROCESS_MODE_ALWAYS
	
	get_tree().root.add_child(settings)

func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo():
		resume_requested.emit()
		get_viewport().set_input_as_handled()
