@tool
extends PanelContainer
class_name GameRoom


@export_group("Map Settings")
@export_range(1,20) var deck_number: int = 1
@export var map_position: Vector2i = Vector2i.ZERO

@export_group("Stealth Settings")
@export var hiding_spots: Array[String] = []

@export_group("Room Information")
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
@export_multiline var short_description := ""
@export var hidden_items: Array[String] = []
@export var hidden_exits: Array[String] = []
@export_multiline var search_text := ""


var visited := false

signal entered(room: GameRoom)




func enter() -> String:
	var first: = not visited
	visited = true
	entered.emit(self)
	return describe(first)

func describe(full: bool = true) -> String:
	var desc := room_description
	if not full and short_description != "":
		desc = short_description
	var text := "%s\n%s" % [room_name, desc]
	if items.size() > 0:
		text += "\n\nYou see: " + ", ".join(items).to_upper()
	var labels: Array[String] = []
	for e in visible_exits():
		labels.append(e + " (locked)" if locked_exits.has(e) else e)
	text += "\n\nExits: " + ", ".join(labels).to_upper()
	return text

func visible_exits() -> Array:
	var result: Array = []
	for k in exits.keys():
		if not hidden_exits.has(k):
			result.append(k)
	return result

func search() -> String:
	var found: Array[String] = []
	for id in hidden_items:
		items.append(id)
		found.append(id)
	hidden_items.clear()
	var revealed: Array[String] = []
	for ex in hidden_exits:
		revealed.append(ex)
	hidden_exits.clear()
	if found.is_empty() and revealed.is_empty():
		return "You search the area thoroughly but find nothing."
	var text := search_text if search_text != "" else "You search the room carefully."
	if not found.is_empty():
		text += "\nItems: " + ", ".join(found)
	if not revealed.is_empty():
		text += "\nYou discover a way: " + ", ".join(revealed)
	return text


func find_exit_name(dest: String) -> String:
	if exits.has(dest) and not hidden_exits.has(dest):
		return dest
	return Fuzzy.best_match(dest, visible_exits())

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
