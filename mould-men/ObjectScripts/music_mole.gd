class_name MusicMole extends Mole

# BEHAVIOURS DESCRIPTION
#
# All behaviours of a Mole with the following changes:
# - RIGHT CLICK on the music mole will toggle the mole Playing Music
# - While Playing Music, the music mole has the following behavioural changes
#    ~ While in the MOVING state the music mole prioritizes moving towards the closest mole
#      and it has a speed boost
#    ~ When the music mole reaches a target of any kind in the MOVING state it transitions
#      to the GROOVING state instead of any other state
#
# GROOVING:
# - State becomes GROOVING when the music mole is Playing Music and it reaches a target
#   while in the MOVING state.
# - While in the GROOVING state, every mole within a certain radius gains a boost to movement
#   and attack speed (also applies to mining speed for the miner mole and healing speed for the
#   doctor mole)
# - When all allies leave the radius of the music mole, or the music mole stops Playing Music,
#   the music mole transitions to the MOVING state.

# Properties that track music playing
@export var _is_playing:		bool			= false
@export var _music_radius:		float			= 5.0
@export var _music_buff:		float			= 1.5
var 		_dance_direction:	float			= 1.0
var			_units_buffed:		Array[Mole]		= []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	# Instantiating parent first
	super._ready()

	# Moles are not enemies
	#_is_enemy							= false

	# Setting the mesh
	_mesh.mesh							= (load("res://Assets/MoleAssets/MusicMole/MusicMole.tres") as Mesh).duplicate()

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

		# Toggling music
		self._is_playing = !_is_playing

		# Giving buffs if the music is playing
		if _is_playing:
			self.increase_buff_val(self._music_buff)
			if _closest_op == null:
				_closest_op = closest_opponent(self)
			elif _closest_op.is_enemy():
				_closest_op = closest_opponent(self)

		else:
			self.decrease_buff_val(self._music_buff)

		_state		= Globals.STATES.MOVING

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

	# Running the standard mole process first
	super._process(delta)

	# Grooving state processing
	if _state == Globals.STATES.GROOVING:
		grooving(delta)

	# No one should be grooving if the music mole is not grooving
	elif _state != Globals.STATES.GROOVING and _units_buffed.size() > 0:
		for ally in _units_buffed:
			ally.decrease_buff_val(_music_buff)
		_units_buffed.clear()

# Called to handle the grooving action
func grooving(delta: float) -> void:

	# Performing a grooving animation
	grooving_animation(delta)

	# Checking to see if each ally should be buffed
	for ally in Globals.ALLY_ARR:

		# Only buff moles
		if ally is Mole and ally != self:

			# If the ally is within range and is not buffed already then do so
			if ally.get_global_pos().distance_to(self.get_global_pos()) <= _music_radius and !_units_buffed.has(ally):

				# Adding the buff then adding them to the list of beneficiaries
				ally.increase_buff_val(_music_buff)
				_units_buffed.push_back(ally)

			# If an ally leaves range remove the buff
			if ally.get_global_pos().distance_to(self.get_global_pos()) > _music_radius and _units_buffed.has(ally):

				# Removing the ally as a beneficiary
				ally.decrease_buff_val(_music_buff)
				_units_buffed.erase(ally)

				# If for some reason the value is below what it should be reset it
				if ally.get_buff_val() < 1.0:
					ally.reset_buf_val()

	# If there is no one to groove with the mole it moves again
	if _units_buffed.size() == 0:
		_state = Globals.STATES.MOVING

# A basic mining animation handler
func grooving_animation(delta: float) -> void:
	_mesh.rotate_z(_dance_direction * delta)
	if _mesh.rotation.z > deg_to_rad(25) or _mesh.rotation.z < deg_to_rad(-25):
		_dance_direction *= -1.0

# Getter for if the music is playing
func is_playing() -> bool:
	return _is_playing

# Called when movement is finished
func nav_finish() -> void:

	# If the mole is playing music when it reaches a target then keep grooving
	if self.is_playing():
		_state		= Globals.STATES.GROOVING

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
	if unit is MusicMole:
		if unit.is_playing():
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
