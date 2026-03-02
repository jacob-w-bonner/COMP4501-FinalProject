class_name Mole extends DynamicUnit

# Constants common to moles
const _TUNNELING_COOLDOWN: 	float 	= 5.0

# Tracking the current tunnel cooldown and ability
var _curr_tunnel_cooldown: 	float 	= 0.0
var _can_tunnel:			bool	= true

# The radius at which the mole can take certain actions
var _reach_radius:			float	= 2.0
var _sentry_radius:			float	= 5.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	# Instantiating parent first
	super._ready()

	# Moles are not enemies
	_is_enemy					= false

	# Instantiating mesh
	_mesh						= MeshInstance3D.new()
	_physics_body.add_child(_mesh)

	# Setting the mesh
	_mesh.mesh					= load("res://Assets/MoleAssets/Mole/Mole.tres") as Mesh

	# Instantiating the collision shape
	_collision_shape			= CollisionShape3D.new()
	_physics_body.add_child(_collision_shape)

	# Finding the size of the collision box
	var bounding_box			= _mesh.mesh.get_aabb()
	var box_size				= bounding_box.size

	# Creating a collision box for the object
	var box_shape				= BoxShape3D.new()
	box_shape.size				= box_size

	# Setting the collision box
	_collision_shape.shape		= box_shape
	_collision_shape.position 	= bounding_box.get_center()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

	# Movement state processing
	if _state == Globals.STATES.MOVING:

		# Checking for the closest enemy to target if no target exists
		if _closest_op == null:
			_closest_op				   = Globals.closest_opponent(self)

		# Navigation setting
		else:
			_nav_agent.target_position = _closest_op.get_global_pos()

		# Moving the mole to its target location
		move(_closest_op)
