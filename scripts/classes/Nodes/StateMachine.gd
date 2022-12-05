class_name StateMachine
extends Node

export var default_node: String

onready var state: State setget change_state


func _ready() -> void:
	state = get_node(default_node)
	state._enter_state(null)


func _process(delta: float) -> void:
	state._update_state(delta)


func change_state(new_state: State) -> void:
	# If line 24 is giving error, make sure exit state ends with 
	#if to != null:
	#	yield(get_tree().create_timer(0.0), "timeout")
	yield(state._exit_state(new_state), "completed")
	var old_state = state
	state = new_state
	state._enter_state(old_state)

func change_state_by_name(name: String) -> void:
	change_state(get_node(name))


func _exit_tree():
	state._exit_state(null)
