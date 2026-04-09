class_name Armadillo extends DynamicUnit

# Shader for the mole
@onready var _shader:		Shader			= preload("res://Shaders/mole.gdshader")

@onready var rig = $Rig
@onready var skeleton = $Rig/Skeleton3D
@onready var animation_player = $AnimationPlayer

# Text over armadillo variables 
var _action_text: Label3D
var _action_text_timer: float = 0.0
var _previous_state = -1

# Carry variables
var _pickup_target: Mole = null
var passenger:		Mole = null
const PICKUP_RANGE: float = 2.5
var holding_mole = false 

#Passive healing vars
var regen_timer = 0
var regen_proc_time = 0.3
var healing_amount = 1

@onready var carry_point: Node3D
@onready var dummy_mole: Node3D

var carried_mole: Mole = null

func _ready() -> void:

	# Instantiating parent first
	super._ready()
	
	carry_point = Node3D.new()
	carry_point.name = "CarryPoint"
	carry_point.position = Vector3(0, 0.5, 0) 
	_physics_body.add_child(carry_point)
	
	dummy_mole = MeshInstance3D.new()
	dummy_mole.mesh = (load("res://Assets/MoleAssets/Mole/Mole.tres") as Mesh).duplicate()
	dummy_mole.scale = Vector3(0.17, 0.17, 0.17)
	dummy_mole.visible = false
	carry_point.add_child(dummy_mole)
	
	_action_text = Label3D.new()
	_action_text.text = ""
	_action_text.visible = false
	_action_text.font_size = 200
	_action_text.position = Vector3(0, 0.571428, 0) # height above armadillo
	_action_text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_action_text.scale = Vector3(0.142857, 0.142857, 0.142857)
	_action_text.outline_size = 50
	
	_physics_body.add_child(_action_text)
	
	# Instantiating the collision shape
	_collision_shape = CollisionShape3D.new()
	_physics_body.add_child(_collision_shape)
	animation_player.reparent(_physics_body)
	rig.reparent(_physics_body)

	var box_shape = CapsuleShape3D.new()
	box_shape.height = 0.285714
	box_shape.radius = 0.171428
	box_shape.mid_height = 0.285714

	_collision_shape.shape = box_shape
	_collision_shape.rotation_degrees.x = -90
	_collision_shape.position = Vector3(0, 0.15, 0)
	
	#Set speed and health to an aproprite value for our fast strong boi
	self._speed = 2.0
	_max_health = 200
	_attack_strength = 15
	print(self._speed)

func _process(delta: float) -> void:
	super._process(delta) 
	
	if _action_text_timer > 0:
		_action_text_timer -= delta
	
	if _action_text_timer <= 0:
		_action_text.visible = false
		
	#Heal our passenger if approprite level
	var my_class = self.get_script().get_global_name()
	var cur_level = Globals.dynamic_levels[my_class]['cur_level']
	if cur_level >= 3 and passenger != null:
		regen_timer += delta
		if regen_timer >= regen_proc_time:
			passenger.receive_healing(healing_amount)
			regen_timer = 0

	# Detect state changes
	if _state != _previous_state:
		_on_state_changed(_state)
		_previous_state = _state

	if _state == Globals.STATES.MOVING:
		if animation_player.is_playing():
			animation_player.stop()
		if _closest_op == null:
			_closest_op = closest_opponent(self)
		else:
			_nav_agent.target_position = _closest_op.get_global_pos()

		move(_closest_op)
		
		if _pickup_target != null and is_instance_valid(_pickup_target) and holding_mole == false and (_pickup_target._state == Globals.STATES.IDLE or _pickup_target._state == Globals.STATES.SENTRY):
			var dist = _physics_body.global_position.distance_to(_pickup_target.get_global_pos())
			if dist <= PICKUP_RANGE:
				pick_up_mole(_pickup_target)
				_pickup_target = null
				_closest_op = null
				_state = Globals.STATES.SENTRY
				return

		if _closest_op == null:
			_nav_agent.velocity = Vector3.ZERO
			_state = Globals.STATES.SENTRY

	elif _state == Globals.STATES.ATTACKING:
		if !is_instance_valid(_closest_op):
			_state = Globals.STATES.MOVING
			return

		_nav_agent.velocity = Vector3.ZERO
		if not animation_player.is_playing():
			animation_player.play_section("Animation")
		attack(_closest_op, delta)

	elif _state == Globals.STATES.SENTRY:
		_closest_op = null
		_nav_agent.velocity = Vector3.ZERO
		sentry()
	
	if (self.get_health() <= 20 and holding_mole and carried_mole != null):
		drop_mole(carried_mole)
	
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
			
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if self._is_hovered and holding_mole and carried_mole != null:
			drop_mole(carried_mole)
			return

	# Checking for left mouse click
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:

		# If the unit is being hovered and there is nothing else selected then select the unit
		if self._is_hovered and Globals.SELECTED_UNIT == null and !self.is_enemy() and _state != Globals.STATES.BURROW and !Globals.SELECT_COOLDOWN:
			Globals.SELECTED_UNIT = self
			_is_selected		  = true
			show_action_text("Selected", Color(1.0, 0.489, 0.112, 1.0))
			#print("%s: %d" % [Globals.SELECTED_UNIT.name, Globals.SELECTED_UNIT.get_state()])
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
				if !is_instance_valid(ally):
					continue
				if ally.is_hovered():
					
					if ally is Mole:
						if not ally._is_being_carried:
							_pickup_target = ally
							_closest_op = ally
							_state = Globals.STATES.MOVING
						return
					
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


func nav_finish() -> void:
	if _pickup_target == null:
		super.nav_finish()

func pick_up_mole(mole: Mole) -> void:
	if mole == null or mole._is_being_carried:
		return
		
	carried_mole = mole  
		
	
	mole._is_being_carried = true
	mole._carrier = self

	mole._nav_agent.velocity = Vector3.ZERO
	mole._closest_op = null

	mole.get_parent().remove_child(mole)
	carry_point.add_child(mole)
	
	mole.visible = false
	mole._collision_shape.disabled = true

	dummy_mole.mesh = mole._mesh.mesh
	dummy_mole.visible = true
	
	self._speed *= 4

	holding_mole = true
	passenger = mole
	
	show_action_text("Picked up mole", Color(0,1,1))
	
func drop_mole(mole: Mole) -> void:
	if mole == null or !mole._is_being_carried:
		return
		
	carried_mole = null
	
	mole._collision_shape.disabled = false

	mole._is_being_carried = false
	mole._carrier = null

	carry_point.remove_child(mole)
	get_parent().add_child(mole)

	var drop_pos = carry_point.global_position + Vector3(2, 0, 0)
	drop_pos.y = Globals.FLOOR_HEIGHT

	mole.scale = Vector3(0.5, 0.5, 0.5)
	mole.global_position = drop_pos
	
	self._speed *= 0.25
	
	mole.visible = true
	mole._collision_shape.disabled = false

	dummy_mole.visible = false

	holding_mole = false
	passenger = null
	show_action_text("Dropped mole", Color(1,1,1))
	
func show_action_text(text: String, color: Color):
	_action_text.text = text
	_action_text.modulate = color
	_action_text.visible = true
	_action_text_timer = 1.5
	
func _on_state_changed(new_state):
	match new_state:
		Globals.STATES.MOVING:
			show_action_text("Moving", Color(0,1,0))
			#_animation_test()

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

#Gives the unit its upgrade boons, deducts resource cost
func handle_level_up_effects() -> void:
	var my_class = self.get_script().get_global_name()
	var cur_level = Globals.dynamic_levels[my_class]['cur_level']
	
	if cur_level == 2:
		#Recieve a 50% increase to speed
		_speed *= 1.50
	elif cur_level == 3:
		#recieve a 25% max health boost, heal 25%
		var old_health = _max_health
		_max_health = ceil(_max_health * 1.25)
		receive_healing(_max_health-old_health)
