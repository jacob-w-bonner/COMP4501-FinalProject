class_name Prospector extends DynamicUnit

# Text over prospector variables 
var _action_text: Label3D
var _action_text_timer: float = 0.0
var _previous_state = -1

# Shader for the prospector
@onready var _shader:			Shader		= preload("res://Shaders/prospector.gdshader")

# Rotation factor for the hit animation
var 		_attack_anim_dir:	float		= 10.0

# Properties that track mending
const		_MENDING_DURATION:	float		= 1.0
var			_mending_time:		float		= 0.0
var			_mending_dealt:		bool		= false
var 		_mending_direction:	float		= 10.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	# Instantiating parent first
	super._ready()

	# Setting the scale
	self.scale = Vector3(0.4, 0.4, 0.4)

	# Action text for UI
	_action_text = Label3D.new()
	_action_text.text = ""
	_action_text.visible = false
	_action_text.font_size = 200
	_action_text.position = Vector3(0, 5.0, 0) # height above prospector
	_action_text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_action_text.outline_size = 50
	_physics_body.add_child(_action_text)
	
	# Change visibility layer of action label so it's NOT visible on layer 1 and IS visible on layer 2
	# Layer 1 will contain everything visible in the minimap
	# (this is because the gridmap is on layer 1 by default and i don't think its layer can be changed)
	_action_text.set_layer_mask_value(1, false)
	# Layer 2 will contain everything visible in the "player" camera
	_action_text.set_layer_mask_value(2, true)

	# Setting that the unit is an enemy
	_is_enemy							= true

	# Setting the mesh
	_mesh.mesh							= (load("res://Assets/ArKaickAssets/Prospector/Prospector.tres") as Mesh).duplicate()

	# Instantiating the collision shape
	_collision_shape					= CollisionShape3D.new()
	_physics_body.add_child(_collision_shape)

	# Finding the size of the collision box
	var bounding_box					= _mesh.mesh.get_aabb()
	var box_size						= bounding_box.size

	# Creating a collision box for the object
	var box_shape						= BoxShape3D.new()
	box_shape.size						= box_size

	# Setting the collision box
	_collision_shape.shape				= box_shape
	_collision_shape.position 			= bounding_box.get_center()

	# Resetting the buff indicator mesh
	_buff_mesh.mesh						= (load("res://Assets/ArKaickAssets/EffectIndicators/Exclamation.tres") as Mesh).duplicate()
	_buff_mesh.scale					= Vector3(0.5, 0.5, 0.5)
	_buff_mesh.position					= Vector3(0.0, 8.0, 0.0)
	_buff_mesh.visible					= false
	_buff_height						= 8.0
	
	# Setting health higher
	_max_health							= 120
	_health								= _max_health

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
			shader_mat.set_shader_parameter("tex_col", standard_mat.albedo_color)
			_mesh.mesh.surface_set_material(i, shader_mat)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

	# Counting down to when the text should disappear
	if _action_text_timer > 0:
		_action_text_timer -= delta

	# Removing the action text
	if _action_text_timer <= 0:
		_action_text.visible = false
		
	# Detect state changes
	if _state != _previous_state:

		# If a previous action was being taken reset the mesh
		_mesh.global_transform.basis 	= _physics_body.global_transform.basis

		# Display new state
		_on_state_changed(_state)
		_previous_state = _state

	# If the target is buffed run the animation
	if _buff_val > 1.0:
		self.buff_animation(delta)

	# If the target is being healed run the animation
	if _is_receiving_healing:
		self.heal_animation(delta)

	# Check first to make sure a target exists
	if _closest_op != null:
		if _closest_op.is_queued_for_deletion():
			_closest_op = null

	# Setting the shader parameters that need to be set by frame
	for i in range(_mesh.mesh.get_surface_count()):

		# Sending the hover value
		_mesh.mesh.surface_get_material(i).set_shader_parameter("is_hovered", _is_hovered)

		# Send health percentage to affect colouring
		_mesh.mesh.surface_get_material(i).set_shader_parameter("health_percent", 1.0 - (float(_health) / float(_max_health)))

	# Basing the unit's actions off of its current state

	# Movement state processing
	if _state == Globals.STATES.MOVING:

		# Checking for the closest enemy to target if no target exists
		if _closest_op == null:
			_closest_op				    = closest_opponent(self)

		# Navigation setting
		else:
			_nav_agent.target_position  = _closest_op.get_global_pos()

		# Moving the prospector to its target location
		move(_closest_op)

		# If there is nowhere to go change state to sentry
		if _closest_op == null:
			_nav_agent.velocity = Vector3.ZERO
			_state				= Globals.STATES.SENTRY

	# Attack state processing
	if _state == Globals.STATES.ATTACKING:

		# If the target is invalid select a new one
		if !is_instance_valid(_closest_op):
			_state = Globals.STATES.MOVING
			_mesh.global_transform.basis 	= _physics_body.global_transform.basis
			_mesh.position					= Vector3.ZERO
			return

		# If there is no target to attack then try to find a new one
		if _closest_op.is_queued_for_deletion() or _closest_op == null:
			_mesh.global_transform.basis 	= _physics_body.global_transform.basis
			_mesh.position					= Vector3.ZERO
			_state							= Globals.STATES.MOVING
			return

		_nav_agent.velocity = Vector3.ZERO
		attack(_closest_op, delta)

	# Sentry state processing
	if _state == Globals.STATES.SENTRY:
		_closest_op			= null
		_nav_agent.velocity = Vector3.ZERO
		sentry()

	# Mending state processing
	if _state == Globals.STATES.MENDING:

		# If the target is invalid select a new one
		if !is_instance_valid(_closest_op):
			_state = Globals.STATES.MOVING
			_mesh.global_transform.basis 	= _physics_body.global_transform.basis
			_mesh.position					= Vector3.ZERO
			return

		# If there is no target to mend then try to find a new one
		if _closest_op.is_queued_for_deletion() or _closest_op == null or _closest_op is not StaticUnit:
			_mesh.global_transform.basis 	= _physics_body.global_transform.basis
			_mesh.position					= Vector3.ZERO
			_state							= Globals.STATES.MOVING
			return

		# If the target is at full health then choose another one
		if _closest_op.is_max_health():
			_mesh.global_transform.basis 	= _physics_body.global_transform.basis
			_mesh.position					= Vector3.ZERO
			_state							= Globals.STATES.MOVING
			return

		_nav_agent.velocity = Vector3.ZERO
		mend(_closest_op, delta)

# Called to mend a nearby structure
func mend(target: StaticUnit, delta: float) -> void:

	# If there is no unit to attack return early
	if target.is_queued_for_deletion():
		_mending_dealt	= false
		_mending_time	= 0.0
		_state			= Globals.STATES.MOVING
		return

	# If the current target is out of range then move towards it 
	if self.get_global_pos().distance_to(target.get_global_pos()) > _reach_radius:
		_mending_dealt					= false
		_mending_time					= 0.0
		_mesh.global_transform.basis 	= _physics_body.global_transform.basis
		_mesh.position					= Vector3.ZERO
		_state							= Globals.STATES.MOVING
		return

	# If the target is at full health then choose another one
	if _closest_op.is_max_health():
		_mesh.global_transform.basis 	= _physics_body.global_transform.basis
		_mesh.position					= Vector3.ZERO
		_state							= Globals.STATES.MOVING
		return

	# Resetting the attack if it is maxed out
	if _mending_time > _MENDING_DURATION / _buff_val:
		_mending_dealt	= false
		_mending_time	= 0.0

	# Adding to the current cast time
	_mending_time += delta

	# Deal damage to the target after a quarter of the time
	if _mending_time > _MENDING_DURATION / _buff_val / 4.0 and !_mending_dealt:
		target.receive_healing(_attack_strength)
		_mending_dealt = true

	# Handling a basic mending animation
	mending_animation(delta)

# Override to apply damage to the unit
func take_damage(damage_val: int) -> void:
	_health = _health - damage_val
	if _health <= 0:
		destroy_self()
	else:

		# Getting the closest opponent
		_closest_op						= super.closest_opponent(self)

		# Calculating the direction the target is facing
		var direction					= self._closest_op._physics_body.global_transform.origin - self._physics_body.global_transform.origin
		direction.y						= 0
		direction 						= direction.normalized()

		# Setting the object rotation
		self._physics_body.rotation.y	= atan2(direction.x, direction.z)

		# Changing states
		_state							= Globals.STATES.ATTACKING

# Override call to determine the closest opposing unit to the given position
func closest_opponent(unit: Unit) -> Unit:

	# Closest unit
	var closest_unit		   = null

	# Values that will contain the closest enemy position and distance
	var enemy_closest_distance = 10000.0
	var enemy_closest_unit	   = null

	# Values that will contain the closest ally position and distance
	var ally_closest_distance  = 10000.0
	var ally_closest_unit	   = null

	# Do not accept null units
	if unit.is_queued_for_deletion() or !is_instance_valid(unit):
		return null

	# First make sure that there are allies to track
	if Globals.ALLY_ARR.size() == 0:
		return null

	# Check the array for the closest ally
	for ally in Globals.ALLY_ARR:

		# Do not accept null units
		if !is_instance_valid(ally):
			continue

		# Do not accept self as an option
		if ally == self:
			continue

		var distance = ally.get_global_pos().distance_to(unit.get_global_pos())
		if distance < ally_closest_distance:
			ally_closest_distance 	= distance
			ally_closest_unit		= ally

	# Next check for closest enemy

	# First make sure that there are enemies to track
	if Globals.ENEMY_ARR.size() == 0:
		return null

	# Check the array for the closest enemy
	for enemy in Globals.ENEMY_ARR:

		# Do not accept null units
		if !is_instance_valid(enemy):
			continue

		# Do not accept self as an option
		if enemy == self or enemy is not StaticUnit:
			continue

		var distance = enemy.get_global_pos().distance_to(unit.get_global_pos())
		if distance < enemy_closest_distance:
			enemy_closest_distance = distance
			enemy_closest_unit	   = enemy

	# If the opponent is closer return the opponent
	if ally_closest_distance <= enemy_closest_distance:
		closest_unit = ally_closest_unit

	# If the closest unit is a full health enemy building or the opponent is in attack range return the opponent
	elif enemy_closest_unit != null:
		if enemy_closest_unit.is_max_health() or ally_closest_unit.get_global_pos().distance_to(self.get_global_pos()) <= 10.0:
			closest_unit = ally_closest_unit

		# Otherwise return the building
		else:
			closest_unit = enemy_closest_unit

	return closest_unit

# Overrided call for when movement is finished
func nav_finish() -> void:

	# Calculating the direction the target is facing
	var direction					= self._closest_op._physics_body.global_transform.origin - self._physics_body.global_transform.origin
	direction.y						= 0
	direction 						= direction.normalized()

	# If the closest target is an enemy building that is below full health then mend it
	if _closest_op is StaticUnit and _closest_op.is_enemy() and !_closest_op.is_max_health():

		# Setting the object rotation
		self._physics_body.rotation.y	= atan2(direction.x, direction.z)

		# Changing states
		_state							= Globals.STATES.MENDING

	# If the closest target is a mole or mole building then attack it
	elif !_closest_op.is_enemy():

		# Setting the object rotation
		self._physics_body.rotation.y	= atan2(direction.x, direction.z)

		# Changing states
		_state							= Globals.STATES.ATTACKING

	# Move towards the closest target
	else:
		_closest_op = closest_opponent(self)
		_state		= Globals.STATES.MOVING

# An override of the hit animation
func hit_animation(delta: float) -> void:
	_mesh.rotate_x(_attack_anim_dir * delta)
	if _mesh.rotation.x > deg_to_rad(45) or _mesh.rotation.x < deg_to_rad(-45):
		_attack_anim_dir *= -1.0

# A basic mending animation handler
func mending_animation(delta: float) -> void:
	var angle = pingpong(Globals.TIME * _speed * 3.0 * _buff_val, PI)
	_mesh.set_rotation(Vector3(sin(angle) * 0.5, _mesh.rotation.y, cos(angle) * 0.5))

# Override called to destroy the unit
func destroy_self() -> void:
	super.destroy_self()

# Called to display the action text
func show_action_text(text: String, color: Color):
	_action_text.text = text
	_action_text.modulate = color
	_action_text.visible = true
	_action_text_timer = 1.5

# Called to display action text based on state change
func _on_state_changed(new_state):
	match new_state:
		Globals.STATES.MOVING:
			show_action_text("Moving", Color(0,1,0))

		Globals.STATES.ATTACKING:
			show_action_text("Attacking", Color(1,0,0))

		Globals.STATES.SENTRY:
			show_action_text("Sentry", Color(1,1,0))

		Globals.STATES.MENDING:
			show_action_text("Mending", Color(0.711, 0.129, 0.968, 1.0))

		Globals.STATES.RALLYING:
			show_action_text("Rallying", Color(1.0, 0.405, 0.028, 1.0))
