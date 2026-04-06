class_name Bomb extends RigidBody3D

# Explosion particles scene
const EXPLOSION: 		PackedScene		= preload("res://Assets/Explosions/explosion.tscn")

# Physicality of the unit
var _collision_shape:	CollisionShape3D
var _mesh:				MeshInstance3D

# Fuse flame
@onready var _flame:	GPUParticles3D	= preload("res://Assets/Shells/bomb_flame.tscn").instantiate()

# Raycast object
var _raycast:				RayCast3D 	= null

# Constants for the dynamite throw physics
const ARC_HEIGHT:			float		= 1.0

# Explosion timer
var _explosion_timer:		Timer		= null

# Explosion damage and range
var _explosion_damage: 		int			= 10
const _EXPLOSION_RANGE:		float		= 4.0

# Storing the thrower
var _thrower:				Cannon		= null

# Whether or not the bomb is from an enemy
var _is_enemy:				bool		= false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	# Setting the scale
	self.scale = Vector3(0.1, 0.1, 0.1)
	self.angular_damp = 10.0

	# Setting the mesh
	_mesh								= MeshInstance3D.new()
	_mesh.mesh							= (load("res://Assets/Shells/Bomb.tres") as Mesh).duplicate()
	self.add_child(_mesh)

	# Instantiating the collision shape
	_collision_shape					= CollisionShape3D.new()
	self.add_child(_collision_shape)

	# Creating a collision box for the object
	var sphere_shape					= SphereShape3D.new()
	sphere_shape.radius					= 1.6

	# Setting the collision box
	_collision_shape.shape				= sphere_shape

	# Setting the bomb flame
	self.add_child(_flame)
	_flame.scale						= Vector3(0.7, 0.7, 0.7)
	_flame.position					   += Vector3(0.33, 2.6, 0.0)

	# Setting the raycast objects
	_raycast							= RayCast3D.new()
	self.add_child(_raycast)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Called to propel the dynamite
func launch(damage: float, is_enemy: bool, thrower: Unit, target: Unit) -> void:

	# Making sure bomb does not collide with cannon
	#self.add_collision_exception_with(thrower)

	# Setting the explosion timer
	_explosion_timer		= Timer.new()
	self.add_child(_explosion_timer)
	_explosion_timer.connect("timeout", Callable(self, "explode"))
	_explosion_timer.start(2.25)

	# Storing the damage and target affiliation
	_explosion_damage		= damage
	_is_enemy				= is_enemy

	# Storing the thrower
	_thrower				= thrower

	# Calculating the distance
	var dist				= thrower.get_global_pos() - target.get_global_pos()

	# Getting the gravity
	var gravity				= ProjectSettings.get_setting("physics/3d/default_gravity")

	# Calculating vertical velocity
	var max_height  		= max(dist.y, ARC_HEIGHT)
	var y_vel				= sqrt(2 * gravity * max_height)

	# Calculating travel time
	var up_travel_time		= y_vel / gravity
	var down_travel_time	= sqrt(2 * (max_height - dist.y) / gravity)
	var total_travel_time	= up_travel_time + down_travel_time

	# Calculating horizontal velocity
	var x_vel				= -dist.x / total_travel_time
	var z_vel				= -dist.z / total_travel_time

	# Applying force to launch the dynamite
	self.apply_central_impulse(Vector3(x_vel, y_vel, z_vel) * 0.75)

# Called to blow up the dynamite
func explode() -> void:

	# Getting which array to check
	var check_arr = []
	if _is_enemy:
		check_arr = Globals.ALLY_ARR
	else:
		check_arr = Globals.ENEMY_ARR

	# Check the array for who to damage
	for target in check_arr:

		# Only do LOS check if target is close enough to take damage
		if self.global_position.distance_to(target.get_global_pos()) <= _EXPLOSION_RANGE:

			# Casting rays for line of sight checks
			_raycast.target_position		= _raycast.to_local(target.get_global_pos())
			_raycast.force_raycast_update()
			var collider					= _raycast.get_collider()

			# If there is an enemy static unit blocking the way then don't damage
			var static_blocking				= true
			if collider != null:
				if (collider.get_parent().get_parent() is StaticUnit) and collider.get_parent().get_parent().is_enemy() != _is_enemy:
					static_blocking = false

			# Indicator on whether line of sight is blocked
			var los							= (collider != null and collider is not GridMap and static_blocking)

			# If there is sufficient line of sight deal damage to the target
			if los:
				target.take_damage(_explosion_damage)

	# Indicating the thrower can throw another dynamite
	if is_instance_valid(_thrower) and !_thrower.is_queued_for_deletion():
		_thrower.throw_another()

	# Adding an explosion to the scene tree
	var expl			 = EXPLOSION.instantiate()
	get_tree().current_scene.add_child(expl)
	expl.global_position = self.global_position

	# Removing the dynamite
	self.queue_free()
