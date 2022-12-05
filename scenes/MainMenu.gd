extends State

var main_menu_packed := preload("res://scenes/MainMenu/MainMenu.tscn")
var main_menu

onready var scene_handler := $"../.."

func _enter_state(from) -> void:
	if from != null:
		if from.name == "Game":
			_add_main_menu()
	else:
		_add_main_menu()

func _add_main_menu() -> void:
	main_menu = main_menu_packed.instance()
	scene_handler.call_deferred("add_child", main_menu)
	main_menu.get_node("MarginContainer/VBoxContainer/Play").connect("button_down", $"..", "change_state_by_name", ["Game"])

func _exit_state(to) -> void:
	main_menu.queue_free()
	if to != null:
		yield(get_tree().create_timer(0.0), "timeout")
