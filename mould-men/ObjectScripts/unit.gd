@abstract
class_name Unit extends Node3D

# Storing the camera
var _camera:					GameCamera		= null

# Properties that all units will have
@export var _max_health: 		int 			= 100
@export var _health: 			int 			= 100
@export var _is_enemy: 			bool 			= false
@export var _attack_strength:	int 			= 10.0

# State of the unit
@export var _state:				Globals.STATES	= Globals.STATES.IDLE

# Minimap variables
@export var _minimap_icon_texture: Texture2D
var _minimap_icon: Sprite3D

# Physicality of the unit
var _physics_body:				PhysicsBody3D
var _collision_shape:			CollisionShape3D
var _mesh:						MeshInstance3D

# Selection variables
var _is_hovered:				bool			= false
var _is_selected:				bool			= false

# Signals
signal clicked_on

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
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_MIDDLE:
		if self._is_hovered:
			_camera.unit_clicked_on(self)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
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

# Getter for a unit at max health
func is_max_health() -> bool:
	return _health == _max_health

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

func set_enemy(is_en: bool):
	_is_enemy = is_en

# Called to determine the closest opposing unit to the given position
func closest_opponent(unit: Unit) -> Unit:

	# Values that will contain the closest enemy position and distance
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

			# Do not accept self as an option
			if ally == self:
				continue

			var distance = ally.get_global_pos().distance_to(unit.get_global_pos())
			if distance < closest_dist:
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

			# Do not accept self as an option
			if enemy == self:
				continue

			var distance = enemy.get_global_pos().distance_to(unit.get_global_pos())
			if distance < closest_dist:
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

func set_minimap_icon(obj) -> void:
	# Set correct texture
	var path : String
	if obj is Amethyst:
		path = "res://Assets/UIAssets/amethyst.svg"
	elif obj is Diamond:
		path = "res://Assets/UIAssets/cut-diamond.svg"
	elif obj is Gold:
		path = "res://Assets/UIAssets/gold-bar.svg"
	elif obj is Coal:
		path = "res://Assets/UIAssets/stone-pile.svg"
	elif _is_enemy:
		path = "res://Assets/UIAssets/MinimapAssets/plain-square.svg"
	else:
		path =  "res://Assets/UIAssets/MinimapAssets/plain-circle.svg"
	
	# Set size
	var size = Vector3(0.3, 0.3, 0.3)
	
	# Load texture
	_minimap_icon_texture = load(path)
	
	# Set minimap icon
	_minimap_icon = Sprite3D.new()
	if _minimap_icon_texture:
		_minimap_icon.texture = _minimap_icon_texture
		_physics_body.add_child(_minimap_icon)
		_minimap_icon.position = Vector3(0, 3.0, 0) # height above mole
		_minimap_icon.scale = size
		_minimap_icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_minimap_icon.set_layer_mask_value(1, false) # minimap objects (ground)
		_minimap_icon.set_layer_mask_value(2, false) # visible through player camera
		_minimap_icon.set_layer_mask_value(3, true) # minimap icons
		
		# Set icon colour
		if obj is ResourceVein:
			return
		if _is_enemy:
			_minimap_icon.modulate = Color(0.0, 0.0, 1.0, 1.0)
		else:
			_minimap_icon.modulate = Color(0.684, 0.311, 0.08, 1.0)
