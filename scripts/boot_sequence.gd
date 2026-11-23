extends Control


@onready var boot_video: VideoStreamPlayer = $BootVideo

var transitioning := false

func _ready() -> void:
	boot_video.play()
	await boot_video.finished
	enter_game()

func _unhandled_key_input(event: InputEvent) -> void:
	if transitioning:
		return
	
	if event is InputEventKey and event.pressed and not event.echo:
		enter_game()

func enter_game() -> void:
	if transitioning:
		return
	
	transitioning = true
	boot_video.stop()
	var result = get_tree().change_scene_to_file("res://scenes/main.tscn")
	
	if result != OK:
		transitioning = false
		push_error("Failed to load game scene.")
