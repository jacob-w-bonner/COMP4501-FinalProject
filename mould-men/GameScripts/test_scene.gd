extends Node3D

# Units to test movement
@onready var mole  = $Mole
@onready var mole2 = $Mole2
@onready var enemy = $Enemy
@onready var enemy2 = $Enemy2
@onready var resource = $Resource
@onready var resource2 = $Resource2
@onready var miner_mole  = $MinerMole
@onready var music_mole  = $MusicMole
@onready var doctor_mole  = $DoctorMole
@onready var cannon  = $Cannon

@onready var armadillo_2025 = $Armadillo

@onready var camera = $Camera3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	# Adding the allies to the ally array
	Globals.ALLY_ARR.push_back(mole)
	Globals.ALLY_ARR.push_back(mole2)
	Globals.ENEMY_ARR.push_back(resource)
	Globals.ALLY_ARR.push_back(resource2)
	Globals.ALLY_ARR.push_back(miner_mole)
	Globals.ALLY_ARR.push_back(music_mole)
	Globals.ALLY_ARR.push_back(doctor_mole)
	Globals.ALLY_ARR.push_back(cannon)
	
	Globals.ALLY_ARR.push_back(armadillo_2025)

	# Adding the enemies to the enemy array
	Globals.ENEMY_ARR.push_back(enemy)
	Globals.ENEMY_ARR.push_back(enemy2)

func _process(_delta: float) -> void:

	# Take select off cooldown
	Globals.SELECT_COOLDOWN = false

	# Incrementing the time passed
	Globals.TIME			+= _delta
