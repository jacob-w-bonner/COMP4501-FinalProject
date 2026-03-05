@abstract
class_name DynamicUnit extends Unit

# Properties that all dynamic units have
@export var _speed: 			int 				= 1.0
@export var _attack_strength:	int 				= 10.0
var			_velocity:			Vector3				= Vector3.ZERO

# Properties that track attacking
const		_ATTACK_DURATION:	float				= 1.0
var			_attack_time:		float				= 0.0
var			_damage_dealt:		bool				= false
var 		_attack_direction:	float				= 10.0

# The current target of the unit
@onready var _closest_op: 		Unit				= null

# Navigation agent to help with movement around walled areas
var _nav_agent:					NavigationAgent3D	= null

# The radius at which the unit can take certain actions
var _reach_radius:				float				= 2.5
var _sentry_radius:				float				= 8.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	# Instantiating parent first
	super._ready()

	# Instantiating a character body
	_physics_body 							= CharacterBody3D.new()
	self.add_child(_physics_body)

	# Instantiating mesh
	_mesh									= MeshInstance3D.new()
	_physics_body.add_child(_mesh)

	# Enabling mouse detection
	_physics_body.input_ray_pickable		= true
	_physics_body.connect("mouse_entered", Callable(self, "start_hover"))
	_physics_body.connect("mouse_exited", Callable(self, "stop_hover"))

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
	_nav_agent.target_desired_distance		= 2.5
	_nav_agent.path_desired_distance		= 0.5
	_nav_agent.debug_enabled 				= true

# Called to handle input events
func _input(event: InputEvent) -> void:

	# Differing to unit input
	super._input(event)

# Called to move the unit to a location
func move(target: Unit) -> void:

	# If there is nowhere to go remain idle
	if target == null:
		_velocity			= Vector3(0.0, 0.0, 0.0)
		_nav_agent.velocity	= _velocity
		_state				= Globals.STATES.SENTRY
		return

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

# Called to attack a closeby target
func attack(target: Unit, delta: float) -> void:

	# If there is no unit to attack return early
	if target.is_queued_for_deletion():
		_damage_dealt	= false
		_attack_time	= 0.0
		_state			= Globals.STATES.MOVING
		return

	# If the current target is out of range then move towards it 
	if self.get_global_pos().distance_to(target.get_global_pos()) > _reach_radius:
		_damage_dealt					= false
		_attack_time					= 0.0
		_mesh.global_transform.basis 	= _physics_body.global_transform.basis
		_mesh.position					= Vector3.ZERO
		_state							= Globals.STATES.MOVING
		return

	# Resetting the attack if it is maxed out
	if _attack_time > _ATTACK_DURATION:
		_damage_dealt	= false
		_attack_time	= 0.0

	# Adding to the current cast time
	_attack_time += delta

	# Deal damage to the target after a quarter of the time
	if _attack_time > _ATTACK_DURATION / 4.0 and !_damage_dealt:
		target.take_damage(_attack_strength)
		_damage_dealt = true

	# Handling a basic attack animation
	hit_animation(delta)

# Called to handle the sentry action
func sentry() -> void:

	# Potential opponent
	var opponent = closest_opponent(self)

	# If there are no opponents return
	if opponent == null:
		return

	# If the opponent is within your sentry radius move towards it
	if self.get_global_pos().distance_to(opponent.get_global_pos()) <= _sentry_radius:
		_closest_op = opponent
		_state		= Globals.STATES.MOVING

# Called when movement is finished
func nav_finish() -> void:

	# If the closest target is an enemy then attack it
	if _closest_op.is_enemy():
		_state = Globals.STATES.ATTACKING

	# Move towards the closest target
	else:
		_closest_op = closest_opponent(self)
		_state		= Globals.STATES.MOVING

# A basic hitting animation handler
func hit_animation(delta: float) -> void:
	_mesh.rotate_y(_attack_direction * delta)
	if _mesh.rotation.y > deg_to_rad(45) or _mesh.rotation.y < deg_to_rad(-45):
		_attack_direction *= -1.0

# Called to adjust the velocity to account for other moving objects
func adjust_velocity(adj_vel: Vector3) -> void:

	# Setting the adjusted velocity
	_velocity = adj_vel

	# Apply the velocity
	_physics_body.velocity.x		= _velocity.x
	_physics_body.velocity.z		= _velocity.z
	_physics_body.move_and_slide()
