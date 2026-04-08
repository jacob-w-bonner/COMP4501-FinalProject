class_name Base extends StaticUnit

var friendly_units = {
	"Mole" : {
		"cost" : { Globals.RESOURCES.COAL : -10, Globals.RESOURCES.GOLD : 0, Globals.RESOURCES.AMETHYST : 0, Globals.RESOURCES.DIAMOND : 0 },
		"spawn_cooldown" : 2.0,
		"cur_spawn_cooldown" : 0.0,
		"unit_type" : Mole,
	},
	"MinerMole" : {
		"cost" : { Globals.RESOURCES.COAL : -15, Globals.RESOURCES.GOLD : -10, Globals.RESOURCES.AMETHYST : 0, Globals.RESOURCES.DIAMOND : 0 },
		"spawn_cooldown" : 10.0,
		"cur_spawn_cooldown" : 0.0,
		"unit_type" : MinerMole,
	},
	"DoctorMole" : {
		"cost" : { Globals.RESOURCES.COAL : -35, Globals.RESOURCES.GOLD : -15, Globals.RESOURCES.AMETHYST : -2, Globals.RESOURCES.DIAMOND : 0 },
		"spawn_cooldown" : 5.0,
		"cur_spawn_cooldown" : 0.0,
		"unit_type" : DoctorMole,
	},
	"MusicMole" : {
		"cost" : { Globals.RESOURCES.COAL : 0, Globals.RESOURCES.GOLD : -20, Globals.RESOURCES.AMETHYST : -4, Globals.RESOURCES.DIAMOND : 0 },
		"spawn_cooldown" : 10.0,
		"cur_spawn_cooldown" : 0.0,
		"unit_type" : MusicMole,
	},
	"Armadillo" : {
		"cost" : { Globals.RESOURCES.COAL : 0, Globals.RESOURCES.GOLD : 0, Globals.RESOURCES.AMETHYST : -5, Globals.RESOURCES.DIAMOND : -5 },
		"spawn_cooldown" : 20.0,
		"cur_spawn_cooldown" : 0.0,
		"unit_type" : Armadillo,
	}
}
var enemy_units = {
	"Prospector" : {
		"spawn_cooldown" : 25.0,
		"cur_spawn_cooldown" : 5.0, 
		"unit_type" : Prospector,
		
	},
	"Foreman" : {
		"spawn_cooldown" : 45.0,
		"cur_spawn_cooldown" : 20.0,
		"unit_type" : Foreman,
	}
}

@export var spawn_offset: Vector3 = Vector3(6.0, Globals.FLOOR_HEIGHT, 0.0)
@export var cannon_pos: Vector3 = Vector3(-0.5, Globals.FLOOR_HEIGHT, -6.0)
@export var spawn_radious: Vector3 = Vector3(0.5, 0.0, 2.5)
var rng = RandomNumberGenerator.new()
var enemy_diff:		int = 1

var health_bar_sprite:	Sprite3D
var subview_port:		SubViewport
var health_bar:			ProgressBar = preload("res://Scenes/health_bar.tscn").instantiate()

# Text over mole variables 
var _action_text: Label3D
var _action_text_timer: float = 0.0
var _previous_state = -1

# Shader for the mole
@onready var _shader:		Shader			= preload("res://Shaders/mole.gdshader")

#Ending scene to switch to
var ending_scene:			Ending			= preload("res://Scenes/end_scene.tscn").instantiate()
var surrendering:			bool			= false
# Called when the node enters the scene tree for the first time.
func _ready():
	
	#If you just want to test an upgrade quickly
	#if not is_enemy():
		#var temp = Cannon.new()
		#print(trigger_upgrade(temp))
		#temp.queue_free()
	
	# Instantiating parent first
	super._ready()
	# Set avoidence radious for units
	# Setting the mesh
	if is_enemy():
		_nav_obs.scale = Vector3(1,1,1) / self.scale
		_nav_obs.radius = 2

		_nav_obs.global_position = self.global_position + Vector3(12,Globals.FLOOR_HEIGHT,20) * Vector3(self.scale.x, 1, self.scale.z)
		_mesh.mesh							= (load("res://Assets/StaticAssets/apartment.tres") as Mesh).duplicate()
	else:
		_nav_obs.radius = 0.65
		_nav_obs.global_position = self.global_position
		_mesh.mesh							= (load("res://Assets/StaticAssets/hole.tres") as Mesh).duplicate()

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

	#health bar stuff
	subview_port = SubViewport.new()
	health_bar_sprite = Sprite3D.new()

	subview_port.add_child(health_bar)
	subview_port.transparent_bg = true
	subview_port.disable_3d = true
	health_bar_sprite.billboard = 1
	health_bar_sprite.texture = subview_port.get_texture()
	
	health_bar.fill_mode = ProgressBar.FillMode.FILL_BEGIN_TO_END
	health_bar.show_percentage = false
	health_bar.max_value = _max_health
	health_bar.value = _health
	self.add_child(subview_port)
	self.add_child(health_bar_sprite)
	
	if is_enemy():
		health_bar.add_theme_stylebox_override("fill", load("res://Assets/ResourceAssets/oliver_health_bar_fill.tres"))
		health_bar_sprite.scale = Vector3(2, 2, 2) / self.scale
		health_bar_sprite.position = Vector3(12,90,0)
	else:
		health_bar.add_theme_stylebox_override("fill", load("res://Assets/ResourceAssets/mole_health_bar_fill.tres"))
		health_bar_sprite.position = Vector3(0,2,0)

	_action_text = Label3D.new()
	_action_text.text = ""
	_action_text.visible = false
	_action_text.font_size = 50
	_action_text.position = Vector3(0, 2.5, 0) # height above mole
	_action_text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_action_text.outline_size = 15
	
	# Change visibility layer of action label so it's NOT visible on layer 1 and IS visible on layer 2
	# Layer 1 will contain everything visible in the minimap
	# (this is because the gridmap is on layer 1 by default and i don't think its layer can be changed)
	_action_text.set_layer_mask_value(1, false)
	# Layer 2 will contain everything visible in the "player" camera
	_action_text.set_layer_mask_value(2, true)
	
	_physics_body.add_child(_action_text)

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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if _action_text_timer > 0:
		_action_text_timer -= delta
	
	if _action_text_timer <= 0:
		_action_text.visible = false

	if is_enemy():
		enemy_spawn_logic(delta)
		scale_enemy_diff(Globals.TIME)
	else:
		for unit in friendly_units.keys():
			if friendly_units[unit]['cur_spawn_cooldown'] > 0.0:
				friendly_units[unit]['cur_spawn_cooldown'] -= delta

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

func _input(event: InputEvent) -> void:

	# Checking all static click events first
	super._input(event)

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
	
	#Check for ending the game prematuraly
	if not is_enemy():
		if event is InputEventKey and event.pressed:
			if event.keycode  == KEY_ESCAPE:
				surrendering = true
				self.take_damage(_max_health)

func take_damage(damage_val: int) -> void:
	super.take_damage(damage_val)
	health_bar.value = _health
	
func destroy_self() -> void:
	if surrendering:
		ending_scene.set_outcome(ending_scene.OUTCOME_TYPES.SURRENDER)
	elif is_enemy():
		ending_scene.set_outcome(ending_scene.OUTCOME_TYPES.VICTORY)
	else:
		ending_scene.set_outcome(ending_scene.OUTCOME_TYPES.DEFEAT)
	
	get_tree().root.add_child(ending_scene)
	super.destroy_self()

func receive_healing(healing_val: int) -> void:
	super.receive_healing(healing_val)
	health_bar.value = _health

func enemy_spawn_logic(delta: float)->void:
	for key in enemy_units.keys():
		var unit = enemy_units[key]
		enemy_units[key]["cur_spawn_cooldown"] = unit["cur_spawn_cooldown"]-delta
		if unit["cur_spawn_cooldown"] <= 0.0:
			spawn_unit(key)
			enemy_units[key]["cur_spawn_cooldown"] = unit["spawn_cooldown"]
			#NOTE put smth subtracting resources here if we wanna go that route
		

func scale_enemy_diff(time_passed: int):
	if time_passed > 180 and enemy_diff == 1: # 3 minutes
		enemy_units['Prospector']['spawn_cooldown'] = enemy_units['Prospector']['spawn_cooldown']-10.0
		enemy_diff=2
	elif time_passed > 360 and enemy_diff == 2: # 6 minutes
		enemy_units['Foreman']['spawn_cooldown'] = enemy_units['Foreman']['spawn_cooldown']-15.0
		enemy_diff=3
	elif time_passed > 600 and enemy_diff == 3: # 10 minutes
		enemy_units['Prospector']['spawn_cooldown'] = enemy_units['Prospector']['spawn_cooldown']-5.0
		enemy_diff=4
	elif time_passed > 1500 and enemy_diff == 4: # 25 minutes
		enemy_units['Foreman']['spawn_cooldown'] = enemy_units['Foreman']['spawn_cooldown']-15.0
		enemy_diff=5
	elif time_passed > 2700 and enemy_diff == 5: #45 minutes Only to pace out players that take an INSANE amount of time
		enemy_units['Prospector']['spawn_cooldown'] = enemy_units['Prospector']['spawn_cooldown']-5.0
		enemy_units['Foreman']['spawn_cooldown'] = enemy_units['Foreman']['spawn_cooldown']-5.0
		enemy_diff=6

func spawn_unit(unit_str: String) -> void:
	var spawned_unit: DynamicUnit = null
	if not is_enemy():
		spawned_unit = friendly_units[unit_str]["unit_type"].new()
		spawned_unit.set_enemy(false)
		Globals.ALLY_ARR.push_back(spawned_unit)
		if spawned_unit is MinerMole:
			spawned_unit._state = Globals.STATES.MINE
		else:
			spawned_unit._state = Globals.STATES.SENTRY
	else:
		spawned_unit = enemy_units[unit_str]["unit_type"].new()
		spawned_unit.set_enemy(true)
		Globals.ENEMY_ARR.push_back(spawned_unit)
		
		if unit_str == "Prospector":
			if randf_range(0.0,1.0) <= 0.80:
				spawned_unit._state = Globals.STATES.MOVING
			else:
				spawned_unit._state = Globals.STATES.SENTRY
		else:
			spawned_unit._state = Globals.STATES.MOVING
	spawned_unit.set_name(unit_str)
	get_parent().add_child(spawned_unit) #If you make it a child of this base you gotta make sure you scale correctly so they aint inperceptable
	spawned_unit.global_position = get_random_point(self.global_position + spawn_offset, spawn_radious)
	spawned_unit.scale = Vector3(0.5,0.5,0.5) #Can make this per unit if wanted, but for now seems pretty global

func request_spawn(unit_str: String) -> float:
	if not is_enemy():
		if friendly_units[unit_str]["cur_spawn_cooldown"] <= 0.0:
			for res in friendly_units[unit_str]["cost"].keys():
				if not Globals.check_valid_resource_transaction(res, friendly_units[unit_str]["cost"][res]):
					return -1.0
			for res in friendly_units[unit_str]["cost"].keys():
				if friendly_units[unit_str]["cost"][res] < 0:
					var new_val: int = Globals.update_resource(res, friendly_units[unit_str]["cost"][res])
			spawn_unit(unit_str)
			friendly_units[unit_str]["cur_spawn_cooldown"] = friendly_units[unit_str]["spawn_cooldown"]
			return friendly_units[unit_str]["cur_spawn_cooldown"]
	else:
		pass
	return -1.0

func get_random_point(origin: Vector3, radious: Vector3) -> Vector3:
	return origin + Vector3(rng.randf_range(radious.x * -1, radious.x),
	0.0, #cannot imagine we would ever want to change this but feel free
	rng.randf_range(radious.z * -1, radious.z))

func handle_level_up() -> void:
	if _level == 2:
		#recieve a 50% max health boost, heal 50%, recieve a -1 deduction in all unit costs
		var old_health = _max_health
		_max_health = ceil(_max_health * 1.50)
		receive_healing(_max_health-old_health)
		for unit in friendly_units.keys():
			for res in friendly_units[unit]['cost']:
				if friendly_units[unit]['cost'][res] < 0:
					friendly_units[unit]['cost'][res] = friendly_units[unit]['cost'][res]+1
	elif _level == 3:
		#Heal to full, reduce all spawn cooldowns by 50%,
		receive_healing(_max_health)
		for unit in friendly_units.keys():
			friendly_units[unit]['spawn_cooldown'] = friendly_units[unit]['spawn_cooldown']*0.50
	health_bar.max_value = _max_health
	health_bar.value = _health

#Base triggers upgrades
func trigger_upgrade(unit) -> int:
	var unit_class = unit.get_script().get_global_name()
	
	if unit is DynamicUnit:
		#check if the level up is legal
		var cur_level = Globals.dynamic_levels[unit_class]['cur_level']+1
		if cur_level not in Globals.dynamic_levels[unit_class]['cost'].keys():
			return -201
		for res in Globals.dynamic_levels[unit_class]['cost'][cur_level].keys():
			if not Globals.check_valid_resource_transaction(res, Globals.dynamic_levels[unit_class]['cost'][cur_level][res]):
				return -1
		
		#Registar the level up
		for res in Globals.dynamic_levels[unit_class]['cost'][cur_level].keys():
			Globals.update_resource(res, Globals.dynamic_levels[unit_class]['cost'][cur_level][res])
		Globals.dynamic_levels[unit_class]['cur_level'] = cur_level
		
		return cur_level
	elif unit is StaticUnit:
		#check if the level up is legal
		var cur_level = Globals.static_levels[unit_class]['cur_level']+1
		if cur_level not in Globals.static_levels[unit_class]['cost'].keys():
			return -201
		for res in Globals.static_levels[unit_class]['cost'][cur_level].keys():
			if not Globals.check_valid_resource_transaction(res, Globals.static_levels[unit_class]['cost'][cur_level][res]):
				return -1
		
		#Trigger the level up
		for res in Globals.static_levels[unit_class]['cost'][cur_level].keys():
			Globals.update_resource(res, Globals.static_levels[unit_class]['cost'][cur_level][res])
		if unit is Cannon and unit._level == 1: #special behvaoir
			var cannon = Cannon.new() 
			#cannon._state = Globals.STATES.SENTRY
			Globals.ALLY_ARR.push_back(cannon)
			cannon.set_name(unit_class)
			get_parent().add_child.call_deferred(cannon) #If you make it a child of this base you gotta make sure you scale correctly so they aint inperceptable
			#cannon.set_enemy(false) TODO Figure out why this crashes?
			cannon.global_position = self.global_position + cannon_pos
			unit = cannon
		unit.level_up()
		unit.handle_level_up()
		#Registar the level up
		Globals.static_levels[unit_class]['cur_level'] = cur_level
		return cur_level
	return -401

func show_action_text(text: String, color: Color):
	_action_text.text = text
	_action_text.modulate = color
	_action_text.visible = true
	_action_text_timer = 1.5
