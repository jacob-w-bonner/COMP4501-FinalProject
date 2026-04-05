@abstract
class_name StaticUnit extends Unit

# Properties all static units have
var _level: int = 1
var _nav_obs: NavigationObstacle3D

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
	
	#Avoidence obstacoledd
	_nav_obs								= NavigationObstacle3D.new()
	self.add_child(_nav_obs)
	_nav_obs.position = Vector3(0,0,0)
	_nav_obs.avoidance_enabled = true
	_nav_obs.radius = 1
	
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
	set_minimap_icon(self)

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

#A generic level up that may be overidden by a unit (or combined)
func handle_level_up() -> void:
	if _level == 2:
		#recieve a 20% max health boost, heal 20%, and then get a 15% attack boost
		var old_health = _max_health
		_max_health = ceil(_max_health * 1.20)
		receive_healing(_max_health-old_health)
		_attack_strength = ceil(_attack_strength * 1.15)
	elif _level == 3:
		#recieve a 30% max health boost, heal 30%, and then get a 20% attack boost
		var old_health = _max_health
		_max_health = ceil(_max_health * 1.30)
		receive_healing(_max_health-old_health)
		_attack_strength = ceil(_attack_strength * 1.20)
