@abstract
class_name StaticUnit extends Unit

# Properties all static units have
var _level: int = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	# Instantiating parent first
	super._ready()

	# Instantiating a static body
	_physics_body						= StaticBody3D.new()
	self.add_child(_physics_body)

	# Instantiating mesh
	_mesh								= MeshInstance3D.new()
	_physics_body.add_child(_mesh)

	# Enabling mouse detection
	_physics_body.input_ray_pickable	= true
	_physics_body.connect("mouse_entered", Callable(self, "start_hover"))
	_physics_body.connect("mouse_exited", Callable(self, "stop_hover"))

# Called to handle input events
func _input(event: InputEvent) -> void:

	# Differing to unit input
	super._input(event)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Setter for the level
func set_level(new_level: int) -> void:
	_level = new_level

# Getter for the level
func get_level() -> int:
	return _level

# Called to level up the unit
func level_up() -> int:
	_level += 1
	return _level
