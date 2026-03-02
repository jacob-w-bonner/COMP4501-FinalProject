@abstract
class_name Unit extends Node3D

# Properties that all units will have
@export var _health: 		int 			= 100
@export var _is_enemy: 		bool 			= false

# State of the unit
@export var _state:					Globals.STATES	= Globals.STATES.IDLE

# Physicality of the unit
var _physics_body:			PhysicsBody3D
var _collision_shape:		CollisionShape3D
var _mesh:					MeshInstance3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

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

# Called to apply damage to the unit
func take_damage(damage_val: int) -> void:
	_health = _health - damage_val

# Called to destroy the unit
func destroy_self() -> void:
	self.queue_free()
