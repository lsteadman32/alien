extends Node


func _ready() -> void:
	# Ship 1 Rooms
	connect_rooms($CryoChamber, $JunctionA1)
	connect_rooms($CryoChamber, $JunctionA5)
	connect_rooms($JunctionA1, $MessHall)
	connect_rooms($JunctionA5, $ChangingRoom)
	connect_rooms($ChangingRoom, $JunctionA3)
	connect_rooms($JunctionA3, $ComputerRoom)
	connect_rooms($ComputerRoom, $Bridge)
	connect_rooms($Bridge, $JunctionA2)
	connect_rooms($JunctionA2, $JunctionA3)
	connect_rooms($JunctionA2, $JunctionA4)
	connect_rooms($JunctionA4, $MedBay)
	connect_rooms($MessHall, $JunctionA2)
	connect_rooms($JunctionA2, $Bridge)
	connect_rooms($MessHall, $Airlock)
	connect_rooms($Airlock, $JunctionA4)
	connect_rooms($Airlock, $Umbilical)
	connect_rooms($Umbilical, $Kinship)
	
	#Ship 1 hidden rooms
	connect_rooms($MedVent, $MedBay)
	connect_rooms($MedVent, $Bridge)
	
	
	# Ship 2 Rooms
	
	# Door locks
	lock_exit($Airlock, $Umbilical, "credentials")
	


func connect_rooms(a: GameRoom, b: GameRoom) -> void:
	a.exits[b.room_name.to_lower()] = a.get_path_to(b)
	b.exits[a.room_name.to_lower()] = b.get_path_to(a)

func lock_exit(a: GameRoom, b: GameRoom, key_id) -> void:
	a.locked_exits[b.room_name.to_lower()] = key_id
	b.locked_exits[b.room_name.to_lower()] = key_id

func hide_exit(a: GameRoom, b: GameRoom) -> void:
	a.hidden_exits.append(b.room_name.to_lower())

func get_rooms_on_deck(deck: int) -> Array[GameRoom]:
	var result: Array[GameRoom] = []
	
	var rooms: Array = find_children("*", "GameRoom", true, false)
	
	for room in rooms:
		if room.deck_number == deck:
			result.append(room)
	
	return result

func get_available_decks() -> Array[int]:
	var decks: Array[int] = []
	var rooms: Array = find_children("*", "GameRoom", true, false)
	
	for room in rooms:
		if room.room_name.strip_edges() == "" or room.room_name == "Name":
			continue
		
		if room.deck_number < 1:
			continue
		
		if not decks.has(room.deck_number):
			decks.append(room.deck_number)
		
	decks.sort()
	return decks
