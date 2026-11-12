extends Node
class_name Xenomorph

#available states
enum State {
	DORMANT,
	PATROLLING,
	INVESTIGATING,
	STALKING,
	HUNTING,
	ATTACKING,
	RETREATING,
	DEAD
}

signal state_changed(old_state: int, new_state: int)
signal xenomorph_event(message: String)

# Current state
var current_state: State = State.DORMANT

#Previous State
var previous_state: State = State.DORMANT

#AI variables
var awareness: int = 0
const MAX_AWARENESS: int = 100

var turns_in_state: int = 0
var turns_since_visual: int = 0
var player_visible: bool = false

#Room Tracking
var current_room: GameRoom
var previous_room: GameRoom
var player_room: GameRoom
var last_known_player_room: GameRoom
var starting_room: GameRoom = null
var has_reached_investigation_site: bool = false

func _ready() -> void:
	print("Xenomorph initialized.")

func initialize(starting_player_room: GameRoom) -> void:
	player_room = starting_player_room
	current_state = State.DORMANT
	
	print("Xenomorph state: DORMANT")

func awaken(spawn_room: GameRoom) -> void:
	if current_state != State.DORMANT:
		return
	
	if spawn_room == null:
		print("Xenomorph ERROR: Invalid spawn room.")
		return
	
	
	starting_room = spawn_room
	current_room = spawn_room
	previous_room = null
	
	awareness = 0
	turns_in_state = 0
	turns_since_visual = 0
	player_visible = false
	last_known_player_room = null
	
	change_state(State.PATROLLING)
	
	xenomorph_event.emit(
		"Something moves in the darkness nearby..."
	)
	print("Xenomorph awakened in: ", current_room.room_name)

func change_state(new_state: State) -> void:
	if current_state == new_state:
		return
		
	previous_state = current_state
	current_state = new_state
	turns_in_state = 0
	
	state_changed.emit(previous_state, current_state)
	
	print("Xenomorph state: ", State.keys()[current_state])
	
	enter_state(current_state)

func enter_state(state: State) -> void:
	match state:
		State.DORMANT:
			xenomorph_event.emit("You feel a presence lurking in the shadows, though you cannot see anything amiss.")
		State.PATROLLING:
			xenomorph_event.emit("Something moves nearby.")
		State.INVESTIGATING:
			xenomorph_event.emit("Something has attracted its attention.")
		State.STALKING:
			xenomorph_event.emit("You are being watched.")
		State.HUNTING:
			xenomorph_event.emit("You hear an ear shattering screech like metal rubbed against metal as the creature screams. It knows where you are.")
		State.ATTACKING:
			xenomorph_event.emit("The Xenomorph attacks.")
		State.RETREATING:
			xenomorph_event.emit("The creature disappears into the darkness. It is gone for now.")
		State.DEAD:
			xenomorph_event.emit("The creature is dead.")

func report_noise(intensity: int = 25) -> void:
	if current_state == State.DORMANT:
		return
	if current_state == State.DEAD:
		return
	awareness = clampi(awareness + intensity, 0, MAX_AWARENESS)
	
	last_known_player_room = player_room
	has_reached_investigation_site = false
	
	match current_state:
		State.DORMANT, State.PATROLLING, State.STALKING:
			change_state(State.INVESTIGATING)
			
		State.INVESTIGATING:
			turns_in_state = 0

func report_player_seen() -> void:
	if current_state == State.DEAD:
		return
	
	awareness = MAX_AWARENESS
	player_visible = true
	turns_since_visual = 0
	
	last_known_player_room = player_room
	
	if current_state != State.ATTACKING:
		change_state(State.HUNTING)

func report_player_lost() -> void:
	player_visible = false
	
	if current_state == State.HUNTING:
		change_state(State.STALKING)

func on_player_moved(old_room: GameRoom, new_room: GameRoom) -> void:
	player_room = new_room
	
	if current_room == new_room:
		report_player_seen()
	
	elif current_room == old_room:
		report_player_lost()

func advance_turn() -> void:
	if current_state == State.DORMANT:
		return
	
	turns_in_state += 1
	
	if not player_visible:
		turns_since_visual += 1
	
	match current_state:
		State.DORMANT:
			change_state(State.PATROLLING)
		State.PATROLLING:
			process_patrolling()
		State.INVESTIGATING:
			process_investigating()
		State.STALKING:
			process_stalking()
		State.HUNTING:
			process_hunting()
		State.ATTACKING:
			process_attacking()
		State.RETREATING:
			process_retreating()

func move_to_random_adjacent_room() -> void:
	if current_room == null:
		return
	
	var available_rooms: Array[GameRoom] = []
	
	for exit_name in current_room.exits.keys():
		
		#cannot pass through locked doors
		if current_room.locked_exits.has(exit_name) or current_room.secured_exits.has(exit_name):
			continue
		
		var candidate := current_room.get_node_or_null(
			current_room.exits[exit_name]
		) as GameRoom
		
		if candidate == null:
			continue
		
		if candidate != previous_room:
			available_rooms.append(candidate)
	
	if available_rooms.size() > 1 and previous_room != null:
		available_rooms.erase(previous_room)
		
	if available_rooms.is_empty():
		return
	
	var destination: GameRoom = available_rooms.pick_random()
	
	previous_room = current_room
	current_room = destination
	
	print(
		"Xenomorph moved from ",
		previous_room.room_name,
		" to ",
		current_room.room_name
	)
	
	if current_room == player_room:
		report_player_seen()

func find_path(start_room: GameRoom, target_room: GameRoom) -> Array[GameRoom]:
	var path: Array[GameRoom] = []
	
	if start_room == null or target_room == null:
		print("BFS ERROR: Invalid starting or target room.")
		return path
	print("BFS: Initializing search.")
	
	var queue: Array[GameRoom] = [start_room]
	var came_from: Dictionary = {}
	
	came_from[start_room.get_instance_id()] = null
	
	var iterations: int = 0
	const MAX_ITERATIONS: int = 200
	
	while not queue.is_empty():
		
		iterations += 1
		
		if iterations > MAX_ITERATIONS:
			print("BFS ERROR: Search exceeded iteration limit.")
			return []
		
		var current: GameRoom = queue.pop_front()
		
		print("BFS examining: ", current.room_name)
		
		if current == target_room:
			print("BFS: Target reached.")
			break
		
		for exit_name in current.exits.keys():
			if current.locked_exits.has(exit_name) or current.secured_exits.has(exit_name):
				continue
			
			var next_room: GameRoom = current.get_node_or_null(
				current.exits[exit_name]
			)
			if next_room == null:
				print("BFS: Invalid exit: ", exit_name)
				continue
			
			var room_id: int = next_room.get_instance_id()
			
			if came_from.has(room_id):
				continue
			
			came_from[room_id] = current
			queue.append(next_room)
			
	if not came_from.has(target_room.get_instance_id()):
		print("BFS: No route found.")
		return path
	var step: GameRoom = target_room
	
	while step != start_room:
		
		path.push_front(step)
		
		var parent: GameRoom = came_from.get(
			step.get_instance_id()
		) as GameRoom
		
		if parent == null:
			print("BFS ERROR: Could not reconstruct path.")
			return []
		step = parent
	path.push_front(start_room)
	print("BFS: Path successfully reconstructed.")
	return path

func move_one_step_toward(target_room: GameRoom) -> bool:
	if current_room == null or target_room == null:
		return false
	
	var path: Array[GameRoom] = find_path(
		current_room,
		target_room
	)
	
	if path.size() < 2:
		return false
	
	var destination: GameRoom = path[1]
	
	previous_room = current_room
	current_room = destination
	
	print(
		"Xenomorph pursuing: ",
		previous_room.room_name,
		" -> ",
		current_room.room_name,
		" (target: ",
		target_room.room_name,
		")"
	)
	
	if current_room == player_room:
		report_player_seen()
	
	return true


func process_dormant() -> void:
	pass

func process_patrolling() -> void:
	move_to_random_adjacent_room()

func process_investigating() -> void:
	if last_known_player_room != null:
		if current_room == last_known_player_room:
			has_reached_investigation_site = true
		
		if not has_reached_investigation_site:
			move_one_step_toward(last_known_player_room)
			if current_room == last_known_player_room:
				has_reached_investigation_site = true
		else:
			move_to_random_adjacent_room()
	
	if current_state != State.INVESTIGATING:
		return
	
	awareness = maxi(awareness -5, 0)
	
	if turns_in_state >= 3:
		if awareness > 0:
			change_state(State.STALKING)
		else:
			change_state(State.PATROLLING)

func process_stalking() -> void:
	if turns_in_state % 2 == 0:
		if not has_reached_investigation_site and last_known_player_room != null:
			move_one_step_toward(last_known_player_room)
			
			if current_room == last_known_player_room:
				has_reached_investigation_site = true
			
		else:
			move_to_random_adjacent_room()
	if current_state != State.STALKING:
		return
	awareness = maxi(awareness -5, 0)
	
	if awareness <= 0:
		change_state(State.RETREATING)

func process_hunting() -> void:
	if player_room == null:
		return
	
	if current_room != player_room:
		move_one_step_toward(player_room)
	
	elif player_visible:
		#the creature is in the room
		#implementing attack later
		pass
	
	if not player_visible:
		change_state(State.STALKING)

func process_attacking() -> void:
	pass

func trigger_attack() -> void:
	if current_state == State.DEAD:
		return
	
	change_state(State.ATTACKING)

func end_attack() -> void:
	if current_state == State.ATTACKING:
		change_state(State.RETREATING)

func process_retreating() -> void:
	if turns_in_state >= 2:
		awareness = 0
		change_state(State.PATROLLING)

func kill_xenomorph() -> void:
	awareness = 0
	player_visible = false
	change_state(State.DEAD)

func process_dead() -> void:
	pass

#Debugging

func debug_pathfinding(target_room: GameRoom) -> void:
	print("\n--- BFS PATHFINDING TEST ---")
	if current_room == null:
		print("ERROR: Xenomorph has no current room.")
		return
	
	if target_room == null:
		print("ERROR: Target room is null.")
		return
	
	print("Starting room: ", current_room.room_name)
	print("Target room: ", target_room.room_name)
	
	var path: Array[GameRoom] = find_path(
		current_room,
		target_room
	)
	
	if path.is_empty():
		print("RESULT: No path found.")
		return
	
	print("RESULT: Path found!")
	
	for i in range(path.size()):
		print(
			"Step ",
			i,
			": ",
			path[i].room_name
		)
		
		print("Total rooms: ", path.size())
		print("Total movements required: ", path.size() -1)
		print("--- END BFS TEST ---\n")

func get_state_name() -> String:
	return State.keys()[current_state]

func get_awareness() -> int:
	return awareness
