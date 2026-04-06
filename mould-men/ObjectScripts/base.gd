class_name Base extends StaticUnit

#NOTE as 4 resourses seems a lot for a game of this size I am assuming that we are only going to have Coal, Gold, and Amethyst (and honestly we might drop Amethyst)
var friendly_units = {
	"Mole" : {
		"cost" : { Globals.RESOURCES.COAL : -10, Globals.RESOURCES.GOLD : 0, Globals.RESOURCES.AMETHYST : 0, Globals.RESOURCES.DIAMOND : 0 },
		"spawn_cooldown" : 2.0,
		"cur_spawn_cooldown" : 0.0,
		"unit_type" : Mole,
	},
	"MinerMole" : {
		"cost" : { Globals.RESOURCES.COAL : -15, Globals.RESOURCES.GOLD : -5, Globals.RESOURCES.AMETHYST : 0, Globals.RESOURCES.DIAMOND : 0 },
		"spawn_cooldown" : 5.0,
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
		"cost" : { Globals.RESOURCES.COAL : 0, Globals.RESOURCES.GOLD : -25, Globals.RESOURCES.AMETHYST : -5, Globals.RESOURCES.DIAMOND : 0 },
		"spawn_cooldown" : 10.0,
		"cur_spawn_cooldown" : 0.0,
		"unit_type" : MusicMole,
	}
}
var enemy_units = {
	"Prospector" : {
		"spawn_cooldown" : 9.0,
		"cur_spawn_cooldown" : 20.0, 
		"unit_type" : Prospector,
	},
	"Foreman" : {
		"spawn_cooldown" : 22.0,
		"cur_spawn_cooldown" : 60.0,
		"unit_type" : Foreman,
	}
}

@export var spawn_offset: Vector3 = Vector3(6.0, Globals.FLOOR_HEIGHT, 0.0)
@export var cannon_pos: Vector3 = Vector3(2.0, Globals.FLOOR_HEIGHT, -5.0)
@export var spawn_radious: Vector3 = Vector3(0.5, 0.0, 2.5)
var rng = RandomNumberGenerator.new()

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
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_enemy():
		enemy_spawn_logic(delta)
	else:
		for unit in friendly_units.keys():
			if friendly_units[unit]['cur_spawn_cooldown'] > 0.0:
				friendly_units[unit]['cur_spawn_cooldown'] -= delta

func _input(event: InputEvent) -> void:
	# Checking all static click events first
	super._input(event)

	# Checking for double click left mouse click
	if event is InputEventMouseButton and event.double_click and event.button_index == MOUSE_BUTTON_LEFT:
		if self._is_hovered and !self.is_enemy() and _state: 
			#TODO, we need to make static units work with mouse_entered and is_hovered and make the spawning ui appear and disappear on duble click or smth
			print(self.name)
			return

func enemy_spawn_logic(delta: float)->void:
	for key in enemy_units.keys():
		var unit = enemy_units[key]
		enemy_units[key]["cur_spawn_cooldown"] = unit["cur_spawn_cooldown"]-delta
		if unit["cur_spawn_cooldown"] <= 0.0:
			spawn_unit(key)
			enemy_units[key]["cur_spawn_cooldown"] = unit["spawn_cooldown"]
			#TODO put smth subtracting resources here if we wanna go that route
		


func spawn_unit(unit_str: String) -> void:
	#TODO use a collision box or smth so that you can tell when you are about to spawn a mole on a mole, and avoid that, could also give them initial move orders
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
		if randf_range(0.0,1.0) >= 0.80:
			spawned_unit._state = Globals.STATES.MOVING
		else:
			spawned_unit._state = Globals.STATES.SENTRY
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

#Base triggers upgrades
func trigger_upgrade(unit) -> int:
	var unit_class = unit.get_script().get_global_name()
	
	if unit is DynamicUnit:
		#check if the level up is legal
		var cur_level = Globals.dynamic_levels[unit_class]['cur_level']+1
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
		for res in Globals.static_levels[unit_class]['cost'][cur_level].keys():
			if not Globals.check_valid_resource_transaction(res, Globals.static_levels[unit_class]['cost'][cur_level][res]):
				return -1
		
		#Trigger the level up
		for res in Globals.static_levels[unit_class]['cost'][cur_level].keys():
			Globals.update_resource(res, Globals.static_levels[unit_class]['cost'][cur_level][res])
		if unit is Cannon and unit._level == 1: #special behvaoir
			var cannon = Cannon.new() 
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
