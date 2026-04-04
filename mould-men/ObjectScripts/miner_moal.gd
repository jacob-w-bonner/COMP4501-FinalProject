class_name MinerMole extends Mole

# BEHAVIOURS DESCRIPTION
#
# All behaviours of a Mole with the following changes:
# - When choosing a target for the MOVING state, the miner mole will prioritize moving towards 
#   ResourceVeins instead of enemies
#
# MINING:
# - State becomes MINING if the miner mole reaches a ResourceVein in the MOVING state
# - While in the MINING state, the miner mole extracts resources from the ResourceVein
#   (adding to the player's resources tracked in Globals over time)
# - When a ResourceVein runs out of resources or health, it is destroyed and the miner mole
#   transitions to the MOVING state

# Properties that track mining
@export var _mining_efficiency:	int 				= 10
const		_MINING_DURATION:	float				= 2.0
var			_mining_time:		float				= 0.0
var			_already_mined:		bool				= false
var 		_mining_direction:	float				= 10.0

# UI labels to be updated
@onready var gold_label: RichTextLabel = $"../GUI/Resources + Minimap/Resources/GridContainer/MarginContainer/MarginContainer/HBoxContainer/GoldLabel"
@onready var coal_label: RichTextLabel = $"../GUI/Resources + Minimap/Resources/GridContainer/MarginContainer2/MarginContainer/HBoxContainer/CoalLabel"
@onready var amethyst_label: RichTextLabel = $"../GUI/Resources + Minimap/Resources/GridContainer/MarginContainer3/MarginContainer/HBoxContainer/AmethystLabel"
@onready var diamond_label: RichTextLabel = $"../GUI/Resources + Minimap/Resources/GridContainer/MarginContainer4/MarginContainer/HBoxContainer/DiamondLabel"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	# Instantiating parent first
	super._ready()

	# Moles are not enemies
	_is_enemy							= false

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
	
	var headlamp = OmniLight3D.new()
	headlamp.position = Vector3(0.0, 3.0, 3.0)
	headlamp.omni_range = 2.02
	headlamp.light_specular = 1.67
	headlamp.shadow_enabled = false
	_mesh.add_child(headlamp)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

	# Running the standard mole process first
	super._process(delta)

	# Mine state processing
	if _state == Globals.STATES.MINE:

		# If the target is invalid select a new one
		if !is_instance_valid(_closest_op):
			_state = Globals.STATES.MOVING
			_mesh.global_transform.basis 	= _physics_body.global_transform.basis
			_mesh.position					= Vector3.ZERO
			return

		# If there is no target to mine then try to find a new one
		if _closest_op.is_queued_for_deletion() or _closest_op == null or _closest_op is not ResourceVein:
			_mesh.global_transform.basis 	= _physics_body.global_transform.basis
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

		# Calculating the direction the target is facing
		var direction					= self._closest_op._physics_body.global_transform.origin - self._physics_body.global_transform.origin
		direction.y						= 0
		direction 						= direction.normalized()

		# Setting the object rotation
		self._physics_body.rotation.y	= atan2(direction.x, direction.z)

		# Changing states
		_state							= Globals.STATES.ATTACKING

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
		_mesh.global_transform.basis 	= _physics_body.global_transform.basis
		_mesh.position					= Vector3.ZERO
		_state							= Globals.STATES.MOVING
		return

	# Resetting the mine if it is maxed out
	if _mining_time > _MINING_DURATION / _buff_val:
		_already_mined	= false
		_mining_time	= 0.0

	# Adding to the current cast time
	_mining_time += delta

	# Deal damage to the target after a quarter of the time
	if _mining_time > 3.0 * _MINING_DURATION / _buff_val / 4.0 and !_already_mined:
		var retrieved = target.deplete_resource(_mining_efficiency)
		_already_mined = true

		# Incrementing whatever resource was retrieved
		match target.get_resource_type():

			# Coal was retrieved
			Globals.RESOURCES.COAL:
				Globals.COAL_NUM += retrieved
				coal_label.text = str(Globals.COAL_NUM)

			# Gold was retrieved
			Globals.RESOURCES.GOLD:
				Globals.GOLD_NUM += retrieved
				gold_label.text = str(Globals.GOAL_NUM)

			# Diamond was retrieved
			Globals.RESOURCES.DIAMOND:
				Globals.DIAMOND_NUM += retrieved
				diamond_label.text = str(Globals.DIAMOND_NUM)

			# Amethyst was retrieved
			Globals.RESOURCES.AMETHYST:
				Globals.AMETHYST_NUM += retrieved
				amethyst_label.text = str(Globals.AMETHYST_NUM)

	# Handling a basic mining animation
	mine_animation(delta)

# A basic mining animation handler
func mine_animation(delta: float) -> void:
	_mesh.rotate_x(_mining_direction * delta * _buff_val)
	if _mesh.rotation.x > deg_to_rad(45) or _mesh.rotation.x < deg_to_rad(-45):
		_mining_direction *= -1.0

# Called to determine the closest opposing unit to the given position
func closest_opponent(unit: Unit) -> Unit:

	# Values that will contain the closest enemy position and distance
	var closest_pos  = Vector3(10000.0, 10000.0, 10000.0)
	var closest_dist = 10000.0
	var closest_unit = null

	# Do not accept null units
	if unit.is_queued_for_deletion() or !is_instance_valid(unit):
		return null

	# If the unit is a miner mole then prioritize finding resources
	if unit is MinerMole:
		for ally in Globals.ALLY_ARR:
			var distance = ally.get_global_pos().distance_to(unit.get_global_pos())
			if distance < closest_dist and ally is ResourceVein:
				closest_pos  = ally.get_global_pos()
				closest_dist = distance
				closest_unit = ally

		# If a resource vein in range was found go mine it
		if closest_unit != null:
			return closest_unit

	return super.closest_opponent(self)
