@abstract
class_name Unit extends Node3D

# Storing the camera
var _camera:					Camera3D		= null

# Properties that all units will have
@export var _max_health: 		int 			= 100
@export var _health: 			int 			= 100
@export var _is_enemy: 			bool 			= false
@export var _attack_strength:	int 				= 5.0

# State of the unit
@export var _state:				Globals.STATES	= Globals.STATES.IDLE

# Physicality of the unit
var _physics_body:				PhysicsBody3D
var _collision_shape:			CollisionShape3D
var _mesh:						MeshInstance3D

# Selection variables
var _is_hovered:				bool			= false
var _is_selected:				bool			= false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	# Getting the root of the tree so the camera node can be found
	var root		= get_tree().get_root()
	var target_node = root.find_child("Camera3D", true, false)

	if target_node is Camera3D:
		_camera = target_node
	else:
		print("Camera node not found.")

# Called to handle input events
func _input(event: InputEvent) -> void:

	# Checking for left mouse click
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:

		if self._is_hovered:
			print(self.name)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Getter for the state
func get_state() -> Globals.STATES:
	return _state

# Setter for the health
func set_health(new_health: int) -> void:
	_health = new_health

# Getter for the health
func get_health() -> int:
	return _health

# Setter for the unit position
func set_unit_position(new_pos: Vector3) -> void:
	self.global_position = new_pos

# Getter for the unit position
func get_unit_position() -> Vector3:
	return self.global_position

# Setter for practical global position (USE THIS INSTEAD OF NORMAL GLOBAL POSITION SETTER)
func set_global_pos(new_pos: Vector3) -> void:
	_physics_body.set_global_position(new_pos)

# Getter for practical global position (USE THIS INSTEAD OF NORMAL GLOBAL POSITION GETTER)
func get_global_pos() -> Vector3:
	return _physics_body.get_global_position()

# Getter for the enemy indicator
func is_enemy() -> bool:
	return _is_enemy

# Called to determine the closest opposing unit to the given position
func closest_opponent(unit: Unit) -> Unit:

	# Values that will contain the closest enemy position and distance
	var closest_pos  = Vector3(10000.0, 10000.0, 10000.0)
	var closest_dist = 10000.0
	var closest_unit = null

	# Do not accept null units
	if unit.is_queued_for_deletion() or !is_instance_valid(unit):
		return null

	# If the unit is an enemy then check for the closest ally
	if unit.is_enemy():

		# First make sure that there are allies to track
		if Globals.ALLY_ARR.size() == 0:
			return null

		# Check the array for the closest ally
		for ally in Globals.ALLY_ARR:

			# Do not accept null units
			if !is_instance_valid(ally):
				continue

			var distance = ally.get_global_pos().distance_to(unit.get_global_pos())
			if distance < closest_dist:
				closest_pos  = ally.get_global_pos()
				closest_dist = distance
				closest_unit = ally

	# Otherwise check for the closest enemy
	else:

		# First make sure that there are enemies to track
		if Globals.ENEMY_ARR.size() == 0:
			return null

		# Check the array for the closest enemy
		for enemy in Globals.ENEMY_ARR:

			# Do not accept null units
			if !is_instance_valid(enemy):
				continue

			var distance = enemy.global_position.distance_to(unit.get_global_pos())
			if distance < closest_dist:
				closest_pos  = enemy.global_position
				closest_dist = distance
				closest_unit = enemy

	return closest_unit


# Called to apply damage to the unit
func take_damage(damage_val: int) -> void:
	_health = _health - damage_val
	if _health <= 0:
		destroy_self()

# Called to apply healing to the unit
func receive_healing(healing_val: int) -> void:
	if _health < _max_health:
		if _health + healing_val > _max_health:
			_health = _max_health
		else:
			_health = _health + healing_val

# Called to destroy the unit
func destroy_self() -> void:
	if self.is_enemy():
		Globals.ENEMY_ARR.erase(self)
	else:
		Globals.ALLY_ARR.erase(self)
	self.queue_free()

# Called when the unit starts being hovered by the mouse
func start_hover() -> void:
	_is_hovered = true

# Called when the unit stops being hovered by the mouse
func stop_hover() -> void:
	_is_hovered = false

# Getter for whether or not the unit is hovered
func is_hovered() -> bool:
	return _is_hovered
