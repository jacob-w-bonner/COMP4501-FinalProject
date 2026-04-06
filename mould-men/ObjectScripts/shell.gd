class_name Shell extends MeshInstance3D

# Shell values
var _damage:	float					= 0.0
var _is_enemy:	bool					= false
var _velocity:	Vector3					= Vector3(1.0, 1.0, 1.0)
var _speed:		float					= 50.0
var _area:		Area3D					= null
var _col:		CollisionShape3D		= null
var _owner:		String					= ""

func _ready() -> void:

	# Setting the mesh
	self.mesh							= (load("res://Assets/Shells/Shell.tres") as Mesh).duplicate()

	# Setting the area
	_area								= Area3D.new()
	self.add_child(_area)

	# Setting the collision shape
	_col 								= CollisionShape3D.new()
	_area.add_child(_col)

	# Finding the size of the collision box
	var bounding_box					= self.mesh.get_aabb()
	var box_size						= bounding_box.size

	# Creating a collision box for the object
	var box_shape						= BoxShape3D.new()
	box_shape.size						= box_size

	# Setting the collision box
	_col.shape							= box_shape
	_col.position 						= bounding_box.get_center()

func _process(delta: float) -> void:

	# Making the shell travel
	self.global_position += _velocity.normalized() * delta * _speed

# Called to propel the shell
func shoot(damage: float, is_enemy: bool, velocity: Vector3, _transform: Transform3D, pos: Vector3, shell_owner: String) -> void:
	_damage			= damage
	_is_enemy		= is_enemy
	_velocity		= velocity
	_owner			= shell_owner
	self.transform	= _transform
	self.global_position = pos
	self.scale		= Vector3(0.1, 0.1, 0.1)

	# Connects the signal to the target hit function
	self._area.body_entered.connect(target_hit)

# Called when a target is hit
func target_hit(target) -> void:

	# Check if the target is valid first
	if is_instance_valid(target):

		# If the target is a unit check to see if it should take damage
		if target.get_parent() is Unit and !target.is_queued_for_deletion():

			# If the target is on the correct team deal damage to it
			if target.get_parent().is_enemy() == _is_enemy:
				target.get_parent().take_damage(_damage)

		# Delete the shell
		if !target.is_in_group(_owner):
			self.queue_free()
