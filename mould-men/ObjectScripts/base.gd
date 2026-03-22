class_name Base extends StaticUnit

#NOTE as 4 resourses seems a lot for a game of this size I am assuming that we are only going to have Coal, Gold, and Amethyst
var friendly_units = {
	"mole" : {
		"cost" : { "coal" : 10, "gold" : 0, "amethyst" : 0},
		"spawn_cooldown" : 2.0,
		"cur_spawn_cooldown" : 0.0
	},
	"miner_mole" : {
		"cost" : { "coal" : 15, "gold" : 1, "amethyst" : 0},
		"spawn_cooldown" : 5.0,
		"cur_spawn_cooldown" : 0.0
	}
}
enum enemy_units {
	
}



# Called when the node enters the scene tree for the first time.
func _ready():
	# Instantiating parent first
	super._ready()
	
	# Setting the mesh
	_mesh.mesh							= (load("res://Assets/StaticAssets/apartment.tres") as Mesh).duplicate()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_enemy():
		pass
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

func spawn(unit_str) -> void:
	#Put the actual spawning logic here
	pass

func request_spawn(unit_str: String) -> float:
	if friendly_units[unit_str]["cur_spawn_cooldown"] <= 0.0:
		spawn(unit_str)
		friendly_units[unit_str]["cur_spawn_cooldown"] = friendly_units[unit_str]["spawn_cooldown"]
		return friendly_units[unit_str]["cur_spawn_cooldown"]
	return -1.0
