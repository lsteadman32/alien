extends Control

@onready var glow = $TerminalEffects/Glow

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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
	pass


func _on_load_pressed() -> void:
	pass

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
