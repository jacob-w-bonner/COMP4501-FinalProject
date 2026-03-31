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
	
	# Change visibility layer of all meshes so they're NOT visible on layer 1 and ARE visible on layer 2
	# Layer 1 will contain everything visible in the minimap
	# (this is because the gridmap is on layer 1 by default and i don't think its layer can be changed)
	_mesh.set_layer_mask_value(1, false)
	# Layer 2 will contain everything visible in the "player" camera
	_mesh.set_layer_mask_value(2, true)

	# Enabling mouse detection
	_physics_body.input_ray_pickable	= true
	_physics_body.connect("mouse_entered", Callable(self, "start_hover"))
	_physics_body.connect("mouse_exited", Callable(self, "stop_hover"))
	
	# Set minimap icon
	_minimap_icon = Sprite3D.new()
	if _minimap_icon_texture:
		_minimap_icon.texture = _minimap_icon_texture
		_physics_body.add_child(_minimap_icon)
		_minimap_icon.position = Vector3(0, 7.0, 0) # height above mole
		_minimap_icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED

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
