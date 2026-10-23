extends Resource
class_name GameTerminal


@export var terminal_name := "terminal"
@export_multiline var greeting := ""
@export var required_item := ""
@export var entries: Array[TerminalEntry] = []
@export var text_color := Color(1.0, 0.7, 0.2)
@export var password := ""
