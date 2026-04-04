class_name Armadillo extends DynamicUnit

# Shader for the mole
@onready var _shader:		Shader			= preload("res://Shaders/mole.gdshader")

@onready var head_pivot = $DALE/HEAD_PIVOT
@onready var head = $DALE/HEAD_PIVOT/HEAD
@onready var snout = $DALE/HEAD_PIVOT/HEAD/SNOUT

@onready var ring_1 = $DALE/RING_1
@onready var ring_2 = $DALE/RING_2
@onready var ring_3 = $DALE/RING_3
@onready var ring_4 = $DALE/RING_4
@onready var ring_5 = $DALE/RING_5
@onready var ring_6 = $DALE/RING_6

@onready var lf_leg_pivot = $DALE/L_F_LEG_PIVOT
@onready var rf_leg_pivot = $DALE/R_F_LEG_PIVOT
@onready var lb_leg_pivot = $DALE/L_B_LEG_PIVOT
@onready var rb_leg_pivot = $DALE/R_B_LEG_PIVOT

# Text over armadillo variables 
var _action_text: Label3D
var _action_text_timer: float = 0.0
var _previous_state = -1

var walk_time: float = 0.0
var walk_speed: float = 6.0   # animation speed
var walk_amount: float = 0.0  # 0 = idle, 1 = full walk

var rings = []
var leg_pivots = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	# Instantiating parent first
	super._ready()
	
	_action_text = Label3D.new()
	_action_text.text = ""
	_action_text.visible = false
	_action_text.font_size = 200
	_action_text.position = Vector3(0, 2.0, 0) # height above armadillo
	_action_text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_action_text.scale = Vector3(0.5, 0.5, 0.5)
	_action_text.outline_size = 50
	
	_physics_body.add_child(_action_text)
	
	#_mesh.mesh = 

	# Armadillos are not enemies
	#_is_enemy							= false
	
	rings = [ring_1, ring_2, ring_3, ring_4, ring_5, ring_6]
	leg_pivots = [lf_leg_pivot, rf_leg_pivot, lb_leg_pivot, rb_leg_pivot]

	_physics_body.position = _physics_body.to_local(head.global_transform.origin)
	
	# Instantiating the collision shape
	_collision_shape = CollisionShape3D.new()
	_physics_body.add_child(_collision_shape)
	$DALE.reparent(_physics_body)

	var box_shape = CapsuleShape3D.new()
	box_shape.height = 1
	box_shape.radius = 0.6
	box_shape.mid_height = 1

	_collision_shape.shape = box_shape
	_collision_shape.rotation_degrees.x = -90
	_collision_shape.position = Vector3(0, -0.2, -0.5)

	# Grabbing the material from each surface for use in the shader
	#for child in model.get_children():
	#	if child is MeshInstance3D:
	#		var mesh = child.mesh
			
	#		for i in range(mesh.get_surface_count()):
	#			var standard_mat = mesh.surface_get_material(i)
	#			
	#			if standard_mat is StandardMaterial3D:
	#				var shader_mat = ShaderMaterial.new()
	#				shader_mat.shader = _shader
	#				shader_mat.set_shader_parameter("tex", standard_mat.albedo_texture)
	#				mesh.surface_set_material(i, shader_mat)

func _process(delta: float) -> void:
	super._process(delta) 
	
	if _action_text_timer > 0:
		_action_text_timer -= delta
	
	if _action_text_timer <= 0:
		_action_text.visible = false
		
	# Detect state changes
	if _state != _previous_state:
		_on_state_changed(_state)
		_previous_state = _state

	if _state == Globals.STATES.MOVING:
		if _closest_op == null:
			_closest_op = closest_opponent(self)
		else:
			_nav_agent.target_position = _closest_op.get_global_pos()

		move(_closest_op)

		if _closest_op == null:
			_nav_agent.velocity = Vector3.ZERO
			_state = Globals.STATES.SENTRY

	elif _state == Globals.STATES.ATTACKING:
		if !is_instance_valid(_closest_op):
			_state = Globals.STATES.MOVING
			return

		_nav_agent.velocity = Vector3.ZERO
		attack(_closest_op, delta)

	elif _state == Globals.STATES.SENTRY:
		_closest_op = null
		_nav_agent.velocity = Vector3.ZERO
		sentry()

	handle_animation(delta)
	
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

func handle_animation(delta: float):
	var vel = 10#_physics_body.velocity.length()
	walk_amount = clamp(vel / _speed, 0.0, 1.0)

	if walk_amount > 0.01:
		walk_time += delta * walk_speed * walk_amount
		animate_walk(walk_time)
	else:
		reset_pose(delta)

func animate_walk(t: float) -> void:

	var leg_swing = sin(t) * 0.01
	var leg_swing_opposite = sin(t + PI) * 0.01

	lf_leg_pivot.rotation.x = leg_swing
	rb_leg_pivot.rotation.x = leg_swing
	rf_leg_pivot.rotation.x = leg_swing_opposite
	lb_leg_pivot.rotation.x = leg_swing_opposite

	for i in range(rings.size()):
		var phase = t + i * 0.5
		rings[i].rotation.y = rings[i].rotation.y + sin(phase) * 0.005
		rings[i].rotation.y = rings[i].rotation.y + cos(phase) * 0.005
		head_pivot.rotation.z = head_pivot.rotation.z + sin(phase) * 0.00001
		head_pivot.rotation.z = head_pivot.rotation.z + cos(phase) * 0.00001

func reset_pose(delta: float) -> void:

	var reset_speed = 5.0

	for leg in leg_pivots:
		leg.rotation.x = lerp(leg.rotation.x, 0.0, delta * reset_speed)

	for ring in rings:
		ring.rotation = ring.rotation.lerp(Vector3.ZERO, delta * reset_speed)

	head_pivot.rotation = head_pivot.rotation.lerp(Vector3.ZERO, delta * reset_speed)
