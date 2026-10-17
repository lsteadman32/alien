extends Node


func _ready() -> void:
	connect_rooms($CryoChamber, $JunctionA1)
	connect_rooms($CryoChamber, $JunctionA5)
	connect_rooms($JunctionA1, $MessHall)
	connect_rooms($JunctionA5, $LockerRoom)

func connect_rooms(a: GameRoom, b: GameRoom) -> void:
	a.exits[b.room_name.to_lower()] = a.get_path_to(b)
	b.exits[a.room_name.to_lower()] = b.get_path_to(a)
