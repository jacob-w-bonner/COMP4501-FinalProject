extends Control

var offset: Vector2 = Vector2(0.0, -130.0)

func _process(_delta: float) -> void:
	global_position = get_global_mouse_position() + offset
