extends Camera3D

@onready var main_cam: Camera3D = get_tree().root.get_node("TestScene/Camera3D")

func _process(_delta):
	self.position.x = main_cam.position.x
	self.position.z = main_cam.position.z
