class_name GSSH
extends Node
# A helper node that communicates with and sends information to the GSS singleton
# Dynamically loaded means that this object doesn't exist before the GSS.save or GSS.load function is ran
#	^ Limitations:
#		- NO MIXING: If a node is dynamically loaded it CANNOT exist at the
#					 start of a scene.
#		- NO NESTING: A dynamically loaded object's parent CANNOT also be dynamically loaded. In addition,
#					  the parent must have its own gssh with at least a uid.
#		- The target must be thwe main node in a scene file, and the scene_file_path MUST be filled out.

export var saved_properties := PoolStringArray()
export var target_parent: bool = true
export var target_path: String = ""
export var uid: String = "" setget register_uid
export var dynamically_loaded: bool = false
# ^ Identifies used to sort which data gets to which GSSH
export var scene_file_path: String = ""
# ^ NECESSARY for dynamically loaded objects
export var file_name: String = ""

var target: Node
const UID_TAKEN_REPLACEMENT := "TAKEN"


func _ready() -> void:
	file_name = GSS.default_file_name if file_name == "" else file_name
	if not dynamically_loaded:
		GSS.add_gssh(uid, self, file_name)
	else:
		GSS.add_dynamic_gssh(self, file_name)
	if target_parent:
		target = get_parent()
	else:
		target = get_node(target_path)


func save_properties() -> void:
	if not dynamically_loaded:
		# Saves all properties of the parent node listed in "saved_properties" to the GSS
		var properties2save := {}
		for property in saved_properties:
			properties2save[property] = target[property]
		if uid != UID_TAKEN_REPLACEMENT:
			GSS.add_node_data(uid, properties2save)
	else:
		#saves data for dynamically loaded objects
		var properties2save := {}
		for property in saved_properties:
			properties2save[property] = target[property]
		var parent_uid: String
		if target_parent:
			parent_uid = $"../../GSSH".uid  #gets the uid stored in the gssh of the parent of the target
		else:
			var path: String = target_path + "/../GSSH"
			parent_uid = get_node(path).uid
		if uid != UID_TAKEN_REPLACEMENT and parent_uid != UID_TAKEN_REPLACEMENT:
			GSS.add_dynamic_node_data(uid, parent_uid, scene_file_path, properties2save)


func load_data(data: Dictionary) -> void:
	# Data is pushed from the GSS, after the GSS loaded it from a file.
	# Updates all the properties of the parent node with the properties in data
	if uid in data.keys() and uid != UID_TAKEN_REPLACEMENT:
		for property in data[uid].keys():
			target[property] = data[uid][property]


func dyn_node_load(data: Dictionary) -> void:
	# used to distribute properties from the more bare-bones properties Dictionary
	# that dynamic nodes recieve from the GSS
	for property in data.keys():
		target[property] = data[property]


func register_uid(new_uid: String) -> void:
	# Checks if the UID already exists in the GSS uid registration array
	# if it does, it sets the uid to UID_TAKEN_REPLACEMENT so that I will know to change it
	# if it doesn't, it adds the uid to the GSS registry and updates the uid
	if new_uid in GSS.uid_registry:
		uid = UID_TAKEN_REPLACEMENT if uid == "" else uid
	else:
		uid = new_uid
