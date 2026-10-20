@tool
extends PanelContainer
class_name GameRoom



@export var room_name: String = "Name" :
	set( name ) :
		$MarginContainer/Rows/RoomName.text = name
		room_name = name
@export_multiline var room_description: String = "Description" :
	set( desc ) :
		room_description = desc
		$MarginContainer/Rows/RoomDescription.text=desc
@export var exits: Dictionary = {}
@export var items: Array[String] = []
@export var ambient_sound: AudioStream
@export var background: Texture2D


var visited := false

signal entered(room: GameRoom)




func enter() -> String:
	visited = true
	entered.emit(self)
	return describe()

func describe() -> String:
	var text := "%s\n%s" % [room_name, room_description]
	if items.size() > 0:
		text += "\nYou see: " + ", ".join(items)
	text += "\nExits: " + ", ".join(exits.keys())
	return text

func get_exit(dest: String) -> GameRoom:
	if exits.has(dest):
		return get_node(exits[dest]) as GameRoom
	for key in exits:
		if key.begins_with(dest):
			return get_node(exits[key]) as GameRoom
	return null

func take_item(id: String) -> bool:
	if items.has(id):
		items.erase(id)
		return true
	return false

func drop_item(id: String) -> void:
	items.append(id)
