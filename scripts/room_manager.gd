extends Node

const SHIP_CONNECTIONS := {
	"USCSS_Thessaly": [
		["CryoChamber", "JunctionA1"],
		["CryoChamber", "JunctionA5"],
		["JunctionA1", "MessHall"],
		["JunctionA5", "ChangingRoom"],
		["ChangingRoom", "JunctionA3"],
		["JunctionA3", "ComputerRoom"],
		["ComputerRoom", "Bridge"],
		["Bridge", "JunctionA2"],
		["JunctionA2", "JunctionA3"],
		["JunctionA2", "JunctionA4"],
		["JunctionA4", "MedBay"],
		["MessHall", "JunctionA2"],
		["MessHall", "ThessalyAirlock"],
		["ThessalyAirlock", "JunctionA4"]
	],

	"USCSS_Kinship": [
		# Second ship connections will go here.
	]
}

const DOCKING_CONNECTIONS := [
	["USCSS_Thessaly/ThessalyAirlock", "USCSS_Thessaly/Umbilical"],
	["USCSS_Thessaly/Umbilical", "USCSS_Kinship/KinshipAirlock"]
]

func _ready() -> void:
	# Build connections within each ship.
	for ship_name in SHIP_CONNECTIONS:
		var ship_node := get_node_or_null(NodePath(ship_name))

		if ship_node == null:
			push_error("RoomManager: Ship node not found: " + ship_name)
			continue

		for connection in SHIP_CONNECTIONS[ship_name]:
			var room_a := ship_node.get_node_or_null(
				NodePath(connection[0])
			) as GameRoom

			var room_b := ship_node.get_node_or_null(
				NodePath(connection[1])
			) as GameRoom

			if room_a == null or room_b == null:
				push_error("RoomManager: Invalid connection on " + ship_name)
				continue

			connect_rooms(room_a, room_b)

	# Build docking connections.
	for connection in DOCKING_CONNECTIONS:
		var room_a := get_node_or_null(
			NodePath(connection[0])
		) as GameRoom

		var room_b := get_node_or_null(
			NodePath(connection[1])
		) as GameRoom

		if room_a == null or room_b == null:
			push_error("RoomManager: Invalid docking connection.")
			continue

		connect_rooms(room_a, room_b)

	# Hidden room connections.
	connect_rooms(
		$USCSS_Thessaly/MedVent,
		$USCSS_Thessaly/MedBay
	)

	connect_rooms(
		$USCSS_Thessaly/MedVent,
		$USCSS_Thessaly/Bridge
	)

	# Door locks.
	lock_exit(
		$USCSS_Thessaly/ThessalyAirlock,
		$USCSS_Thessaly/Umbilical,
		"credentials"
	)

func connect_rooms(a: GameRoom, b: GameRoom) -> void:
	a.exits[b.room_name.to_lower()] = a.get_path_to(b)
	b.exits[a.room_name.to_lower()] = b.get_path_to(a)

func lock_exit(a: GameRoom, b: GameRoom, key_id) -> void:
	a.locked_exits[b.room_name.to_lower()] = key_id
	b.locked_exits[b.room_name.to_lower()] = key_id

func hide_exit(a: GameRoom, b: GameRoom) -> void:
	a.hidden_exits.append(b.room_name.to_lower())

func get_rooms_on_deck(deck: int, ship_id: String) -> Array[GameRoom]:
	var result: Array[GameRoom] = []	
	var rooms: Array = find_children("*", "GameRoom", true, false)
	
	for room in rooms:
		var belongs_to_ship: bool = room.ship_id == ship_id
		var is_docking_umbilical: bool = (
			room.ship_id == "docking_umbilical"
			and ship_id in ["thessaly", "kinship"]
		)
	
		if room.deck_number == deck and (belongs_to_ship or is_docking_umbilical):
			result.append(room)
	
	return result

func get_available_decks(ship_id: String) -> Array[int]:
	var decks: Array[int] = []
	var rooms: Array = find_children("*", "GameRoom", true, false)
	
	for room in rooms:
		if room.ship_id != ship_id:
			continue
		
		if room.room_name.strip_edges() == "" or room.room_name == "Name":
			continue
		
		if room.deck_number < 1:
			continue
		
		if not decks.has(room.deck_number):
			decks.append(room.deck_number)
		
	decks.sort()
	return decks
