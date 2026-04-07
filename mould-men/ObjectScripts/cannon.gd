class_name Cannon extends StaticUnit

# Constant colours for the base depending on player or enemy
const _ENEMY_BASE:				Color				= Color(0.654, 0.654, 0.654, 1.0)
const _ALLY_BASE:				Color				= Color(0.453, 0.179, 0.0, 1.0)

# Constant for cannon attack range
const _ATTACK_RADIUS:			float				= 8.0

# Meshes and nodes for the cannon parts
var _mount_mesh:				MeshInstance3D		= null
var _barrel_mesh:				MeshInstance3D		= null
var _pivot:						Node3D				= null

# Raycast object
var _raycast:					RayCast3D 			= null

# Text over cannon variables 
var _action_text: Label3D
var _action_text_timer: float = 0.0
var _previous_state = -1

# Properties that track attacking
const		_ATTACK_DURATION:	float				= 1.0
var			_attack_time:		float				= 0.0
var 			_attack_speed:		float				= 1.0

# Bomb object
var 		_bomb:				Bomb				= null

# Shader for the cannon
@onready var _shader:		Shader					= preload("res://Shaders/cannon.gdshader")

# List of targets to fire at
var _target_list:			Array					= []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	# Instantiating parent first
	super._ready()

		# Setting health higher
	_max_health							= 500
	_health								= _max_health
	
	_action_text = Label3D.new()
	_action_text.text = ""
	_action_text.visible = false
	_action_text.font_size = 200
	_action_text.position = Vector3(0, 3.0, 0) # height above cannon
	_action_text.font_size = 100
	_action_text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_action_text.outline_size = 20

	# Change visibility layer of action label so it's NOT visible on layer 1 and IS visible on layer 2
	# Layer 1 will contain everything visible in the minimap
	# (this is because the gridmap is on layer 1 by default and i don't think its layer can be changed)
	_action_text.set_layer_mask_value(1, false)
	# Layer 2 will contain everything visible in the "player" camera
	_action_text.set_layer_mask_value(2, true)
	
	_physics_body.add_child(_action_text)

	# By default cannons are not enemies
	_is_enemy							= false

	# Initial state is cannoning
	_state								= Globals.STATES.CANNONING

	# Setting the mesh
	_mesh.mesh							= CylinderMesh.new()
	_mesh.mesh.top_radius				= 1.1
	_mesh.mesh.bottom_radius			= 1.1
	_mesh.mesh.height					= 0.5

	# Setting the shader material for the base
	var base_mat						= ShaderMaterial.new()
	base_mat.shader 					= _shader

	# Setting the colour of the base based on whether or not the cannon is an ally
	if is_enemy():
		base_mat.set_shader_parameter("tex_col", _ENEMY_BASE)
	else:
		base_mat.set_shader_parameter("tex_col", _ALLY_BASE)

	# Adding the base colour
	_mesh.mesh.surface_set_material(0, base_mat)

	# Adding the cannon mount next
	_mount_mesh = MeshInstance3D.new()
	_mesh.add_child(_mount_mesh)
	_mount_mesh.mesh = (load("res://Assets/Cannon/CannonBase.tres") as Mesh).duplicate()
	_mount_mesh.scale = Vector3(0.15, 0.15, 0.15)
	_mount_mesh.rotate(Vector3.UP, PI / 2.0)

	# Grabbing the material from each mount surface for use in the shader
	for i in range(_mount_mesh.mesh.get_surface_count()):

		# Getting the standard material from the surface
		var standard_mat 	= _mount_mesh.mesh.surface_get_material(i)

		# Only transform if what was retrieved is a standard material
		if standard_mat is StandardMaterial3D:

			# Initializing shader material for the mesh
			var shader_mat		= ShaderMaterial.new()
			shader_mat.shader 	= _shader

			# Setting the shader surface colour to the old material
			shader_mat.set_shader_parameter("tex_col", standard_mat.albedo_color)
			_mount_mesh.mesh.surface_set_material(i, shader_mat)

	# Adding the cannon pivot point next
	_pivot = Node3D.new()
	_mount_mesh.add_child(_pivot)
	_pivot.position = Vector3(2.1, 6.0, 0.0)

	# Adding the cannon barrel next
	_barrel_mesh = MeshInstance3D.new()
	_pivot.add_child(_barrel_mesh)
	_barrel_mesh.mesh = (load("res://Assets/Cannon/CannonBarrel.tres") as Mesh).duplicate()

	# Grabbing the material from each mount surface for use in the shader
	for i in range(_barrel_mesh.mesh.get_surface_count()):

		# Getting the standard material from the surface
		var standard_mat 	= _barrel_mesh.mesh.surface_get_material(i)

		# Only transform if what was retrieved is a standard material
		if standard_mat is StandardMaterial3D:

			# Initializing shader material for the mesh
			var shader_mat		= ShaderMaterial.new()
			shader_mat.shader 	= _shader

			# Setting the shader surface colour to the old material
			shader_mat.set_shader_parameter("tex_col", standard_mat.albedo_color)
			_barrel_mesh.mesh.surface_set_material(i, shader_mat)

	# Instantiating the collision shape
	_collision_shape					= CollisionShape3D.new()
	_physics_body.add_child(_collision_shape)

	# Finding the size of the collision box
	var bounding_box					= _mesh.mesh.get_aabb()
	var box_size						= bounding_box.size
	box_size.y							= 2.7

	# Creating a collision box for the object
	var box_shape						= BoxShape3D.new()
	box_shape.size						= box_size

	# Setting the collision box
	_collision_shape.shape				= box_shape
	_collision_shape.position 			= bounding_box.get_center()

	# Setting the raycast object
	_raycast							= RayCast3D.new()
	_pivot.add_child(_raycast)

	# Adding to own group
	_physics_body.add_to_group(self.name)

# Called to handle input events
func _input(event: InputEvent) -> void:

	# Checking all static click events first
	super._input(event)

	# Checking for right mouse click
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and self._is_hovered and !_is_enemy:

		# Changing states based on toggle
		if _state == Globals.STATES.CANNONING:
			_state = Globals.STATES.MORTARING
		else:
			_state = Globals.STATES.CANNONING

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

	# Locking y axis
	_physics_body.global_position.y = Globals.FLOOR_HEIGHT

	if _action_text_timer > 0:
		_action_text_timer -= delta
	
	if _action_text_timer <= 0:
		_action_text.visible = false
		
	# Detect state changes
	if _state != _previous_state:
		_on_state_changed(_state)
		_previous_state = _state

	# Setting the shader parameters that need to be set by frame for the base
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

	# Setting the shader parameters that need to be set by frame for the mount
	for i in range(_mount_mesh.mesh.get_surface_count()):

		# Sending the hover value
		_mount_mesh.mesh.surface_get_material(i).set_shader_parameter("is_hovered", _is_hovered)

		# If the object is being selected indicate so
		if Globals.SELECTED_UNIT == self:
			_mount_mesh.mesh.surface_get_material(i).set_shader_parameter("is_selected", true)
		else:
			_mount_mesh.mesh.surface_get_material(i).set_shader_parameter("is_selected", false)

		# Send health percentage to affect colouring
		_mount_mesh.mesh.surface_get_material(i).set_shader_parameter("health_percent", 1.0 - (float(_health) / float(_max_health)))

	# Setting the shader parameters that need to be set by frame for the base
	for i in range(_barrel_mesh.mesh.get_surface_count()):

		# Sending the hover value
		_barrel_mesh.mesh.surface_get_material(i).set_shader_parameter("is_hovered", _is_hovered)

		# If the object is being selected indicate so
		if Globals.SELECTED_UNIT == self:
			_barrel_mesh.mesh.surface_get_material(i).set_shader_parameter("is_selected", true)
		else:
			_barrel_mesh.mesh.surface_get_material(i).set_shader_parameter("is_selected", false)

		# Send health percentage to affect colouring
		_barrel_mesh.mesh.surface_get_material(i).set_shader_parameter("health_percent", 1.0 - (float(_health) / float(_max_health)))

	# Updating target selection
	get_targets()

	# Only deal with state checks if there are targets in range
	if _target_list.size() > 0:

		# If the target is invalid return
		if !is_instance_valid(_target_list[0]):
			_target_list.remove_at(0)
			return

		# If the target is queued for deletion return
		if _target_list[0].is_queued_for_deletion() or _target_list[0] == null:
			_target_list.remove_at(0)
			return

		# Calculating the direction the target is facing
		var direction					= self._target_list[0]._physics_body.global_transform.origin - self._physics_body.global_transform.origin
		var stored_y					= direction.y
		direction.y						= 0
		direction 						= direction.normalized()
		self.rotation.y					= atan2(direction.x, direction.z)
		var horizontal_distance			= sqrt(direction.x * direction.x + direction.z * direction.z)
		_barrel_mesh.rotation.x			= -atan2(stored_y, horizontal_distance)

		# Cannoning state processing
		if _state == Globals.STATES.CANNONING:
			cannon(delta)

		# Mortaring state processing
		if _state == Globals.STATES.MORTARING:
			mortar(delta)

# Called to handle cannoning action
func cannon(delta: float) -> void:

	# Adding to the current cast time, scaling by level
	_attack_time += (delta * _attack_speed)

	# Resetting the attack if it is maxed out
	if _attack_time > _ATTACK_DURATION:
		_attack_time	= 0.0

	# Deal damage to the target after a quarter of the time
	if _attack_time == 0:
		var shell				 = Shell.new()
		get_tree().current_scene.add_child(shell)
		_mount_mesh.rotate(Vector3.UP, -PI / 2.0)
		var velocity			 = self._target_list[0]._physics_body.global_transform.origin - Vector3(0.0, 1.0, 0.0) - self._barrel_mesh.global_transform.origin
		shell.shoot(_attack_strength, !_is_enemy, velocity, self._barrel_mesh.global_transform, self._pivot.global_position + Vector3(0.0, 1.0,0.0) + velocity.normalized() * 1.5, self.name)
		_mount_mesh.rotate(Vector3.UP, PI / 2.0)

# Called to handle mortaring action
func mortar(delta: float) -> void:

	# Throwing the dynamite
	if _bomb == null:
		_bomb = Bomb.new()
		get_tree().current_scene.add_child(_bomb)
		_mount_mesh.rotate(Vector3.UP, -PI / 2.0)
		_bomb.global_position = self._barrel_mesh.global_transform.origin + Vector3(0.0, 0.7, 0.0) + self._barrel_mesh.global_transform.basis.z.normalized() * 1.5
		_mount_mesh.rotate(Vector3.UP, PI / 2.0)
		_bomb.launch(_attack_strength, self.is_enemy(), self, _target_list[0])

# Called to indicate the dynamite exploded
func throw_another() -> void:
	_bomb = null

# Override for setting a cannon as enemy
func set_enemy(is_en: bool):
	_is_enemy = is_en

	# Changing the mesh base colour depending on if its an enemy or not
	if _is_enemy:
		_mesh.mesh.surface_get_material(0).set_shader_parameter("tex", _ENEMY_BASE)
	else:
		_mesh.mesh.surface_get_material(0).set_shader_parameter("tex", _ALLY_BASE)

# Called for cannon target acquisition
func get_targets() -> void:

	# Values that will contain the closest enemy position and distance
	var check_arr	= []

	# Do not accept null units
	if self.is_queued_for_deletion() or !is_instance_valid(self):
		return

	# Setting the check array
	if self.is_enemy():
		check_arr = Globals.ALLY_ARR
	else:
		check_arr = Globals.ENEMY_ARR

	# Checking the array for nearby enemies
	for target in check_arr:

		# Distance to the target
		var dist = self.get_global_pos().distance_to(target.get_global_pos())

		# If the target is within radius and not in the list check to see if it is a target
		if dist <= _ATTACK_RADIUS:

			# Casting rays for line of sight checks
			_raycast.target_position		= _raycast.to_local(target.get_global_pos())
			_raycast.force_raycast_update()
			var collider					= _raycast.get_collider()

			# If there is an enemy static unit blocking the way then don't damage
			var static_blocking				= true
			if collider != null and (collider.get_parent().get_parent() is StaticUnit) and _is_enemy == collider.is_enemy():
				static_blocking = false

			# Indicator on whether line of sight is blocked
			var los							= (collider != null and collider is not GridMap and static_blocking)

			# If there is sufficient line of sight add the unit to the array
			if los and !_target_list.has(target):
				_target_list.push_back(target)

			# If a target is in the list and out of line of sight remove it from the list
			if !los and _target_list.has(target):
				_target_list.erase(target)

		# If the target is out of range remove it from the list
		elif dist > _ATTACK_RADIUS and _target_list.has(target):
			_target_list.erase(target)

func show_action_text(text: String, color: Color):
	_action_text.text = text
	_action_text.modulate = color
	_action_text.visible = true
	_action_text_timer = 1.5

func _on_state_changed(new_state):
	match new_state:

		Globals.STATES.CANNONING:
			show_action_text("Cannon", Color(1,0,0))

		Globals.STATES.MORTARING:
			show_action_text("Mortar", Color(1.0, 0.405, 0.028, 1.0))
			
func handle_level_up() -> void:
	if _level == 3:
		#25% increase to attack speed, heal to full
		_attack_speed *= 1.25
		receive_healing(_max_health)

	elif _level == 4:
		#Componding 25% increase to attack speed, 25% increase to attack damage, heal to full
		_attack_strength *= 1.25
		_attack_speed *= 1.25
		receive_healing(_max_health)
