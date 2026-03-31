class_name DoctorMole extends Mole

# BEHAVIOURS DESCRIPTION
#
# All behaviours of a Mole with the following changes:
# - RIGHT CLICK on the doctor mole will toggle the mole Healing
# - While Healing, the doctor mole has the following behavioural changes
#    ~ While in the MOVING state the doctor mole prioritizes moving towards the closest mole
#      and it regenerates health over time
#    ~ When the doctor mole reaches a target of any kind in the MOVING state it transitions
#      to the HEALING state instead of any other state
#
# HEALING:
# - State becomes HEALING when the doctor mole is Healing and it reaches a target
#   while in the MOVING state.
# - While in the HEALING state, every mole within a certain radius gains healing over time
# - When all allies leave the radius of the doctor mole, or the doctor mole stops Healing,
#   the doctor mole transitions to the MOVING state.

# Properties that healing
@export var _is_healing:		bool			= false
@export var _healing_radius:	float			= 5.0
@export var _healing_strength:	int				= 5.0
const		_HEALING_DURATION:	float			= 2.0
var			_healing_time:		float			= 0.0
var			_dealt_healing:		bool			= false
var			_units_healed:		Array[Mole]		= []

# Properties that track self regeneration
const		_REGEN_DURATION:	float			= 2.0
var			_regen_time:		float			= 0.0
var			_dealt_regen:		bool			= false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	# Instantiating parent first
	super._ready()

	# Moles are not enemies
	_is_enemy							= false

	# Setting the mesh
	_mesh.mesh							= (load("res://Assets/MoleAssets/DoctorMole/DoctorMole.tres") as Mesh).duplicate()

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

# Called to handle input events
func _input(event: InputEvent) -> void:

	# Checking all mole click events first
	super._input(event)

	# Checking for right mouse click
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and self._is_hovered:

		# Toggling healing
		self._is_healing = !_is_healing

		# Giving healing if casting
		if _is_healing:
			_regen_time = 0.0
			self.set_is_healing(true)
			if _closest_op == null:
				_closest_op = closest_opponent(self)
			elif _closest_op.is_enemy():
				_closest_op = closest_opponent(self)
		else:
			self.set_is_healing(false)

		_state		= Globals.STATES.MOVING

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

	# Running the standard mole process first
	super._process(delta)

	# If healing has been toggled apply passive health regeneration
	if _is_healing:

		# Resetting the heal timer if it is maxed out
		if _regen_time > _HEALING_DURATION / _buff_val:
			_dealt_regen	= false
			_regen_time		= 0.0

		# Adding to the current cast time
		_regen_time += delta

		# If it is the correct time apply regeneration
		if _regen_time > _REGEN_DURATION / _buff_val / 2.0 and !_dealt_regen:
			self.receive_healing(_healing_strength)
			_dealt_regen = true

	# Healing state processing
	if _state == Globals.STATES.HEALING:
		healing(delta)

	# No one should be receiving healing if the mole is not casting
	elif _state != Globals.STATES.HEALING and _units_healed.size() > 0:
		for ally in _units_healed:
			ally.set_is_healing(false)
		_units_healed.clear()

# Called to handle the healing action
func healing(delta: float) -> void:

	# Performing a healing animation
	healing_animation(delta)

	# Resetting the heal timer if it is maxed out
	if _healing_time > _HEALING_DURATION / _buff_val:
		_dealt_healing	= false
		_healing_time	= 0.0

	# Adding to the current cast time
	_healing_time += delta

	# Checking to see if each ally should be buffed
	for ally in Globals.ALLY_ARR:

		# Only buff moles
		if ally is Mole and ally != self:

			# If the ally is within range and is not buffed already then do so
			if ally.get_global_pos().distance_to(self.get_global_pos()) <= _healing_radius and !_units_healed.has(ally):

				# Adding healing then adding them to the list of beneficiaries
				ally.set_is_healing(true)
				_units_healed.push_back(ally)

			# If an ally leaves range remove the buff
			if ally.get_global_pos().distance_to(self.get_global_pos()) > _healing_radius and _units_healed.has(ally):

				# Removing the ally as a beneficiary
				ally.set_is_healing(false)
				_units_healed.erase(ally)

			# If the ally is in the healing list at the correct time apply healing
			if _healing_time > _HEALING_DURATION / _buff_val / 2.0 and !_dealt_healing and _units_healed.has(ally):
				ally.receive_healing(_healing_strength)

	# Making sure healing occurs only once in the time frame
	if _healing_time > _HEALING_DURATION / _buff_val / 2.0:
		_dealt_healing = true

	# If there is no one to groove with the mole it moves again
	if _units_healed.size() == 0:
		_state = Globals.STATES.MOVING

# A basic healing animation handler
func healing_animation(delta: float) -> void:
	_mesh.set_rotation(Vector3(cos(Globals.TIME * _speed) * 0.5, _mesh.rotation.y, sin(Globals.TIME * _speed) * 0.5))

# Getter for if the music is playing
func is_healing() -> bool:
	return _is_healing

# Called when movement is finished
func nav_finish() -> void:

	# If the mole is playing music when it reaches a target then keep healing
	if self.is_healing():
		_state		= Globals.STATES.HEALING

	# If the closest target is an enemy then attack it
	elif _closest_op.is_enemy():
		_state		= Globals.STATES.ATTACKING

	# Move towards the closest target
	else:
		_closest_op = closest_opponent(self)
		_state		= Globals.STATES.MOVING

# Called to determine the closest opposing unit to the given position
func closest_opponent(unit: Unit) -> Unit:

	# Values that will contain the closest enemy position and distance
	var closest_pos  = Vector3(10000.0, 10000.0, 10000.0)
	var closest_dist = 10000.0
	var closest_unit = null

	# Do not accept null units
	if unit.is_queued_for_deletion() or !is_instance_valid(unit):
		return null

	# If the unit is a music mole and playing music then travel to an ally instead
	if unit is DoctorMole:
		if unit.is_healing():
			for ally in Globals.ALLY_ARR:
				var distance = ally.get_global_pos().distance_to(unit.get_global_pos())
				if distance < closest_dist and ally is Mole and ally != self:
					closest_pos  = ally.get_global_pos()
					closest_dist = distance
					closest_unit = ally

		# If a resource vein in range was found go mine it
		if closest_unit != null:
			return closest_unit

	return super.closest_opponent(self)
