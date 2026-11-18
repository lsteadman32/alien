extends Node

var crt_enabled: bool = true

const CONFIG_PATH = "user://settings.cfg"

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	var config := ConfigFile.new()
	var error := config.load(CONFIG_PATH)
	
	if error == OK:
		crt_enabled = config.get_value("display", "crt_enabled", true)

func set_crt_enabled(enabled: bool) -> void:
	crt_enabled = enabled
	
	var config := ConfigFile.new()
	config.set_value("display", "crt_enabled", crt_enabled)
	config.save(CONFIG_PATH)
