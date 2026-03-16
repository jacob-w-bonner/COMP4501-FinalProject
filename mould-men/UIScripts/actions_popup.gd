extends PanelContainer

var offset = Vector2(15,15)

func _process(delta: float) -> void:
	global_position = get_global_mouse_position() + offset
