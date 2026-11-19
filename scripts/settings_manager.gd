extends Node

var fullscreen_enabled: bool = true
var crt_enabled: bool = true
var keyboard_clicks_enabled: bool = true
var print_sounds_enabled:bool = true

const CONFIG_PATH = "user://settings.cfg"

func _ready() -> void:
	load_settings()
	apply_fullscreen_setting()

func load_settings() -> void:
	var config := ConfigFile.new()
	var error := config.load(CONFIG_PATH)
	
	if error == OK:
		crt_enabled = config.get_value("display", "crt_enabled", true)
		keyboard_clicks_enabled = config.get_value("audio", "keyboard_clicks_enabled", true)
		print_sounds_enabled = config.get_value("audio", "print_sounds_enabled", true)

func apply_fullscreen_setting() -> void:
	if fullscreen_enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func set_fullscreen_enabled(enabled: bool) -> void:
	fullscreen_enabled = enabled
	apply_fullscreen_setting()
	save_settings()

func set_crt_enabled(enabled: bool) -> void:
	crt_enabled = enabled
	save_settings()

func set_keyboard_clicks_enabled(enabled: bool) -> void:
	keyboard_clicks_enabled = enabled
	save_settings()

func set_print_sounds_enabled(enabled: bool) -> void:
	print_sounds_enabled = enabled
	save_settings()

func save_settings() -> void:
	var config := ConfigFile.new()
	
	config.set_value("display", "crt_enabled", crt_enabled)
	config.set_value("audio", "keyboard_clicks_enabled", keyboard_clicks_enabled)
	config.set_value("audio", "print_sounds_enabled", print_sounds_enabled)
	config.set_value("display", "fullscreen_enabled", fullscreen_enabled)
	
	config.save(CONFIG_PATH)
