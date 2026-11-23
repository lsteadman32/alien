extends Resource
class_name ItemData

#Remember, item descriptions are entered in
#the command processor node under main scene

@export var id := ""
@export_multiline var item_description := ""
@export var is_toggleable: bool = false
