class_name Base extends StaticUnit

#NOTE as 4 resourses seems a lot for a game of this size I am assuming that we are only going to have Coal, Gold, and Amethyst (and honestly we might drop Amethyst)
var friendly_units = {
	"mole" : {
		"cost" : { Globals.RESOURCES.COAL : -10, Globals.RESOURCES.GOLD : 0, Globals.RESOURCES.AMETHYST : 0 },
		"spawn_cooldown" : 2.0,
		"cur_spawn_cooldown" : 0.0,
		"unit_type" : Mole,
	},
	"miner_mole" : {
		"cost" : { Globals.RESOURCES.COAL : -15, Globals.RESOURCES.GOLD : -1, Globals.RESOURCES.AMETHYST : 0 },
		"spawn_cooldown" : 5.0,
		"cur_spawn_cooldown" : 0.0,
		"unit_type" : MinerMole,
	},
	"doctor_mole" : {
		"cost" : { Globals.RESOURCES.COAL : -22, Globals.RESOURCES.GOLD : -3, Globals.RESOURCES.AMETHYST : 0 },
		"spawn_cooldown" : 5.0,
		"cur_spawn_cooldown" : 0.0,
		"unit_type" : DoctorMole,
	},
	"music_mole" : {
		"cost" : { Globals.RESOURCES.COAL : -3, Globals.RESOURCES.GOLD : -5, Globals.RESOURCES.AMETHYST : -1 },
		"spawn_cooldown" : 10.0,
		"cur_spawn_cooldown" : 0.0,
		"unit_type" : MusicMole,
	}
}
var enemy_units = {
	"prospector" : {
		"spawn_cooldown" : 9.0,
		"cur_spawn_cooldown" : 20.0, 
		"unit_type" : Prospector,
	},
	"foreman" : {
		"spawn_cooldown" : 22.0,
		"cur_spawn_cooldown" : 60.0,
		"unit_type" : Foreman,
	}
}
@onready var resources_container: GridContainer = $"../CanvasLayer/Resources"

@export var spawn_offset: Vector3 = Vector3(6.0, Globals.FLOOR_HEIGHT,0.0)
@export var spawn_radious: Vector3 = Vector3(0.5, 0.0, 2.5)
var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	# Instantiating parent first
	super._ready()
	
	# Set avoidence radious for units
	# Setting the mesh
	if is_enemy():
		_nav_obs.radius = 30
		_nav_obs.global_position = self.global_position + Vector3(2,Globals.FLOOR_HEIGHT,1)
		_mesh.mesh							= (load("res://Assets/StaticAssets/apartment.tres") as Mesh).duplicate()
	else:
		_nav_obs.radius = 0.9
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
		Globals.ENEMY_ARR.push_back(spawned_unit)
		
	else:
		spawned_unit = enemy_units[unit_str]["unit_type"].new()
		spawned_unit.set_enemy(true)
		Globals.ALLY_ARR.push_back(spawned_unit)
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
					#if(res == Globals.RESOURCES.COAL):
						#resources_container.get_node("CoalLabel").text = str(new_val)
					#elif(res == Globals.RESOURCES.GOLD):
						#resources_container.get_node("GoldLabel").text = str(new_val)
					#elif(res == Globals.RESOURCES.AMETHYST):
						#resources_container.get_node("AmethystLabel").text = str(new_val)
					#elif(res == Globals.RESOURCES.DIAMOND):
						#resources_container.get_node("DiamondLabel").text = str(new_val)
					
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

	pass # Replace with function body.
