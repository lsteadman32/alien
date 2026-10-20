extends Node


func _ready() -> void:
	connect_rooms($CryoChamber, $JunctionA1)
	connect_rooms($CryoChamber, $JunctionA5)
	connect_rooms($JunctionA1, $MessHall)
	connect_rooms($JunctionA5, $LockerRoom)
	connect_rooms($LockerRoom, $JunctionA3)
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


func connect_rooms(a: GameRoom, b: GameRoom) -> void:
	a.exits[b.room_name.to_lower()] = a.get_path_to(b)
	b.exits[a.room_name.to_lower()] = b.get_path_to(a)
