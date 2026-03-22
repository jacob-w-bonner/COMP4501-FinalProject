class_name Mole extends DynamicUnit

# BEHAVIOURS DESCRIPTION
#
# SENTRY:
# - State becomes SENTRY if no enemies left or mole is DOUBLE CLICKED
# - While in SENTRY state, mole waits until an enemy unit comes within sentry radius then
#   changes to MOVING state
#
# MOVING:
# - State becomes MOVING if
#    ~ there is an enemy within its SENTRY radius
#    ~ the mole is CLICKED and another unit of any kind is clicked (will move towards this unit)
#    ~ the mole is in the ATTACKING state and it does not have an enemy to attack (will find the closest
#      one to move towards)
#    ~ the mole's target in the ATTACKING state moves out of range
#    ~ the mole has reached its destination specified by the BURROW state
# - While in MOVING state, the mole moves towards a target contained in the _closest_op field
#
# ATTACKING:
# - State becomes ATTACKING if mole reaches its target in the MOVING state and its target is an enemy
# - While in the ATTACKING state the mole attacks the unit in the _closest_op field until it has been
#   killed (when this happens it changes to MOVING state targeting the closest enemy)
#
# BURROW
# - State becomes BURROW when the mole is CLICKED and a valid space that does not contain a unit of
#   any kind is CLICKED (the space must be within a certain radius)
# - While in the BURROW state the mole travels to the CLICKED location underground (it remains at
#   its first location before half of the cast time and it teleports to its destination after half
#   its cast time)
# - Once the BURROW cast time has finished there is a small cooldown before a mole can BURROW again
#   and the mole will find the nearest enemy and transition to the MOVING state

# Constants common to moles
const _BURROW_COOLDOWN: 	float 			= 5.0
const _BURROW_DISTANCE:		float			= 10.0
const _BURROW_TIME:			float			= 8.0

# Tracking burrowing properties
var _curr_burrow_cooldown: 	float 			= 0.0
var _can_burrow:			bool			= true
var _burrow_target:			Vector3			= Vector3(0.0, Globals.FLOOR_HEIGHT, 0.0)

# Text over mole variables 
var _action_text: Label3D
var _action_text_timer: float = 0.0
var _previous_state = -1

# Shader for the mole
@onready var _shader:		Shader			= preload("res://Shaders/mole.gdshader")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Instantiating parent first
	super._ready()
	
	_action_text = Label3D.new()
	_action_text.text = ""
	_action_text.visible = false
	_action_text.font_size = 200
	_action_text.position = Vector3(0, 5.0, 0) # height above mole
	_action_text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_action_text.outline_size = 50
	
	_physics_body.add_child(_action_text)

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

	# Checking for double click left mouse click
	if event is InputEventMouseButton and event.double_click and event.button_index == MOUSE_BUTTON_LEFT:
		if self._is_hovered and !self.is_enemy() and _state != Globals.STATES.BURROW and !Globals.SELECT_COOLDOWN:
			Globals.SELECTED_UNIT 	= null
			Globals.SELECT_COOLDOWN = true
			_state					= Globals.STATES.SENTRY
			return

	# Checking for left mouse click
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:

		# If the unit is being hovered and there is nothing else selected then select the unit
		if self._is_hovered and Globals.SELECTED_UNIT == null and !self.is_enemy() and _state != Globals.STATES.BURROW and !Globals.SELECT_COOLDOWN:
			Globals.SELECTED_UNIT = self
			_is_selected		  = true
			show_action_text("Selected", Color(1.0, 0.489, 0.112, 1.0))
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

	if _action_text_timer > 0:
		_action_text_timer -= delta
	
	if _action_text_timer <= 0:
		_action_text.visible = false
		
	# Detect state changes
	if _state != _previous_state:
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

		# If a previous action was being taken reset the mesh
		_mesh.global_transform.basis 	= _physics_body.global_transform.basis

		# Checking for the closest enemy to target if no target exists
		if _closest_op == null:
			_closest_op				    = closest_opponent(self)

		# Navigation setting
		else:
			_nav_agent.target_position  = _closest_op.get_global_pos()

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
		_mesh.global_transform.basis 	= _physics_body.global_transform.basis
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

# Called to determine the closest opposing unit to the given position
func closest_opponent(unit: Unit) -> Unit:
	return super.closest_opponent(self)

func show_action_text(text: String, color: Color):
	_action_text.text = text
	_action_text.modulate = color
	_action_text.visible = true
	_action_text_timer = 1.5
	
func _on_state_changed(new_state):
	match new_state:
		Globals.STATES.MOVING:
			show_action_text("Moving", Color(0,1,0))

		Globals.STATES.ATTACKING:
			show_action_text("Attacking", Color(1,0,0))

		Globals.STATES.BURROW:
			show_action_text("Burrowing", Color(0,0.5,1))

		Globals.STATES.SENTRY:
			show_action_text("Sentry", Color(1,1,0))
			
		Globals.STATES.MINE:
			show_action_text("Mining", Color(1.0, 0.0, 0.937, 1.0))
			
		Globals.STATES.GROOVING:
			show_action_text("Grooving", Color(0.456, 0.663, 1.0, 1.0))
			
		Globals.STATES.HEALING:
			show_action_text("Healing", Color(0.0, 0.602, 0.295, 1.0))
