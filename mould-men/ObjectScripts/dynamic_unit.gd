@abstract
class_name DynamicUnit extends Unit

# Properties that all dynamic units have
@export var _speed: 			int 				= 1.0
@export var _attack_strength:	int 				= 1.0
var			_velocity:			Vector3				= Vector3.ZERO

# The current target of the unit
@onready var _closest_op: 		Unit				= null

# Navigation agent to help with movement around walled areas
var _nav_agent:					NavigationAgent3D	= null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	# Instantiating parent first
	super._ready()

	# Instantiating a character body
	_physics_body 							= CharacterBody3D.new()
	self.add_child(_physics_body)

	# Instantiating the navigation agent
	_nav_agent 								= NavigationAgent3D.new()
	_physics_body.add_child(_nav_agent)

	# Connecting the navigation agent to a function to detect the end of a path
	_nav_agent.connect("target_reached", Callable(self, "nav_finish"))

	# Connecting the navigation agent to a function to adjust the velocity
	_nav_agent.connect("velocity_computed", Callable(self, "adjust_velocity"))
	_nav_agent.avoidance_enabled			= true
	_nav_agent.radius						= 1.0

	# Setting more path following parameters for tighter motion
	_nav_agent.target_desired_distance		= 4.0
	_nav_agent.path_desired_distance		= 0.5
	_nav_agent.debug_enabled 				= true

# Called to move the unit to a location
func move(target: Unit) -> void:

	# Next position to move to
	var next_pos					= _nav_agent.get_next_path_position()

	# Calculate direction of travel
	var direction					= (next_pos - _physics_body.global_transform.origin).normalized()
	_velocity						= direction * _speed

	# Calculating rotation so that unit is facing correct direction
	var rotation_vec				= Vector3(direction.x, 0, direction.z)
	var angle						= atan2(rotation_vec.x, rotation_vec.z)
	_physics_body.rotation.y		= lerp_angle(_physics_body.rotation.y, angle, _speed * 0.1)

	# Calculating a velocity to avoid collisions with other moving objects
	_nav_agent.velocity				= _velocity

	# Apply the velocity
	#_physics_body.velocity.x		= _velocity.x
	#_physics_body.velocity.z		= _velocity.z
	#_physics_body.move_and_slide()

# Called to recalculate movement position
func nav_finish() -> void:
	print("bruh")
	_state = Globals.STATES.IDLE

# Called to adjust the velocity to account for other moving objects
func adjust_velocity(adj_vel: Vector3) -> void:

	# Setting the adjusted velocity
	_velocity = adj_vel

	# Apply the velocity
	_physics_body.velocity.x		= _velocity.x
	_physics_body.velocity.z		= _velocity.z
	_physics_body.move_and_slide()
