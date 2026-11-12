
extends Control

var room_manager: Node
var current_room: GameRoom
var selected_deck: int = 1
var available_decks: Array[int] = []
var deck_label: Label
var previous_button: Button
var next_button: Button

const MAP_MARGIN := 60.0
const MAP_HEADER_HEIGHT := 90.0
const ROOM_RADIUS := 9.0

const COLOR_BACKGROUND := Color(0.02, 0.06, 0.05, 0.96)
const COLOR_CONNECTION := Color(0.2, 0.55, 0.42, 0.7)
const COLOR_ROOM := Color(0.4, 0.75, 0.6, 1.0)
const COLOR_CURRENT := Color(0.7, 1.0, 0.75, 1.0)
const COLOR_TEXT := Color(0.65, 0.85, 0.75, 1.0)
const COLOR_UNVISITED := Color(0.22, 0.38, 0.32, 0.75)

func _ready() -> void:
	var header := HBoxContainer.new()
	header.anchor_left = 0.5
	header.anchor_right = 0.5
	header.anchor_top = 0.0
	header.anchor_bottom = 0.0
	header.offset_left = -115
	header.offset_right = 115
	header.offset_top = 20
	header.offset_bottom = 60
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 12)
	add_child(header)

	previous_button = Button.new()
	previous_button.text = "<"
	previous_button.custom_minimum_size = Vector2(42, 36)
	previous_button.focus_mode = Control.FOCUS_NONE
	previous_button.pressed.connect(_previous_deck)
	header.add_child(previous_button)

	deck_label = Label.new()
	deck_label.text = "DECK 01"
	deck_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deck_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	deck_label.custom_minimum_size = Vector2(100, 36)
	header.add_child(deck_label)

	next_button = Button.new()
	next_button.text = ">"
	next_button.custom_minimum_size = Vector2(42, 36)
	next_button.focus_mode = Control.FOCUS_NONE
	next_button.pressed.connect(_next_deck)
	header.add_child(next_button)

func _refresh_available_decks() -> void:
	available_decks = room_manager.get_available_decks()

	if available_decks.is_empty():
		available_decks.append(1)

	if not available_decks.has(selected_deck):
		selected_deck = available_decks[0]

	_update_deck_selector()


func _update_deck_selector() -> void:
	if deck_label == null:
		return

	var deck_index := available_decks.find(selected_deck)

	deck_label.text = "DECK %02d" % selected_deck
	previous_button.disabled = deck_index <= 0
	next_button.disabled = deck_index >= available_decks.size() - 1


func _previous_deck() -> void:
	var deck_index := available_decks.find(selected_deck)

	if deck_index > 0:
		set_deck(available_decks[deck_index - 1])


func _next_deck() -> void:
	var deck_index := available_decks.find(selected_deck)

	if deck_index < available_decks.size() - 1:
		set_deck(available_decks[deck_index + 1])

func setup(manager: Node) -> void:
	room_manager = manager
	_refresh_available_decks()
	queue_redraw()


func set_current_room(room: GameRoom) -> void:
	current_room = room
	
	if available_decks.has(room.deck_number):
		selected_deck = room.deck_number
	
	_update_deck_selector()
	queue_redraw()


func set_deck(deck: int) -> void:
	if not available_decks.has(deck):
		return
	
	selected_deck = deck
	_update_deck_selector()
	queue_redraw()


func _draw() -> void:
	if room_manager == null:
		return

	draw_rect(Rect2(Vector2.ZERO, size), COLOR_BACKGROUND, true)

	var discovered_rooms: Array[GameRoom] = []

	# First, collect rooms the player has actually visited.
	for room in room_manager.get_rooms_on_deck(selected_deck):
		if room.room_name.strip_edges() == "" or room.room_name == "Name":
			continue
		if room.visited or room == current_room:
			discovered_rooms.append(room)

# Start the visible map with discovered rooms.
	var visible_rooms: Array[GameRoom] = discovered_rooms.duplicate()

# Add only the immediate connections of discovered rooms.
	for room in discovered_rooms:
		for exit_name in room.exits.keys():
			if room.hidden_exits.has(exit_name):
				continue

			var connected_room: GameRoom = room.get_exit(exit_name)

			if connected_room == null:
				continue

			if connected_room.deck_number != selected_deck:
				continue

			if connected_room.room_name.strip_edges() == "" or connected_room.room_name == "Name":
				continue

			if not visible_rooms.has(connected_room):
				visible_rooms.append(connected_room)

	if visible_rooms.is_empty():
		draw_string(
			ThemeDB.fallback_font,
			Vector2(30, 50),
			"NO DISCOVERED LOCATIONS",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			16,
			COLOR_TEXT
		)
		return

	# Determine the spatial bounds of discovered rooms.
	var min_position := Vector2(INF, INF)
	var max_position := Vector2(-INF, -INF)
	var room_centers: Dictionary = {}

	for room in visible_rooms:
		var center := room.global_position + room.size / 2.0
		room_centers[room] = center

		min_position.x = min(min_position.x, center.x)
		min_position.y = min(min_position.y, center.y)
		max_position.x = max(max_position.x, center.x)
		max_position.y = max(max_position.y, center.y)

	var available_size := size - Vector2(
		MAP_MARGIN * 2.0,
		MAP_HEADER_HEIGHT + MAP_MARGIN
	)
	var layout_size := max_position - min_position

	if layout_size.x < 1.0:
		layout_size.x = 1.0
	if layout_size.y < 1.0:
		layout_size.y = 1.0

	var scale_factor: float = minf(
		available_size.x / layout_size.x,
		available_size.y / layout_size.y
	)

	scale_factor = min(scale_factor, 1.0)

	var map_size := layout_size * scale_factor
	var available_origin := Vector2(MAP_MARGIN, MAP_HEADER_HEIGHT)
	var map_offset := available_origin + (available_size - map_size) / 2.0

	var draw_positions: Dictionary = {}

	for room in visible_rooms:
		var source_position: Vector2 = room_centers[room]
		var map_position := (source_position - min_position) * scale_factor
		draw_positions[room] = map_offset + map_position

	# Draw connections between discovered rooms.
	for room in visible_rooms:
		var start_position: Vector2 = draw_positions[room]

		for exit_name in room.exits.keys():
			if room.hidden_exits.has(exit_name):
				continue

			var connected_room := room.get_exit(exit_name)

			if connected_room == null:
				continue

			if not draw_positions.has(connected_room):
				continue

			var end_position: Vector2 = draw_positions[connected_room]

			draw_line(
				start_position,
				end_position,
				COLOR_CONNECTION,
				2.0
			)

	# Draw room markers and labels.
	for room in visible_rooms:
		var position: Vector2 = draw_positions[room]
		var is_current := room == current_room

		var marker_color := COLOR_ROOM
		
		if is_current:
			marker_color = COLOR_CURRENT
		elif not room.visited:
			marker_color = COLOR_UNVISITED
		
		var marker_radius := ROOM_RADIUS * 1.5 if is_current else ROOM_RADIUS

		draw_circle(position, marker_radius, marker_color)

		var label_position := position + Vector2(14, 5)
		var label_size := ThemeDB.fallback_font.get_string_size(
			room.room_name.to_upper(),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			14
		)

		var label_rect := Rect2(
			label_position + Vector2(-3, -14),
			label_size + Vector2(6, 6)
	)

		draw_rect(label_rect, COLOR_BACKGROUND, true)

		draw_string(
			ThemeDB.fallback_font,
			label_position,
			room.room_name.to_upper(),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			14,
			COLOR_TEXT
		)
