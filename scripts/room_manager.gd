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
		["KinshipAirlock", "EVAPrepRoom"],
		["EVAPrepRoom", "MedicalBay"],
		["EVAPrepRoom", "Security"],
		["MedicalBay", "FitnessCenter"],
		["MedicalBay", "MedStorage"],
		["FitnessCenter", "Laundry"],
		["Security", "SecurityStorage"],
		["Laundry", "CentralAtrium"],
		["FitnessCenter", "CentralAtrium"]
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
			var room_a := _find_ship_room(ship_name, connection[0])
			var room_b := _find_ship_room(ship_name, connection[1])

			if room_a == null or room_b == null:
				push_error("RoomManager: Invalid connection on " + ship_name)
				continue

			connect_rooms(room_a, room_b)

	# Build docking connections.
	for connection in DOCKING_CONNECTIONS:
		var room_a := _find_room_from_path(connection[0])
		var room_b := _find_room_from_path(connection[1])

		if room_a == null or room_b == null:
			push_error("RoomManager: Invalid docking connection.")
			continue

		connect_rooms(room_a, room_b)

	# Hidden room connections.
	var med_vent := _find_ship_room("USCSS_Thessaly", "MedVent")
	var med_bay := _find_ship_room("USCSS_Thessaly", "MedBay")
	var bridge := _find_ship_room("USCSS_Thessaly", "Bridge")

	if med_vent != null and med_bay != null:
		connect_rooms(med_vent, med_bay)

	if med_vent != null and bridge != null:
		connect_rooms(med_vent, bridge)

	# Ladder rooms.
	var junction_a3 := _find_ship_room("USCSS_Thessaly", "JunctionA3")
	var junction_b3 := _find_ship_room("USCSS_Thessaly", "JunctionB3")

	if junction_a3 != null and junction_b3 != null:
		connect_ladder(junction_a3, junction_b3)

	# Door locks.
	var airlock := _find_ship_room("USCSS_Thessaly", "ThessalyAirlock")
	var umbilical := _find_ship_room("USCSS_Thessaly", "Umbilical")
	var medical := _find_ship_room("USCSS_Kinship", "MedicalBay")
	var fitness := _find_ship_room("USCSS_Kinship", "FitnessCenter")
	var eva := _find_ship_room("USCSS_Kinship", "EVAPrepRoom")

	if airlock != null and umbilical != null:
		lock_exit(airlock, umbilical, "credentials")
	
	if medical != null and fitness != null and eva != null:
		lock_exit(medical, eva, "medical officer credentials")
		lock_exit(medical, fitness, "medical officer credentials")
	


func _find_ship_room(ship_name: String, room_node_name: String) -> GameRoom:
	var ship_node := get_node_or_null(NodePath(ship_name))

	if ship_node == null:
		push_error("RoomManager: Ship not found: " + ship_name)
		return null

	return ship_node.find_child(room_node_name, true, false) as GameRoom


func _find_room_from_path(path: String) -> GameRoom:
	var parts := path.split("/", false)

	if parts.size() != 2:
		push_error("RoomManager: Invalid room path: " + path)
		return null

	return _find_ship_room(parts[0], parts[1]) 

func connect_rooms(a: GameRoom, b: GameRoom) -> void:
	a.exits[b.room_name.to_lower()] = a.get_path_to(b)
	b.exits[a.room_name.to_lower()] = b.get_path_to(a)

func connect_ladder(a: GameRoom, b: GameRoom) -> void:
	connect_rooms(a, b)
	
	var exit_a: String = b.room_name.to_lower()
	var exit_b: String = a.room_name.to_lower()
	
	if not a.ladder_exits.has(exit_a):
		a.ladder_exits.append(exit_a)
	
	if not b.ladder_exits.has(exit_b):
		b.ladder_exits.append(exit_b)

func lock_exit(a: GameRoom, b: GameRoom, key_id: String) -> void:
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
