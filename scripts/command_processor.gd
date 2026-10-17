extends Node


signal response_generated(response_text)



var current_room: GameRoom
var previous_room: GameRoom


func initialize(starting_room):
	change_room(starting_room)

func process_command(_input: String) -> String:
	var words = _input.split(" ", false)
	if words.size() == 0:
		return "Error: no words were parsed."
	
	var first_word = words[0].to_lower()
	var second_word = " ".join(words.slice(1)).to_lower()
	
	match first_word:
		"back":
			return go("back")
		"go":
			return go(second_word)
		"help":
			return help()
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
	var next: GameRoom = current_room.get_exit(second_word)
	if next == null:
		return "You can't go that way."
	return move_to(next)

func move_to(room: GameRoom) -> String:
	previous_room = current_room
	current_room = room
	print("moved from", previous_room.room_name, " to ", room.room_name)
	return room.enter()

func help() -> String:
	return "You can use these commands: go [location], help"

func change_room(new_room: GameRoom):
	current_room = new_room
	emit_signal("response_generated", new_room.enter())
