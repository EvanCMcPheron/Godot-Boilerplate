tool
class_name CollisionCircleTool
extends CollisionPolygon2D

export var radius: float = 101 setget radius_set
export var resolution: int = 100 setget resolution_set


func _ready():
	_update_poly()


func _update_poly() -> void:
	var new_polygon := PoolVector2Array([])
	for i in range(resolution + 1):
		var new_v := Vector2.ZERO
		var theta: float = i * (2 * PI / resolution)
		new_v.x = radius * cos(theta)
		new_v.y = radius * sin(theta)
		new_polygon.append(new_v)
	polygon = new_polygon


func radius_set(value: float) -> void:
	radius = value
	_update_poly()


func resolution_set(value: int) -> void:
	resolution = value
	_update_poly()
