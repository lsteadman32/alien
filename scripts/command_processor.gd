extends Node

@export var item_data: Array [ItemData] = []


signal response_generated(response_text)
var current_room: GameRoom
var previous_room: GameRoom
var inventory: Array[String] = []
var active_terminal: GameTerminal
var player_name := ""
var awaiting_name := false
var item_lookup := {}
var pending_terminal: GameTerminal
var awaiting_password := false

func initialize(starting_room):
	current_room = starting_room
	awaiting_name = true
	emit_signal("response_generated", "Identify yourself, crew member.\nEnter your name:")

func _ready() -> void:
	for d in item_data:
		item_lookup[d.id.to_lower()] = d

func process_command(_input: String) -> String:
	if awaiting_name:
		return set_player_name(_input)
	if awaiting_password:
		return check_password(_input)
	var words = _input.split(" ", false)
	if active_terminal != null:
		return terminal_input(" ".join(words).to_lower())

	if words.size() == 0:
		return "Error: no words were parsed."
	
	var first_word = words[0].to_lower()
	var second_word = " ".join(words.slice(1)).to_lower()
	
	match first_word:
		"back":
			return go("back")
		"go", "move":
			return go(second_word)
		"help":
			return help()
		"unlock":
			return unlock(second_word)
		"take":
			return take(second_word)
		"drop":
			return drop(second_word)
		"inventory", "i":
			return show_inventory()
		"use", "access":
			return use_terminal(second_word)
		"examine", "investigate":
			return find_item_id(second_word)
		_:
			var full_text := " ".join(words).to_lower()
			if current_room.get_exit(full_text) != null:
				return go(full_text)
			return "Unrecognized command - please try again."

func go(second_word: String) -> String:
	if second_word == "":
		return "Go where?"
	if second_word == "back":
		if previous_room == null:
			return "There's nowhere to go back to"
		return move_to(previous_room)
	var exit_name := current_room.find_exit_name(second_word)
	if exit_name == "":
		return "You can't go that way."
	if current_room.locked_exits.has(exit_name):
		return "The way to %s is locked." % exit_name
	return move_to(current_room.get_exit((exit_name)))

func unlock(target: String) -> String:
	var exit_name := current_room.find_exit_name(target)
	if exit_name == "":
		return "There's nothing like that to unlock."
	if not current_room.locked_exits.has(exit_name):
		print("locks here: ", current_room.locked_exits)
		return "It isn't locked."
	var key_id: String = current_room.locked_exits[exit_name]
	if not inventory.has(key_id):
		return "You don't have anything that opens it."
	current_room.unlock_exit(exit_name)
	return "You unlock the way to %s." % exit_name

func move_to(room: GameRoom) -> String:
	previous_room = current_room
	current_room = room
	print("moved from", previous_room.room_name, " to ", room.room_name)
	return room.enter()

func take(item: String) -> String:
	if item == "":
		return "Take what?"
	if current_room.take_item(item):
		inventory.append(item)
		return "You take the %s." % item
	return "You don't see that here."

func find_entry(term: GameTerminal, text: String) -> TerminalEntry:
	var names: Array = []
	for e in term.entries:
		names.append(e.command.strip)

func find_item_id(query: String) -> String:
	return Fuzzy.best_match(query, inventory)

func examine(query: String) -> String:
	if query == "":
		return "Examine what?"
	var id := find_item_id(query)
	if id == "":
		return "You aren't carrying that."
	if not item_lookup.has(id):
		return "You see nothing special about the %s." % id
	var data: ItemData = item_lookup[id]
	return data.description.replace("{name}", player_name)

func use_terminal(target: String) -> String: 
	var term := current_room.find_terminal(target)
	var greeting := term.greeting.replace("{name}", player_name)
	if term == null:
		return "There's nothing like that to use."
	if term.required_item != "" and not inventory.has(term.required_item):
		return "ACCESS DENIED. Authorization required."
	if term.password != "":
		pending_terminal = term
		awaiting_password = true
		return "%s\n ENTER PASSWORD (or type cancel):" % term.terminal_name
	return open_terminal(term)

func open_terminal(term: GameTerminal) -> String:
	active_terminal = term
	var greeting := term.greeting.replace("{name}", player_name)
	return "%s\nAvailable: %s\nType 'logout' to leave session.\nREMEMBER\nCompany information is private information." % [greeting, list_entries(term)]


func check_password(text: String) -> String:
	awaiting_password = false
	var term := pending_terminal
	pending_terminal = null
	var attempt := text.strip_edges().to_lower()
	if attempt == "cancel":
		return "You step away from the terminal."
	if attempt == term.password.to_lower():
		return open_terminal(term)
	return "ACCESS DENIED.\nIncorrect password. Please try again."

func terminal_input(text: String) -> String:
	if text == "logout" or text == "exit":
		active_terminal = null
		return "You step away from the terminal."
	for e in active_terminal.entries:
		if e.command.begins_with(text):
			var result: String = e.text.replace("{name}", player_name)
			if e.unlocks_exit != "":
				var target: GameRoom = current_room
				if e.unlocks_room != "":
					target = find_room(e.unlocks_room)
				print("terminal target room: ", target.room_name if target else "NULL")
				if target != null and target.unlock_exit(e.unlocks_exit):
					result += "\n[ACCESS GRANTED: %s unlocked]" % e.unlocks_exit
				else:
					result += "\n[%s is already unlocked]" % e.unlocks_exit
				return e.text.replace("{name}", player_name)
			return result
	return "Unknown entry. Available: " + list_entries(active_terminal)


func drop(item: String) -> String:
	if not inventory.has(item):
		return "You aren't carrying that."
	inventory.erase(item)
	current_room.drop_item(item)
	return "You drop the %s." % item

func show_inventory() -> String:
	if inventory.is_empty():
		return "You aren't carrying anything."
	return "You are carrying: " + ", ".join(inventory)

func help() -> String:
	return "You can use these commands: go [location], take [item], drop [item], inventory or i, help"

func change_room(new_room: GameRoom):
	current_room = new_room
	emit_signal("response_generated", new_room.enter())

func set_player_name(text: String) -> String:
	var cleaned := text.strip_edges()
	if cleaned == "":
		return "Please enter a name."
	player_name = cleaned.substr(0, 24)
	awaiting_name = false
	return "Good morning, %s.\n\n%s" % [player_name, current_room.enter()]

func list_entries(term: GameTerminal) -> String: 
	var names: Array[String] = []
	for e in term.entries:
		names.append(e.command)
	return ",".join(names)

func find_room(room: String) -> GameRoom:
	for r in current_room.get_parent().get_children():
		if r is GameRoom and r.room_name.to_lower() == room.to_lower():
			return r
	return null
