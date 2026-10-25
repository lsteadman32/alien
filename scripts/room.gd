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
@export var locked_exits: Dictionary = {}
@export var items: Array[String] = []
@export var ambient_sound: AudioStream
@export var background: Texture2D
@export var terminals: Array[GameTerminal] = []

var visited := false

signal entered(room: GameRoom)




func enter() -> String:
	visited = true
	entered.emit(self)
	return describe()

func describe() -> String:
	var text := "%s\n\n%s" % [room_name, room_description]
	for t in terminals:
		text += "\nA terminal is here"
	if items.size() > 0:
		text += "\nYou see: " + ", ".join(items)
	
	var labels: Array[String] = []
	for e in exits.keys():
		labels.append(e + " (locked)" if locked_exits.has(e) else e)
	text += "\nExits: " + ", ".join(labels)
	return text

func find_exit_name(dest: String) -> String:
	if exits.has(dest):
		return dest
	var hit := Fuzzy.best_match(dest, exits.keys())
	return hit

func get_exit(dest: String) -> GameRoom:
	var key := find_exit_name(dest)
	if key == "":
		return null
	return get_node(exits[key]) as GameRoom

func take_item(id: String) -> bool:
	if items.has(id):
		items.erase(id)
		return true
	return false

func find_terminal(query: String) -> GameTerminal:
	if terminals.is_empty():
		return null
	if query == "" or query == "terminal":
		return terminals[0]
	var names: Array = []
	for t in terminals:
		if t != null:
			names.append(t.terminal_name.to_lower())
	var hit := Fuzzy.best_match(query, names)
	for t in terminals:
		if t != null and hit != "" and t.terminal_name.to_lower() == hit:
			return t
	return null


func unlock_exit(query: String) -> bool:
	var key := find_exit_name(query.to_lower())
	print("unlock_exit: query=[", query, "] key =[", key, "] locks=", locked_exits)
	if key == "" or not locked_exits.has(key):
		return false
	locked_exits.erase(key)
	var other := get_node(exits[key])
	if other != null:
		other.locked_exits.erase(room_name.to_lower())
	return true

func drop_item(id: String) -> void:
	items.append(id)
