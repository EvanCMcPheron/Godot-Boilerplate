extends CellEditor


func can_edit_value(value, type, property_hint, column_index) -> bool:
	return type == TYPE_INT and property_hint == PROPERTY_HINT_ENUM


func set_value(node : Control, value):
	node.text = hint_strings_array[node.get_position_in_parent() % hint_strings_array.size()][value]
	node.self_modulate = Color(node.text.hash()) + Color(0.25, 0.25, 0.25, 1.0)
	node.align = Label.ALIGN_CENTER


func is_text():
	return false
