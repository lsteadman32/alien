extends Control

@onready var glow = $TerminalEffects/Glow

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var has_saved_game: bool = SaveManager.has_save()
	$VBoxContainer/Continue.disabled = not has_saved_game
	$VBoxContainer/Load.disabled = not has_saved_game
	glow.pivot_offset = glow.size / 2
	glow.modulate.a = 0.3
	var tween := create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel(true)
	tween.tween_property(glow, "modulate:a", 0.6, 2.0)
	tween.tween_property(glow, "scale", Vector2(1.05, 1.05), 2.0)
	tween.chain().tween_property(glow, "modulate:a", 0.3, 2.0)
	tween.tween_property(glow, "scale", Vector2.ONE, 2.0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")



func _on_continue_pressed() -> void:
	await _load_saved_game()


func _on_load_pressed() -> void:
	await _load_saved_game()

func _load_saved_game() -> void:
	if not SaveManager.has_save():
		print("No save file found.")
		return
	
	var tree = get_tree()
	
	var result: Error = get_tree().change_scene_to_file(
		"res://scenes/main.tscn"
		)
	
	if result != OK:
		push_error("Could not open game scene.")
		return
	
	await tree.scene_changed
	
	var game = tree.current_scene
	
	if game and game.has_method("load_game"):
		if game.load_game():
			print("Saved game restored successfully.")
		else:
			print("Failed to restore saved game.")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
