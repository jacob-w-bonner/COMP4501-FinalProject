class_name MinerMole extends Mole

# Properties that track mining
@export var _mining_efficiency:	int 				= 10
const		_MINING_DURATION:	float				= 2.0
var			_mining_time:		float				= 0.0
var			_already_mined:		bool				= false
var 		_mining_direction:	float				= 10.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	# Instantiating parent first
	super._ready()

	# Moles are not enemies
	#_is_enemy							= false

	# Setting the mesh
	_mesh.mesh							= (load("res://Assets/MoleAssets/MinerMole/MinerMole.tres") as Mesh).duplicate()

	# Grabbing the material from each surface for use in the shader
	for i in range(_mesh.mesh.get_surface_count()):

		# Getting the standard material from the surface
		var standard_mat 	= _mesh.mesh.surface_get_material(i)

		# Only transform if what was retrieved is a standard material
		if standard_mat is StandardMaterial3D:

			# Initializing shader material for the mesh
			var shader_mat		= ShaderMaterial.new()
			shader_mat.shader 	= _shader

			# Setting the shader surface colour to the old material
			shader_mat.set_shader_parameter("tex", standard_mat.albedo_texture)
			_mesh.mesh.surface_set_material(i, shader_mat)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

	# Running the standard mole process first
	super._process(delta)

	# Mine state processing
	if _state == Globals.STATES.MINE:

		# If the target is invalid select a new one
		if !is_instance_valid(_closest_op):
			_state = Globals.STATES.MOVING
			_mesh.global_transform.basis 	= self.global_transform.basis
			_mesh.position					= Vector3.ZERO
			return

		# If there is no target to mine then try to find a new one
		if _closest_op.is_queued_for_deletion() or _closest_op == null or _closest_op is not ResourceVein:
			_mesh.global_transform.basis 	= self.global_transform.basis
			_mesh.position					= Vector3.ZERO
			_state							= Globals.STATES.MOVING
			return

		_nav_agent.velocity = Vector3.ZERO
		mine(_closest_op, delta)

# Called when movement is finished
func nav_finish() -> void:

	# If the closest target is a resource then mine it
	if _closest_op is ResourceVein:
		_state = Globals.STATES.MINE

	# If the closest target is an enemy then attack it
	elif _closest_op.is_enemy():
		_state = Globals.STATES.ATTACKING

	# Move towards the closest target
	else:
		_closest_op = closest_opponent(self)
		_state		= Globals.STATES.MOVING

# Called to handle the mine action
func mine(target: ResourceVein, delta: float) -> void:

	# If there is no unit to mine return early
	if target.is_queued_for_deletion():
		_already_mined	= false
		_mining_time	= 0.0
		_state			= Globals.STATES.MOVING
		return

	# If the current target is out of range then move towards it 
	if self.get_global_pos().distance_to(target.get_global_pos()) > _reach_radius:
		_already_mined					= false
		_mining_time					= 0.0
		_mesh.global_transform.basis 	= self.global_transform.basis
		_mesh.position					= Vector3.ZERO
		_state							= Globals.STATES.MOVING
		return

	# Resetting the mine if it is maxed out
	if _mining_time > _MINING_DURATION * (_buff_val if _is_buffed else 1.0):
		_already_mined	= false
		_mining_time	= 0.0

	# Adding to the current cast time
	_mining_time += delta

	# Deal damage to the target after a quarter of the time
	if _mining_time > 3.0 * _MINING_DURATION / (_buff_val if _is_buffed else 1.0) / 4.0 and !_already_mined:
		var retrieved = target.deplete_resource(_mining_efficiency)
		_already_mined = true

		# Incrementing whatever resource was retrieved
		match target.get_resource_type():

			# Coal was retrieved
			Globals.RESOURCES.COAL:
				Globals.COAL_NUM += retrieved

			# Gold was retrieved
			Globals.RESOURCES.GOLD:
				Globals.GOLD_NUM += retrieved

			# Diamond was retrieved
			Globals.RESOURCES.DIAMOND:
				Globals.DIAMOND_NUM += retrieved

			# Amethyst was retrieved
			Globals.RESOURCES.AMETHYST:
				Globals.AMETHYST_NUM += retrieved

	# Handling a basic mining animation
	mine_animation(delta)

# A basic mining animation handler
func mine_animation(delta: float) -> void:
	_mesh.rotate_x(_mining_direction * delta)
	if _mesh.rotation.x > deg_to_rad(45) or _mesh.rotation.x < deg_to_rad(-45):
		_mining_direction *= -1.0
