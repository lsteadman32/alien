extends CanvasLayer
@onready var glow = $SettingsControl/Glow

var opened_from_pause: bool = false

var bus_name : String


func _ready() -> void:
	$SettingsControl/VBoxContainer/FullScreenCheck.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	$SettingsControl/VBoxContainer/CRT_Enabled.button_pressed = SettingsManager.crt_enabled
	$SettingsControl/VBoxContainer/PrintSoundsCheck.button_pressed = SettingsManager.keyboard_clicks_enabled
	$SettingsControl/VBoxContainer/PrintSoundsCheck.button_pressed = SettingsManager.print_sounds_enabled
	
	glow.pivot_offset = glow.size / 2
	glow.modulate.a = 0.3
	var tween := create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel(true)
	tween.tween_property(glow, "modulate:a", 0.6, 4.0)
	tween.tween_property(glow, "scale", Vector2(2.05, 2.05), 10.0)
	tween.chain().tween_property(glow, "modulate:a", 0.3, 2.0)
	tween.tween_property(glow, "scale", Vector2.ONE, 2.0)
	
	var bus_index: int = AudioServer.get_bus_index("Master")
	var current_db: float = AudioServer.get_bus_volume_db(bus_index)
	$SettingsControl/VBoxContainer/Vol_Label/Volume.value = db_to_linear(current_db)


func _on_volume_value_changed(value: float) -> void:
	var bus_index: int = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))


func _on_resolutions_item_selected(index: int) -> void:
	var screen := DisplayServer.screen_get_size()
	var win := DisplayServer.window_get_size()
	DisplayServer.window_set_position((screen - win) /2.0)
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
		

func _on_crt_check_toggled(toggled_on: bool) -> void:
	SettingsManager.set_crt_enabled(toggled_on)
	
	var game := get_tree().current_scene
	if game and game.has_node("TextEditorGUI/GUI/ScanLines"):
		game.get_node("TextEditorGUI/GUI/ScanLines").visible = toggled_on

func _on_close_pressed() -> void:
	if opened_from_pause:
		queue_free()
	else: get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_print_sounds_toggled(toggled_on: bool) -> void:
	SettingsManager.set_print_sounds_enabled(toggled_on)


func _on_keyboard_clicks_toggled(toggled_on: bool) -> void:
	SettingsManager.set_keyboard_clicks_enabled(toggled_on)
