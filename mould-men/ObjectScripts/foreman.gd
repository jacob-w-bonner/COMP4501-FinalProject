class_name Foreman extends Prospector

# The foreman has a different attack radius than its reach radius
const _RADIUS_MAX:  float	= 20.0
var _attack_radius: float 	= _RADIUS_MAX

# Ray cast objects
var _raycast1: RayCast3D 	= null
var _raycast2: RayCast3D 	= null

# Dynamite object
var _dynamite: Dynamite		= null

# Properties that track of rallying
@export var _has_rallied: 		bool				= false
@export var _rally_radius:		float				= 5.0
@export var _rally_buff:		float				= 1.5
var 		_rally_direction:	float				= 1.0
var			_jump_counter:		int					= 0
var			_units_buffed:		Array[Prospector]	= []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	# Instantiating parent first
	super._ready()

	# Setting the mesh
	_mesh.mesh							= (load("res://Assets/ArKaickAssets/Foreman/Foreman.tres") as Mesh).duplicate()

	# Finding the size of the collision box
	var bounding_box					= _mesh.mesh.get_aabb()
	var box_size						= bounding_box.size

	# Creating a collision box for the object
	var box_shape						= BoxShape3D.new()
	box_shape.size						= box_size

	# Setting the collision box
	_collision_shape.shape				= box_shape
	_collision_shape.position 			= bounding_box.get_center()

	# Setting the raycast objects
	_raycast1							= RayCast3D.new()
	_physics_body.add_child(_raycast1)
	_raycast2							= RayCast3D.new()
	_physics_body.add_child(_raycast2)

	# Offsetting the rays
	_raycast1.position.x += 0.7
	_raycast2.position.x -= 0.7

	# Setting the buff mesh height
	_buff_mesh.position					= Vector3(0.0, 7.0, 0.0)
	_buff_mesh.visible					= false
	_buff_height						= 7.0

	# Setting health higher
	_max_health							= 220
	_health								= _max_health

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

	# Additional things to do as foreman if moving
	if _state == Globals.STATES.MOVING:

		# Checking for the closest enemy to target if no target exists
		if _closest_op == null:
			_closest_op				    = closest_opponent(self)

		# If the current target is an ally or enemy then reset navigation range
		if _closest_op != null:
			if !_closest_op.is_enemy():
				_nav_agent.target_desired_distance = _attack_radius
			else:
				if _closest_op is Base:
					_nav_agent.target_desired_distance = _reach_radius * 2.0
				else:
					_nav_agent.target_desired_distance = _reach_radius

		# Running a basic move animation
		move_animation(delta)

	# Deal with the normal process
	super._process(delta)

	# Checking if the state should be rallying
	if self._health <= self._max_health / 3.0 and !_has_rallied:

		# Making sure the mesh is displaying properly
		_mesh.global_transform.basis 	= _physics_body.global_transform.basis
		_mesh.position					= Vector3.ZERO

		# Changing state to rallying
		_state							= Globals.STATES.RALLYING
		_has_rallied					= true

		# Applying buff to self
		self.increase_buff_val(self._rally_buff)

	# This unit should not leave the rallying state until animation is done
	if _jump_counter < 3 and _has_rallied:
		_state = Globals.STATES.RALLYING

	# Rally state processing
	if _state == Globals.STATES.RALLYING:

		# If the animation has played through then go back to moving
		if _jump_counter >= 3:
			_mesh.global_transform.basis 	= _physics_body.global_transform.basis
			_mesh.position					= Vector3.ZERO
			_state							= Globals.STATES.MOVING

		# Otherwise rally
		else:
			rally(delta)

# Called to rally nearby units
func rally(delta: float) -> void:

	# Rally animation
	rally_animation(delta)

	# Checking to see if each ally should be buffed
	for enemy in Globals.ENEMY_ARR:

		# Do not accept null units
		if !is_instance_valid(enemy):
			continue

		# Only buff enemies
		if enemy is Prospector and enemy != self:

			# If the enemy is within range and is not buffed already then do so
			if enemy.get_global_pos().distance_to(self.get_global_pos()) <= _rally_radius and !_units_buffed.has(enemy):

				# Adding the buff then adding them to the list of beneficiaries
				enemy.increase_buff_val(_rally_buff)
				_units_buffed.push_back(enemy)

# Override call to attack a closeby target
func attack(target: Unit, delta: float) -> void:

	# If there is no unit to attack return early
	if target.is_queued_for_deletion():
		_damage_dealt	= false
		_attack_time	= 0.0
		_state			= Globals.STATES.MOVING
		return

	# If the current target is out of range then move towards it 
	if self.get_global_pos().distance_to(target.get_global_pos()) > _attack_radius:
		_damage_dealt					= false
		_attack_time					= 0.0
		_mesh.global_transform.basis 	= _physics_body.global_transform.basis
		_mesh.position					= Vector3.ZERO
		_state							= Globals.STATES.MOVING
		return

	# Making sure enemy is within line of sight still
	_raycast1.target_position = _raycast1.to_local(self._closest_op.get_global_pos())
	_raycast1.force_raycast_update()
	_raycast2.target_position = _raycast2.to_local(self._closest_op.get_global_pos())
	_raycast2.force_raycast_update()
	var collider1			  = _raycast1.get_collider()
	var collider2			  = _raycast2.get_collider()

	# Indicator on whether line of sight is blocked
	var los1				  = (collider1 == null or (collider1 is not GridMap and !(collider1.get_parent() is StaticUnit and collider1.get_parent().is_enemy())))
	var los2				  = (collider2 == null or (collider2 is not GridMap and !(collider2.get_parent() is StaticUnit and collider2.get_parent().is_enemy())))

	# If the target is no longer in line of sight start moving
	if !los1 or !los2:
		_damage_dealt					= false
		_attack_time					= 0.0
		_mesh.global_transform.basis 	= _physics_body.global_transform.basis
		_mesh.position					= Vector3.ZERO
		_state							= Globals.STATES.MOVING
		return

	# Throwing the dynamite
	if _dynamite == null:
		_dynamite = Dynamite.new()
		get_tree().current_scene.add_child(_dynamite)
		_dynamite.global_position = self._physics_body.global_transform.origin + self._physics_body.global_transform.basis.z.normalized() * 1.5
		_dynamite.global_position.y += 1.0
		_dynamite.launch(self, _closest_op)

	# Throwing animation
	throw_animation(delta)

# A basic animation handler for the foreman movement
func move_animation(delta: float) -> void:
	_mesh.rotate_y(_attack_direction * delta * _buff_val * 0.25)
	if _mesh.rotation.y > deg_to_rad(45) or _mesh.rotation.y <= 0:
		_attack_direction *= -1.0

# A basic throwing animation
func throw_animation(delta: float) -> void:
	if _mesh.rotation.x < 0 and _dynamite != null:
		return
	_mesh.rotate_x(_attack_direction * delta * _buff_val)
	if _mesh.rotation.x > deg_to_rad(45) or _mesh.rotation.x < 0:
		_attack_direction *= -1.0

# A basic rallying animation
func rally_animation(delta: float) -> void:
	_mesh.position.y += _rally_direction * delta * 3.0
	if _mesh.position.y >= 1.0:
		_rally_direction *= -1.0
	if _mesh.position.y <= 0.0:
		_rally_direction *= -1.0
		_jump_counter += 1

# Called to indicate the dynamite exploded
func throw_another() -> void:
	_mesh.rotation.x = 0
	_dynamite		 = null

# Override called to destroy the unit
func destroy_self() -> void:

	# Clear the buff list
	for enemy in _units_buffed:
		if !is_instance_valid(enemy):
				continue
		enemy.decrease_buff_val(_rally_buff)
	_units_buffed.clear()

	# Destroying the unit
	super.destroy_self()

# Overrided call for when movement is finished
func nav_finish() -> void:

	# Calculating the direction the target is facing
	var direction					= self._closest_op._physics_body.global_transform.origin - self._physics_body.global_transform.origin
	direction.y						= 0
	direction 						= direction.normalized()

	# Casting rays for line of sight checks
	_raycast1.target_position		= _raycast1.to_local(self._closest_op.get_global_pos())
	_raycast1.force_raycast_update()
	_raycast2.target_position		= _raycast2.to_local(self._closest_op.get_global_pos())
	_raycast2.force_raycast_update()
	var collider1					= _raycast1.get_collider()
	var collider2					= _raycast2.get_collider()

	# Indicator on whether line of sight is blocked
	var los1						= (collider1 == null or (collider1 is not GridMap and !(collider1.get_parent() is StaticUnit and collider1.get_parent().is_enemy())))
	var los2						= (collider2 == null or (collider2 is not GridMap and !(collider2.get_parent() is StaticUnit and collider2.get_parent().is_enemy())))

	# If the closest target is an enemy building that is below full health then mend it
	if _closest_op is StaticUnit and _closest_op.is_enemy() and !_closest_op.is_max_health():

		# Setting the object rotation
		self._physics_body.rotation.y	= atan2(direction.x, direction.z)

		# Changing states
		_state							= Globals.STATES.MENDING

	# If the closest target is a mole or mole building then attack it
	elif !_closest_op.is_enemy() and los1 and los2:

		# Setting the object rotation
		self._physics_body.rotation.y	= atan2(direction.x, direction.z)

		# Changing states
		_attack_radius					= _RADIUS_MAX
		_state							= Globals.STATES.ATTACKING

	# Move towards the closest target
	else:

		# Storing the previous opponent and getting the closest one
		var prev	= _closest_op
		_closest_op = closest_opponent(self)

		# If the unit is the same ally unit then tighten the radius so that it moves closer
		if prev == _closest_op and !_closest_op.is_enemy():
			_attack_radius = max(_reach_radius, _attack_radius - 1.0)
		else:
			_attack_radius = _RADIUS_MAX

		# Changing states
		_state		= Globals.STATES.MOVING
