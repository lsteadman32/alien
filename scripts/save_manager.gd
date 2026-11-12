extends Node

const SAVE_PATH := "user://alien_save.json"
var load_on_next_scene := false

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game(game: Node) -> bool:
	var command_processor = game.command_processor
	var room_manager = game.room_manager
	var creature: Xenomorph = game.xenomorph

	var room_data := {}

	# Record the changing state of every room.
	var rooms: Array = room_manager.find_children("*", "GameRoom", true, false)

	for room in rooms:
		room_data[room.room_name] = {
			"items": room.items,
			"hidden_items": room.hidden_items,
			"hidden_exits": room.hidden_exits,
			"locked_exits": room.locked_exits,
			"secured_exits": room.secured_exits,
			"visited": room.visited
		}

	# Record the Xenomorph's AI state.
	var creature_data := {
		"current_state": creature.current_state,
		"previous_state": creature.previous_state,
		"awareness": creature.awareness,
		"turns_in_state": creature.turns_in_state,
		"turns_since_visual": creature.turns_since_visual,
		"player_visible": creature.player_visible,
		"has_reached_investigation_site": creature.has_reached_investigation_site,
		"current_room": _room_name(creature.current_room),
		"previous_room": _room_name(creature.previous_room),
		"last_known_player_room": _room_name(creature.last_known_player_room),
		"starting_room": _room_name(creature.starting_room)
	}

	# Assemble the complete save.
	var save_data := {
		"player_name": command_processor.player_name,
		"current_room": _room_name(command_processor.current_room),
		"previous_room": _room_name(command_processor.previous_room),
		"inventory": command_processor.inventory,
		"pda_notes": command_processor.pda_notes,
		"rooms": room_data,
		"xenomorph": creature_data
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file == null:
		push_error("SaveManager: Could not open save file.")
		return false

	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()

	print("SaveManager: Game saved successfully.")
	return true


func load_game(game: Node) -> bool:
	if not has_save():
		push_warning("SaveManager: No save file found.")
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)

	if file == null:
		push_error("SaveManager: Could not open save file.")
		return false

	var save_data = JSON.parse_string(file.get_as_text())
	file.close()

	if not save_data is Dictionary:
		push_error("SaveManager: Save file is invalid.")
		return false

	var command_processor = game.command_processor
	var room_manager = game.room_manager
	var creature: Xenomorph = game.xenomorph

	# Find the saved player location before changing anything.
	var loaded_room: GameRoom = _find_room(
		room_manager,
		save_data.get("current_room", "")
	)

	if loaded_room == null:
		push_error("SaveManager: Saved player room could not be found.")
		return false

	# Restore player information.
	command_processor.player_name = save_data.get("player_name", "")
	command_processor.inventory.clear()

	for item in save_data.get("inventory", []):
		command_processor.inventory.append(str(item))

	command_processor.pda_notes.clear()

	for note in save_data.get("pda_notes", []):
		command_processor.pda_notes.append(str(note))

	command_processor.current_room = loaded_room
	command_processor.previous_room = _find_room(
		room_manager,
		save_data.get("previous_room", "")
	)

	# Reset any active interfaces or pending input.
	command_processor.awaiting_name = false
	command_processor.active_pda = false
	command_processor.active_terminal = null
	command_processor.awaiting_password = false
	command_processor.pending_terminal = null

	# Restore room states.
	var saved_rooms: Dictionary = save_data.get("rooms", {})

	for room_name in saved_rooms.keys():
		var room: GameRoom = _find_room(room_manager, room_name)

		if room == null:
			continue

		var data: Dictionary = saved_rooms[room_name]

		room.items.assign(data.get("items", []))
		room.hidden_items.assign(data.get("hidden_items", []))
		room.hidden_exits.assign(data.get("hidden_exits", []))
		room.locked_exits = data.get("locked_exits", {})
		room.secured_exits.assign(data.get("secured_exits", []))
		room.visited = data.get("visited", false)

	# Restore Xenomorph state without awakening it.
	var creature_data: Dictionary = save_data.get("xenomorph", {})

	creature.current_state = int(creature_data.get("current_state", Xenomorph.State.DORMANT)) as Xenomorph.State
	creature.previous_state = int(creature_data.get("previous_state", Xenomorph.State.DORMANT)) as Xenomorph.State
	creature.awareness = int(creature_data.get("awareness", 0))
	creature.turns_in_state = int(creature_data.get("turns_in_state", 0))
	creature.turns_since_visual = int(creature_data.get("turns_since_visual", 0))
	creature.player_visible = creature_data.get("player_visible", false)
	creature.has_reached_investigation_site = creature_data.get("has_reached_investigation_site", false)

	creature.current_room = _find_room(room_manager, creature_data.get("current_room", ""))
	creature.previous_room = _find_room(room_manager, creature_data.get("previous_room", ""))
	creature.last_known_player_room = _find_room(room_manager, creature_data.get("last_known_player_room", ""))
	creature.starting_room = _find_room(room_manager, creature_data.get("starting_room", ""))
	creature.player_room = loaded_room

	print("SaveManager: Game loaded successfully.")
	return true


func _room_name(room: GameRoom) -> String:
	if room == null:
		return ""
	return room.room_name


func _find_room(room_manager: Node, target_name: String) -> GameRoom:
	if target_name == "":
		return null

	var rooms: Array = room_manager.find_children("*", "GameRoom", true, false)

	for room in rooms:
		if room.room_name == target_name:
			return room

	return null
