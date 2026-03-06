class_name Mole extends DynamicUnit

# Constants common to moles
const _BURROW_COOLDOWN: 	float 			= 5.0
const _BURROW_DISTANCE:		float			= 10.0
const _BURROW_TIME:			float			= 8.0

# Tracking burrowing properties
var _curr_burrow_cooldown: 	float 			= 0.0
var _can_burrow:			bool			= true
var _burrow_target:			Vector3			= Vector3(0.0, Globals.FLOOR_HEIGHT, 0.0)

# Shader for the mole
@onready var _shader:		Shader			= preload("res://Shaders/mole.gdshader")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	# Instantiating parent first
	super._ready()

	# Moles are not enemies
	#_is_enemy							= false

	# Setting the mesh
	_mesh.mesh							= (load("res://Assets/MoleAssets/Mole/Mole.tres") as Mesh).duplicate()

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

	# Checking all dynamic click events first
	super._input(event)

	# Checking for left mouse click
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:

		# If the unit is being hovered and there is nothing else selected then select the unit
		if self._is_hovered and Globals.SELECTED_UNIT == null and !self.is_enemy() and _state != Globals.STATES.BURROW and !Globals.SELECT_COOLDOWN:
			Globals.SELECTED_UNIT = self
			_is_selected		  = true
			print("%s: %d" % [Globals.SELECTED_UNIT.name, Globals.SELECTED_UNIT.get_state()])
			return

		# Deselect a unit
		elif self._is_hovered and Globals.SELECTED_UNIT == self and !self.is_enemy() and _state != Globals.STATES.BURROW and !Globals.SELECT_COOLDOWN:
			Globals.SELECTED_UNIT = null
			_is_selected		  = false
			return

		# Actions to consider if the unit has been selected
		if self == Globals.SELECTED_UNIT:

			# First check if an opponent has been clicked
			var opponent_arr = Globals.ALLY_ARR if self.is_enemy() else Globals.ENEMY_ARR
			for op in opponent_arr:
				if op.is_hovered():

					# We know that an opponent was clicked so go attack it
					_closest_op 			= op
					_state					= Globals.STATES.MOVING
					Globals.SELECTED_UNIT 	= null
					return

			# Now check if an ally was clicked
			var ally_arr = Globals.ALLY_ARR if !self.is_enemy() else Globals.ENEMY_ARR
			for ally in ally_arr:
				if ally.is_hovered():

					# We know that an ally was clicked so go towards it
					_closest_op 			= ally
					_state					= Globals.STATES.MOVING
					Globals.SELECTED_UNIT 	= null
					Globals.SELECT_COOLDOWN = true
					return

			# If the current unit is selected then check what location was clicked by raycasting
			var ray_from 	= _camera.project_ray_origin(event.position)
			var ray_to 		= ray_from + _camera.project_ray_normal(event.position) * 1000.0
			var space_state = get_world_3d().direct_space_state
			var ray_query 	= PhysicsRayQueryParameters3D.create(ray_from, ray_to)
			var result 		= space_state.intersect_ray(ray_query)

			# If the space clicked is a valid location then set the state to burrow
			if result:

				# If the location is out of bounds do not do anything
				if result.position.y > Globals.FLOOR_HEIGHT or result.position.distance_to(self.get_global_pos()) > _BURROW_DISTANCE or !_can_burrow:
					return

				# Burrowing to the position
				result.position.y		= Globals.FLOOR_HEIGHT
				_state					= Globals.STATES.BURROW
				_can_burrow				= false
				_burrow_target			= result.position
				#self.set_global_pos(result.position)
				Globals.SELECTED_UNIT 	= null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

	# Check first to make sure a target exists
	if _closest_op != null:
		if _closest_op.is_queued_for_deletion():
			_closest_op = null

	# Setting the shader parameters that need to be set by frame
	for i in range(_mesh.mesh.get_surface_count()):

		# Sending the hover value
		_mesh.mesh.surface_get_material(i).set_shader_parameter("is_hovered", _is_hovered)

		# If the object is being selected indicate so
		if Globals.SELECTED_UNIT == self:
			_mesh.mesh.surface_get_material(i).set_shader_parameter("is_selected", true)
		else:
			_mesh.mesh.surface_get_material(i).set_shader_parameter("is_selected", false)

		# Send health percentage to affect colouring
		_mesh.mesh.surface_get_material(i).set_shader_parameter("health_percent", 1.0 - (float(_health) / float(_max_health)))

	# Running the burrowing cooldown
	if !_can_burrow and _state != Globals.STATES.BURROW:
		_curr_burrow_cooldown += delta
		if _curr_burrow_cooldown > _BURROW_COOLDOWN:
			_can_burrow			  = true
			_curr_burrow_cooldown = 0.0

	# Basing the unit's actions off of its current state

	# Movement state processing
	if _state == Globals.STATES.MOVING:

		# Checking for the closest enemy to target if no target exists
		if _closest_op == null:
			_closest_op				   = closest_opponent(self)

		# Navigation setting
		else:
			_nav_agent.target_position = _closest_op.get_global_pos()

		# Moving the mole to its target location
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
			_mesh.global_transform.basis 	= self.global_transform.basis
			_mesh.position					= Vector3.ZERO
			return

		# If there is no target to attack then try to find a new one
		if _closest_op.is_queued_for_deletion() or _closest_op == null:
			_mesh.global_transform.basis 	= self.global_transform.basis
			_mesh.position					= Vector3.ZERO
			_state							= Globals.STATES.MOVING
			return

		_nav_agent.velocity = Vector3.ZERO
		attack(_closest_op, delta)

	# Burrow state processing
	if _state == Globals.STATES.BURROW:
		_closest_op			= null
		_nav_agent.velocity = Vector3.ZERO
		burrow(delta)

	# Sentry state processing
	if _state == Globals.STATES.SENTRY:
		_closest_op			= null
		_nav_agent.velocity = Vector3.ZERO
		sentry()

# Called to handle the burrow action
func burrow(delta: float):

	# Add to the cast time
	_curr_burrow_cooldown += delta

	# If the cast time has been met then start the cooldown
	if _curr_burrow_cooldown > _BURROW_TIME:
		_mesh.global_transform.basis 	= self.global_transform.basis
		_mesh.position					= Vector3.ZERO
		_mesh.rotate_y(-delta * 50.0)
		_curr_burrow_cooldown			= 0.0
		_burrow_target					= Vector3(0.0, Globals.FLOOR_HEIGHT, 0.0)
		_state							= Globals.STATES.MOVING

	# Rotate the mole as it burrows
	_mesh.rotate_y(delta * 50.0)

	# Steadily lower or raise the mesh depending on what part of the burrow it is at
	if _curr_burrow_cooldown < _BURROW_TIME / 2.0:
		_mesh.position.y -= delta * _speed
	else:
		_mesh.position.y += delta * _speed

	# Move the mesh to the destination
	if _curr_burrow_cooldown > _BURROW_TIME / 2.0 and self.get_global_pos() != _burrow_target:
		self.set_global_pos(_burrow_target)
