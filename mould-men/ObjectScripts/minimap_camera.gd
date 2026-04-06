extends Camera3D

@onready var main_cam: Camera3D = get_tree().root.get_node("TestScene/Camera3D")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#TODO Simple fix for left to right maps, if maps become more vertical will need to change to smth slightly more robust
	self.position.x = main_cam.position.x
