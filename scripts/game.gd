extends Control


const InputResponse = preload("res://scenes/input_response.tscn")
const Response = preload("res://scenes/response.tscn")



@export var max_lines_remembered := 30

@onready var glow = $Settings/SettingsControl/Glow
@onready var history_rows = $TextEditorGUI/GUI/MarginContainer/Rows/GameInfo/Scroll/HistoryRows
@onready var scroll = $TextEditorGUI/GUI/MarginContainer/Rows/GameInfo/Scroll
@onready var command_processor = $CommandProcessor
@onready var room_manager = $RoomManager
@onready var pause_menu = $PauseLayer


var paused = false

func _ready() -> void:
	handle_response_generated("")
	$PauseLayer/PauseRoot.resume_requested.connect(pauseMenu)
	

	
	## glow effect
	glow.pivot_offset = glow.size / 2
	glow.modulate.a = 0.3
	var tween := create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel(true)
	tween.tween_property(glow, "modulate:a", 0.6, 4.0)
	tween.tween_property(glow, "scale", Vector2(2.05, 2.05), 10.0)
	tween.chain().tween_property(glow, "modulate:a", 0.3, 2.0)
	tween.tween_property(glow, "scale", Vector2.ONE, 2.0)


	command_processor.response_generated.connect(handle_response_generated)
	command_processor.initialize(room_manager.get_child(0))

func _process(_delta):
	if Input.is_action_just_pressed("pause"):
		pauseMenu()

func pauseMenu():
	if paused:
		pause_menu.hide()
		get_tree().paused = false
	else:
		pause_menu.show()
		get_tree().paused = true
	
	paused = !paused

func _on_input_text_submitted(_new_text: String) -> void:
	if _new_text.is_empty():
		return
	
	var input_response = InputResponse.instantiate()
	var response = command_processor.process_command(_new_text)
	input_response.set_text(_new_text, response)
	add_response_to_game(input_response)

func handle_response_generated(response_text: String):
	var response = Response.instantiate()
	response.text = response_text
	add_response_to_game(response)



func add_response_to_game(response: Control):
	history_rows.add_child(response)
	await get_tree().process_frame
	scroll.ensure_control_visible(response)
	delete_history_beyond_limit()

func delete_history_beyond_limit():
	if history_rows.get_child_count() > max_lines_remembered:
		var rows_to_forget = history_rows.get_child_count() - max_lines_remembered
		for i in range(rows_to_forget):
			history_rows.get_child(i).queue_free()
