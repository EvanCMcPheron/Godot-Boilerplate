tool
extends SheetsDockEditor

onready var recent_container := $"HBoxContainer/Control2/HBoxContainer/HFlowContainer"
onready var contents_label := $"HBoxContainer/HBoxContainer/Panel/Label"
onready var button_box := $"HBoxContainer/HBoxContainer/Control/VBoxContainer/HBoxContainer"
onready var value_input := $"HBoxContainer/HBoxContainer/Control/VBoxContainer/LineEdit"

var _stored_value
var _stored_type := 0


func try_edit_value(value, type, property_hint) -> bool:
	if (
		type != TYPE_ARRAY and type != TYPE_STRING_ARRAY
		and type != TYPE_INT_ARRAY and type != TYPE_REAL_ARRAY
	):
		return false

	if sheet.column_hint_strings[sheet.get_selected_column()][0].begins_with("2/3:"):
		# For enums, prefer the specialized dock.
		return false

	_stored_type = type
	_stored_value = value.duplicate()  # Generic arrays are passed by reference
	contents_label.text = str(value)
	
	var is_generic_array = _stored_type == TYPE_ARRAY
	button_box.get_child(1).visible = is_generic_array or _stored_type == TYPE_STRING_ARRAY
	button_box.get_child(2).visible = is_generic_array or _stored_type == TYPE_INT_ARRAY
	button_box.get_child(3).visible = is_generic_array or _stored_type == TYPE_REAL_ARRAY

	return true


func _add_value(value):
	_stored_value.append(value)
	var values = sheet.get_edited_cells_values()
	var cur_value
	var dupe_array : bool = ProjectSettings.get_setting(SettingsGrid.SETTING_PREFIX + "dupe_arrays") 
	for i in values.size():
		cur_value = values[i]
		if dupe_array:
			cur_value = cur_value.duplicate()

		cur_value.append(value)
		values[i] = cur_value

	sheet.set_edited_cells_values(values)


func _remove_value(value):
	_stored_value.erase(value)
	var values = sheet.get_edited_cells_values()
	var cur_value
	var dupe_array : bool = ProjectSettings.get_setting(SettingsGrid.SETTING_PREFIX + "dupe_arrays") 
	for i in values.size():
		cur_value = values[i]
		if dupe_array:
			cur_value = cur_value.duplicate()

		if cur_value.has(value): # erase() not defined in PoolArrays
			cur_value.remove(cur_value.find(value))
		
		values[i] = cur_value

	sheet.set_edited_cells_values(values)


func _add_recent(value):
	for x in recent_container.get_children():
		if x.text == str(value):
			return

	var node := Button.new()
	node.text = str(value)
	node.self_modulate = Color(value.hash()) + Color(0.25, 0.25, 0.25, 1.0)
	node.connect("pressed", self, "_on_recent_clicked", [node, value])
	recent_container.add_child(node)


func _on_recent_clicked(button, value):
	var val = recent_container.get_child(1).selected
	value_input.text = str(value)
	if val == 0:
		_add_value(value)

	if val == 1:
		_remove_value(value)

	if val == 2:
		button.queue_free()


func _on_Remove_pressed():
	_remove_value(str2var(value_input.text))


func _on_ClearRecent_pressed():
	for i in recent_container.get_child_count():
		if i == 0: continue
		recent_container.get_child(i).free()
	

func _on_Float_pressed():
	_add_value(float(value_input.text))


func _on_Int_pressed():
	_add_value(int(value_input.text))


func _on_String_pressed():
	_add_value(value_input.text)
	_add_recent(value_input.text)


func _on_Variant_pressed():
	_add_value(str2var(value_input.text))


func _on_AddRecentFromSel_pressed():
	for x in sheet.get_edited_cells_values():
		for y in x:
			_add_recent(y)
