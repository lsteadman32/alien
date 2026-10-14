extends CanvasLayer


func _ready() -> void:
	$SettingsControl/VBoxContainer/FullScreenCheck.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


func _on_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0,value)


func _on_resolutions_item_selected(index: int) -> void:
	var screen := DisplayServer.screen_get_size()
	var win := DisplayServer.window_get_size()
	DisplayServer.window_set_position((screen - win) /2)
	match index:
		0:
			DisplayServer.window_set_size(Vector2i(600,600))
		1:
			DisplayServer.window_set_size(Vector2i(1280,720))
		2:
			DisplayServer.window_set_size(Vector2i(1366,768))
		3:
			DisplayServer.window_set_size(Vector2i(1600,900))
		4:
			DisplayServer.window_set_size(Vector2i(1920,1080))

func _on_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		


func _on_close_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
