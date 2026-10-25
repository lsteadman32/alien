extends Label
@export var typing_speed: float = 25.0
var total_characters: int = 0
var typing_time: float = 0.0
var is_typing: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_typewriter()

func start_typewriter() -> void:
	visible_characters = 0
	total_characters = get_total_character_count() if "get_total_character_count" in self else text.length()
	typing_time = 0.0
	is_typing = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_typing:
		return
	
	typing_time += delta
	visible_characters = int(typing_time * typing_speed)
	
	if visible_characters >= total_characters:
		visible_characters = total_characters
		is_typing = false
