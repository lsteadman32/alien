extends Control

signal inventory_closed
signal item_inspected(item_id: String)
signal item_toggled(item_id: String, is_active: bool)

@onready var item_list: ItemList = $MarginContainer/MainLayout/Content/ItemList
@onready var item_name: Label = $MarginContainer/MainLayout/Content/DetailsPanel/DetailsLayout/ItemName
@onready var item_classification: Label = $MarginContainer/MainLayout/Content/DetailsPanel/DetailsLayout/ItemClassification
@onready var item_description: RichTextLabel = $MarginContainer/MainLayout/Content/DetailsPanel/DetailsLayout/ItemDescription

var player_name: String = ""
var inventory_lookup: Dictionary = {}
var current_inventory: Array[String] = []
var active_items: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	item_list.item_selected.connect(_on_item_selected)

func populate_inventory(inventory: Array[String], lookup: Dictionary, character_name: String) -> void:
	current_inventory = inventory
	inventory_lookup = lookup
	player_name = character_name
	
	item_list.clear()
	
	if current_inventory.is_empty():
		item_name.text = "INVENTORY EMPTY"
		item_classification.text = "CLASSIFICATION: --"
		item_description.text = "No items currently registered."
		return
	
	for item_id in current_inventory:
		item_list.add_item(item_id.to_upper())
		
		var index: int = item_list.item_count - 1
		_update_item_list_entry(index, item_id)
	
	item_list.select(0)
	_on_item_selected(0)

func _on_item_selected(index: int) -> void:
	if index < 0 or index >= current_inventory.size():
		return
	
	var item_id: String = current_inventory[index]
	var data: ItemData = inventory_lookup.get(item_id.to_lower())
	
	if data == null:
		return
	
	item_name.text = data.id.to_upper()
	item_description.text = data.item_description.replace(
		"{name}",
		player_name
	)
	item_classification.text = "CLASSIFICATION: --"

func _unhandled_key_input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event is InputEvent and event.pressed and not event.echo:
		match event.keycode:
			KEY_UP:
				_move_selection(-1)
				get_viewport().set_input_as_handled()
			KEY_DOWN:
				_move_selection(1)
				get_viewport().set_input_as_handled()
			KEY_ENTER, KEY_KP_ENTER:
				var selected_items := item_list.get_selected_items()
			
				if not selected_items.is_empty():
					var index: int = selected_items[0]
				
					if index >= 0 and index < current_inventory.size():
						_toggle_selected_item(index)
			
				get_viewport().set_input_as_handled()
			KEY_ESCAPE:
				hide()
				inventory_closed.emit()
				get_viewport().set_input_as_handled()

func _move_selection(direction: int) -> void:
	if item_list.item_count == 0:
		return
	
	var selected_index := item_list.get_selected_items()
	
	var current_index := 0
	if not selected_index.is_empty():
		current_index = selected_index[0]
	
	var new_index := clampi(
		current_index + direction,
		0,
		item_list.item_count - 1
	)
	item_list.select(new_index)
	_on_item_selected(new_index)

func _toggle_selected_item(index: int) -> void:
	var item_id: String = current_inventory[index]
	var item_key: String = item_id.to_lower()
	var data: ItemData = inventory_lookup.get(item_key)
	
	if data == null:
		return
	
	if not data.is_toggleable:
		item_classification.text = "CLASSIFICATION: NON-EQUIPMENT"
		return
	
	var currently_active: bool = active_items.get(item_key, false)
	active_items[item_key] = not currently_active
	item_toggled.emit(item_key, active_items[item_key])
	
	if active_items[item_key]:
		item_classification.text = "CLASSIFICATION: ACTIVE EQUIPMENT"
	else:
		item_classification.text = "CLASSIFICATION: INACTIVE EQUIPMENT"
	
	_update_item_list_entry(index, item_id)

func _update_item_list_entry(index: int, item_id: String) -> void:
	var item_key: String = item_id.to_lower()
	var data: ItemData = inventory_lookup.get(item_key)
	
	if data == null:
		return
	
	var display_text: String = item_id.to_upper()
	
	if data.is_toggleable:
		if active_items.get(item_key, false):
			display_text += " [ACTIVE]"
		else:
			display_text += " [INACTIVE]"
	
	item_list.set_item_text(index, display_text)
