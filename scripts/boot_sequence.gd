extends Control

@onready var system_header: Label = $TerminalArea/BootText/SystemHeader
@onready var sequence_title: Label = $TerminalArea/BootText/SequenceTitle
@onready var diagnostic_output: RichTextLabel = $TerminalArea/BootText/DiagnosticOutput
@onready var boot_audio: AudioStreamPlayer = $BootAudio

const BOOT_MESSAGES: Array[Dictionary] = [
	{"time": 2.0, "text": "POWER DISTRIBUTION ............. ONLINE"},
	{"time": 4.5, "text": "NAVIGATION CONTROL  ............. ONLINE"},
	{"time": 7.0, "text": "LIFE SUPPORT ............. ONLINE"},
	{"time": 10.0, "text": "CRYO-STASIS ............. 3/4 OPERATIONAL"},
	{"time": 13.5, "text": "MuThUr INTERFACE ............. ACTIVE"},
	{"time": 17.5, "text": "SYSTEM DIAGNOSTICS COMPLETE"},
]

func _ready() -> void:
	diagnostic_output.clear()
	boot_audio.play()
	await run_boot_sequence()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func run_boot_sequence() -> void:
	var elapsed := 0.0
	
	for message in BOOT_MESSAGES:
		var message_time: float = message["time"]
		var delay := message_time - elapsed
		
		await get_tree().create_timer(delay).timeout
		
		diagnostic_output.append_text(message["text"] + "\n")
		elapsed = message_time
