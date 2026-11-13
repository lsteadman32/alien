extends Control


const InputResponse = preload("res://scenes/input_response.tscn")
const Response = preload("res://scenes/response.tscn")



@export var max_lines_remembered := 30

@onready var glow = $Settings/SettingsControl/Glow
@onready var history_rows = $TextEditorGUI/GUI/MarginContainer/Rows/GameInfo/Scroll/HistoryRows
@onready var scroll = $TextEditorGUI/GUI/MarginContainer/Rows/GameInfo/Scroll
@onready var command_processor: Node = $CommandProcessor
@onready var room_manager = $RoomManager
@onready var pause_menu = $PauseLayer
@onready var xenomorph: Xenomorph = $Xenomorph
@onready var map_display = $MapLayer/MapDisplay
@onready var smoke_particles: GPUParticles2D = $EnvironmentEffectsLayer/EffectsOverlay/SmokeParticles


var pending_xenomorph_events: Array[String] = []
var waiting_for_xenomorph_event := false
var paused = false

func _ready() -> void:
	handle_response_generated("")
	$PauseLayer/PauseRoot.resume_requested.connect(resume_game_input)
	
	scroll.get_v_scroll_bar().changed.connect(_scroll_to_bottom)

	
	## glow effect
	glow.pivot_offset = glow.size / 2.0
	glow.modulate.a = 0.3
	var tween := create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel(true)
	tween.tween_property(glow, "modulate:a", 0.6, 4.0)
	tween.tween_property(glow, "scale", Vector2(2.05, 2.05), 10.0)
	tween.chain().tween_property(glow, "modulate:a", 0.3, 2.0)
	tween.tween_property(glow, "scale", Vector2.ONE, 2.0)


	command_processor.response_generated.connect(handle_response_generated)
	
	command_processor.player_moved.connect(xenomorph.on_player_moved)
	command_processor.player_made_noise.connect(xenomorph.report_noise)
	command_processor.player_moved.connect(_on_player_moved)
	xenomorph.xenomorph_event.connect(_on_xenomorph_event)
	
	var starting_room: GameRoom = room_manager.get_node("CryoChamber")
	smoke_particles.emitting = starting_room.smoke_enabled
	
	var loading_saved_game: bool = SaveManager.load_on_next_scene
	
	command_processor.initialize(starting_room, not loading_saved_game)
	xenomorph.initialize(starting_room)
	
	map_display.setup(room_manager)
	map_display.set_current_room((command_processor.current_room))
	
	if SaveManager.load_on_next_scene:
		SaveManager.load_on_next_scene = false
		call_deferred("_load_pending_save")
	
	#xenomorph.debug_pathfinding(
	#	room_manager.get_node("CryoChamber") as GameRoom
	#)

func _load_pending_save() -> void:
	if load_game():
		map_display.set_current_room(command_processor.current_room)
		print("Game: Saved game restored successfully.")
		print("Restored room: ", command_processor.current_room.room_name)
		print("Restored inventory: ", command_processor.inventory)
		print("Restored player: ", command_processor.player_name)
	else:
		push_error("Game: Failed to restore saved game.")

func _on_xenomorph_event(message: String) -> void:
	pending_xenomorph_events.append(message)

func display_next_xenomorph_event() -> void:
	if pending_xenomorph_events.is_empty():
		return
	
	waiting_for_xenomorph_event = true
	
	var message: String = pending_xenomorph_events.pop_front()
	
	handle_response_generated(message)

func _process(_delta):
	if Input.is_action_just_pressed("pause"):
		if map_display.visible:
			_close_map()
			return
		pauseMenu()

func _close_map() -> void:
	map_display.hide()
	
	await get_tree().process_frame
	
	var input_field: LineEdit = $TextEditorGUI/GUI/MarginContainer/Rows/InputArea/HBoxContainer/Input
	
	get_viewport().gui_release_focus()
	
	input_field.editable = true
	input_field.grab_focus()
	input_field.call_deferred("grab_focus")
	print("Focus owner: ", get_viewport().gui_get_focus_owner())

func pauseMenu():
	if paused:
		resume_game_input()
	else:
		pause_menu.show()
		get_tree().paused = true
		paused = true
	

func resume_game_input() -> void:
	pause_menu.hide()
	paused = false
	get_tree().paused = false
	
	await get_tree().process_frame
	
	var input_field: LineEdit = $TextEditorGUI/GUI/MarginContainer/Rows/InputArea/HBoxContainer/Input
	get_viewport().gui_release_focus()
	input_field.editable = true
	input_field.grab_focus()
	input_field.call_deferred("grab_focus")

func _on_input_text_submitted(_new_text: String) -> void:
	get_tree().call_group("typewriter", "skip")
	
	if _new_text.is_empty():
		return
	
	var player_turn_started: bool = not command_processor.awaiting_name
	var is_map_command: bool = _new_text.strip_edges().to_lower() == "map"
	
	var input_response = InputResponse.instantiate()
	var masked: bool =  command_processor.awaiting_password
	var response = command_processor.process_command(_new_text)
	var response_label = input_response.get_node("Response")
	
	if response_label.has_signal("typing_finished"):
		response_label.typing_finished.connect(
			display_next_xenomorph_event
		)
	
	if is_map_command:
		response_label.typing_finished.connect(_open_map)
	
	input_response.set_text("*".repeat(_new_text.length()) if masked else _new_text, response)

	if command_processor.active_terminal != null:
		var label = input_response.get_node("Response")
		label.add_theme_color_override("font_color", command_processor.active_terminal.text_color)
	add_response_to_game(input_response)
	
	if player_turn_started and not is_map_command:
		xenomorph.advance_turn()
		

func handle_response_generated(response_text: String):
	var response = Response.instantiate()
	response.text = response_text
	add_response_to_game(response)

func _scroll_to_bottom() -> void:
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)

func add_response_to_game(response: Control):
	history_rows.add_child(response)
	await get_tree().process_frame
	await get_tree().process_frame
	_scroll_to_bottom()
	delete_history_beyond_limit()

func delete_history_beyond_limit():
	if history_rows.get_child_count() > max_lines_remembered:
		var rows_to_forget = history_rows.get_child_count() - max_lines_remembered
		for i in range(rows_to_forget):
			history_rows.get_child(i).queue_free()

func save_game() -> bool:
	return SaveManager.save_game(self)

func load_game() -> bool:
	return SaveManager.load_game(self)

func _toggle_map() -> void:
	map_display.visible = not map_display.visible
	map_display.set_current_room(command_processor.current_room)

func _on_player_moved(_previous_room: GameRoom, new_room: GameRoom) -> void:
	map_display.set_current_room(new_room)
	smoke_particles.emitting = new_room.smoke_enabled

func _open_map() -> void:
	map_display.show()
	map_display.set_current_room(command_processor.current_room)
