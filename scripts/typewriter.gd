extends Label

signal typing_finished

@export var sound_1: AudioStream
@export var sound_2: AudioStream
@export var sound_3: AudioStream
@export var sound_4: AudioStream

@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

var sound_pool: Array[AudioStream] = []
var typing := false


func _ready() -> void:
	add_to_group("typewriter")
	sound_pool = [sound_1, sound_2, sound_3, sound_4]
	if text != "":
		start_typing()

func skip() -> void:
	if not typing:
		return
	audio_player.stop()
	visible_ratio = 1.0
	typing = false
	typing_finished.emit()

func update_text(new_text: String) -> void:
	text = new_text
	
	start_typing()

func start_typing() -> void:
	var clip := pick_sound()
	if clip == null or text.is_empty():
		visible_ratio = 0.0
		return
	visible_ratio = 1.0
	audio_player.stream = clip
	audio_player.pitch_scale = randf_range(0.95, 1.05)
	audio_player.play()
	typing = true

func pick_sound() -> AudioStream:
	var valid := sound_pool.filter(func(s): return s != null)
	if valid.is_empty():
		return null
	return valid.pick_random()

func _process(delta: float) -> void:
	if not typing:
		return
	if audio_player.playing:
		var clip_length := audio_player.stream.get_length()
		var pos := audio_player.get_playback_position() + AudioServer.get_time_since_last_mix()
		visible_ratio = clampf(pos / clip_length, 0.0, 1.0)
	else:
		visible_ratio = 1.0
		typing = false
		typing_finished.emit()
