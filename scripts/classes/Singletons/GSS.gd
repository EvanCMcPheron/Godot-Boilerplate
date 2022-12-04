extends Node
# A singleton that stores, saves, and loads data from and to all GSSH nodes

var helper_ref := {}	# uid:Node_Reference
var helper_filenames := {}	# uid:file_name
var dynamic_helper_ref := []
var dynamic_helper_filenames := {}	#uid:file_name
var data_holder: GSSR
var uid_registry := []
var dir: String = "user://Saves"
var default_file_name := "gs"
var file_type := ".tres"


func save_data(file_name: String = default_file_name) -> void:
	# Clears the dictionary then tells all the helpers to update the dictionary
	# with their node's data.
	var path = dir + "/" + file_name + file_type
	if data_holder == null:
		data_holder = GSSR.new()
	data_holder.data.clear()
	data_holder.dynamic_node_data.clear()

	for helper_key in helper_ref.keys(): 
		var helper:Node = helper_ref[helper_key]
		var save_file_name:String = helper_filenames[helper_key]
		#if helper is currently loaded AND it's save file name is the same as the file being loaded
		if helper.saved_properties != null and save_file_name == file_name:
			helper.save_properties()
	for dyn_helper_indx in range(dynamic_helper_ref.size()):
		var dyn_helper:Node = dynamic_helper_ref[dyn_helper_indx]
		var dyn_helper_file:String = dynamic_helper_filenames[dyn_helper.uid]
		#if helper is currently loaded AND it's save file name is the same as the file being loaded
		if dyn_helper.saved_properties != null and dyn_helper_file == file_name:
			dyn_helper.save_properties()

	data_holder.version = ProjectSettings.get_setting("global/version")
	var directory = Directory.new()
	if not directory.dir_exists(dir):
		directory.make_dir_recursive(dir)
	ResourceSaver.save(path, data_holder)


func load_data(file_name: String = default_file_name) -> void:
	# Loads the resource file if it exists then updates all the GSSHs
	var path = dir + "/" + file_name + file_type
	var file = File.new()
	if file.file_exists(path):
		data_holder = load(path)
	else:
		data_holder = GSSR.new()

	if data_holder.version == ProjectSettings.get_setting("global/version"):
		for helper_key in helper_ref.keys(): 
			var helper:Node = helper_ref[helper_key]
			var save_file_name:String = helper_filenames[helper_key]
			#if helper is currently loaded AND it's save file name is the same as the file being loaded
			if helper.saved_properties != null and save_file_name == file_name:
				helper.load_data(data_holder.data)

		# erases all dynamic nodes, replaces them with the saved dynamic nodes, and fills in the new node's values
		for dyn_helper_indx in range(dynamic_helper_ref.size()):
			# Since an element is getting removed each time, we know the index of the element in question is allways 0
			# If the current dyn_helper's filename matches the current file being loaded
			if dynamic_helper_filenames[dynamic_helper_ref[0].uid] == file_name:
				if dynamic_helper_ref[0].saved_properties != null:
					dynamic_helper_ref[0].target.queue_free()
				dynamic_helper_ref.remove(0)

		for dyn_uid in data_holder.dynamic_node_data.keys():  # Create dynamic nodes according to file info
			var dyn_info:Dictionary = data_holder.dynamic_node_data[dyn_uid]
			for node_indx in range(int(dyn_info.count)):
				var parent: Node = helper_ref[dyn_info.parent_uids[node_indx]].get_parent()
				var node: Node = load(dyn_info.path).instance()
				parent.add_child(node)
				node.get_node("GSSH").dyn_node_load(dyn_info.properties[node_indx])


func add_gssh(uid: String, reference: Node, save_file_name:String) -> void:
	# Adds a GSSH (gamestatesaver helper) to the references array
	# Called by all GSSH's in their ready function
	helper_ref[uid] = reference
	helper_filenames[uid] = save_file_name


func add_dynamic_gssh(reference: Node, save_file_name:String) -> void:
	# Dynamic nodes need their own seperate add_gssh function because multiple
	# dynamic nodes can share one uid, which breaks the dictionary reference system
	# standard nodes use. So, dynamic gssh references are stored in a seperate array.
	dynamic_helper_ref.append(reference)
	dynamic_helper_filenames[reference.uid] = save_file_name


func add_node_data(uid: String, property_data: Dictionary) -> void:
	data_holder.data[str(uid)] = property_data


func add_dynamic_node_data(
	uid: String, parent_uid: String, scene_file_path: String, properties2save: Dictionary
) -> void:
	if data_holder.dynamic_node_data.has(uid):
		# add one to count, append parent uid to parent_uids, append new data to properties
		data_holder.dynamic_node_data[uid].count += 1
		data_holder.dynamic_node_data[uid].parent_uids.append(parent_uid)
		data_holder.dynamic_node_data[uid].properties.append(properties2save)
	else:
		#create an entry for this dynamic node's uid
		data_holder.dynamic_node_data[uid] = {
			"count": 1,
			"path": scene_file_path,
			"parent_uids": [parent_uid],
			"properties": [properties2save],
		}


func check_for_viable_save_file(file_name: String = "gs.tres") -> bool:
	var data: Resource
	var path = dir + "/" + file_name

	var file = File.new()
	if file.file_exists(path):
		data = load(path)
	else:
		return false

	if data_holder.version == ProjectSettings.get_setting("global/version"):
		return true
	else:
		return false
