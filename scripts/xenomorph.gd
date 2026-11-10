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

func _ready() -> void:
	print("Xenomorph initialized.")
	change_state(State.DORMANT)

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
	if current_state == State.DEAD:
		return
	awareness = clampi(awareness + intensity, 0, MAX_AWARENESS)
	
	match current_state:
		State.DORMANT, State.PATROLLING:
			change_state(State.INVESTIGATING)
		State.STALKING:
			change_state(State.INVESTIGATING)
		State.INVESTIGATING:
			turns_in_state = 0

func report_player_seen() -> void:
	if current_state == State.DEAD:
		return
	
	awareness = MAX_AWARENESS
	player_visible = true
	turns_since_visual = 0
	
	if current_state != State.ATTACKING:
		change_state(State.HUNTING)

func report_player_lost() -> void:
	player_visible = false
	if current_state == State.HUNTING:
		change_state(State.STALKING)

func advance_turn() -> void:
	if current_state == State.DEAD:
		return
	
	turns_in_state += 1
	if not player_visible:
		turns_since_visual += 1
	
	match current_state:
		State.DORMANT:
			pass
		State.PATROLLING:
			pass
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

func process_dormant(delta: float) -> void:
	pass

func process_patrolling(delta: float) -> void:
	pass

func process_investigating(delta: float) -> void:
	awareness = maxi(awareness - 10, 0)
	if turns_in_state >= 3:
		if awareness > 0:
			change_state(State.STALKING)
		else:
			change_state(State.PATROLLING)

func process_stalking(delta: float) -> void:
	pass

func process_hunting(delta: float) -> void:
	pass

func process_attacking(delta: float) -> void:
	pass

func process_retreating(delta: float) -> void:
	pass

func process_dead(delta: float) -> void:
	pass
