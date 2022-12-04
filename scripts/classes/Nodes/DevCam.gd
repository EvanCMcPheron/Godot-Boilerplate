extends Camera2D
class_name DevCam

var moving: bool = false
export(float) var movement_speed: float = 1.0
export(float) var zoom_speed: float = 1.25


func _unhandled_input(event) -> void:
	var mouse_input = event as InputEventMouseMotion
	var is_mouse_event: bool = event is InputEventMouseMotion
	if is_mouse_event and moving:
		position -= mouse_input.relative * movement_speed * zoom
	elif not is_mouse_event:  # the reason the mouse event condition is here is that I dont want to have redundant mouse motion events calling this block
		if event.is_action_pressed("DevMouseClick"):
			moving = true
		elif event.is_action_released("DevMouseClick"):
			moving = false
		elif event.is_action_pressed("DevMouseScrollUp"):
			zoom /= zoom_speed
		elif event.is_action_pressed("DevMouseScrollDown"):
			zoom *= zoom_speed
