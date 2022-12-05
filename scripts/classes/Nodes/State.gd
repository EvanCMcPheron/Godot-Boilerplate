class_name State
extends Node

func _enter_state(from: State) -> void:
	pass


func _exit_state(to: State) -> void:
	if to != null:
		yield(get_tree().create_timer(0.0), "timeout")


func _update_state(delta: float) -> void:
	pass
