extends LineEdit


@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
var last_text_length = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	grab_focus()
	text_changed.connect(_on_text_changed)

func _on_text_changed(new_text: String) -> void:
	if new_text.length() > last_text_length:
		audio_player.pitch_scale = randf_range(0.95, 1.01)
		audio_player.play()
	last_text_length = new_text.length()

func _on_text_submitted(_new_text: String) -> void:
	clear()
