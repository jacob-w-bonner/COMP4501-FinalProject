extends Camera3D

@export var base: Base = null

# Called when the node enters the scene tree for the first time.
func _ready():
	self.global_position =  Vector3(base.global_position.x, self.global_position.y, base.global_position.z)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
