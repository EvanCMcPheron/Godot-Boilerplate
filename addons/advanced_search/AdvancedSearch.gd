tool
extends EditorPlugin

var list_item_load
var dock
var search_result_container

var node_types: Array = ["AudioStreamPlayer", "AudioStreamPlayer2D", "AudioStreamPlayer3D",\
	"Spatial", "Node2D", "MeshInstance", "Node", "Control", "AnimationPlayer", "CollisionShape",\
	"CollisionShape2D", "Room", "Skeleton", "Skeleton2D"]

var tscns: Dictionary = {}
# we only care about the keys of this dictionary
var type_filter: Array = []
var text_filter: String = ""
var regex_filter: RegEx = RegEx.new()

func _enter_tree():
	dock = preload("res://addons/advanced_search/AdvancedSearch.tscn").instance()
	list_item_load = preload("res://addons/advanced_search/ListItem.tscn")
	add_control_to_dock(DOCK_SLOT_LEFT_BR, dock)
	dock.get_node("Search").connect("pressed", self, "search")
	dock.get_node("%LineEdit").connect("text_changed", self, "update_text_filter")
	search_result_container = dock.get_node("%SearchResults")
	var node_type_list = dock.get_node("%NodeTypeList")
	node_types.sort()
	for node_type in node_types:
		var node_list_item = CheckBox.new()
		node_list_item.text = node_type
		node_list_item.connect("toggled", self, "update_node_type", [node_type])
		node_type_list.add_child(node_list_item)

func _exit_tree():
	# clear dock
	remove_control_from_docks(dock)
	dock.queue_free()

func update_text_filter(new_text):
	text_filter = new_text
	search()

func update_node_type(pressed, node_type):
	if pressed:
		type_filter.append(node_type)
	else:
		type_filter.erase(node_type)
	search()

func get_all_tscns():
	var folders = []
	var tscns = []
	var dir = Directory.new()
	var path = "res://"
	dir.open(path)
	dir.list_dir_begin()
	
	# initial loop through the uppermost directory, filtering out addons and builds
	while true:
		var file = dir.get_next()
		var full_path = path + file
		if file == "":
			break
		elif not file.begins_with(".") and full_path != "res://addons" and full_path != "res://builds":
			if file.get_extension() == "tscn":
				tscns.append(full_path)
			elif dir.dir_exists(full_path):
				folders.append(full_path)
	
	dir.list_dir_end()
	
	# loop through the rest of the files
	# I deliberately chose not to use recursion here
	while !folders.empty():
		path = folders.front()
		dir.open(path)
		dir.list_dir_begin()
		
		while true:
			var file = dir.get_next()
			var full_path = path + "/" + file
			if file == "":
				break
			elif not file.begins_with("."):
				if file.ends_with(".tscn"):
					tscns.append(full_path)
				elif dir.dir_exists(full_path):
					folders.append(full_path)
		
		dir.list_dir_end()
		folders.pop_front()
	
	return tscns

func compile_text_filter():
	var type_filter_string: String = "|".join(type_filter)
	if type_filter.size() == 0:
		type_filter_string = ".*"
	regex_filter.compile("\\[node name=\".*{0}.*\" type=\"({1})\" .*\\]"\
		.format([text_filter, type_filter_string]))

func filter_tscns(file) -> bool:
	var filter_pass: bool = false
	var f = File.new()
	f.open(file, File.READ)
	while not f.eof_reached(): # iterate through all lines until the end of file is reached
		var line: String = f.get_line()
		# only check node header lines
		if line.begins_with("[node ") and regex_filter.search(line):
			filter_pass = true
			break
	f.close()
	return filter_pass

func search():
	var all_tscns = get_all_tscns()
	tscns = {}
	compile_text_filter()
	for file in all_tscns:
		if filter_tscns(file):
			tscns[file.get_file()] = file
	
	# we try not to delete children and immediately re-instance them, instead we add more children
	# as needed and adjust the existing ones to fit
	var result_labels = search_result_container.get_children()
	var index: int = 0
	while result_labels.size() <= tscns.size():
		var list_item = list_item_load.instance()
		search_result_container.add_child(list_item)
		result_labels.append(list_item)
	for tscn in tscns:
		result_labels[index].visible = true
		result_labels[index].text = tscn
		if result_labels[index].is_connected("pressed", self, "scene_clicked"):
			result_labels[index].disconnect("pressed", self, "scene_clicked")
		result_labels[index].connect("pressed", self, "scene_clicked", [tscns[tscn]])
		index += 1
	while index < result_labels.size():
		result_labels[index].visible = false
		index += 1

func scene_clicked(scene_path):
	print(scene_path)
	var interface = get_editor_interface()
	interface.open_scene_from_path(scene_path)
