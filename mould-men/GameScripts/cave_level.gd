extends Node3D

# Units to test movement
@onready var mole  = $Units/Mole
@onready var mole2 = $Units/Mole2
@onready var enemy = $Units/Prospector
@onready var enemy2 = $Units/Foreman
@onready var resource = $Units/Resource
@onready var resource2 = $Units/Resource2
@onready var miner_mole  = $Units/MinerMole
@onready var music_mole  = $Units/MusicMole
@onready var doctor_mole  = $Units/DoctorMole

@onready var mole_base  = $Units/MoleBase
@onready var oliver_base  = $Units/OliverBase


@onready var camera = $Camera3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Adding the bases to the arrays
	Globals.ALLY_ARR.push_back(mole_base)
	Globals.ENEMY_ARR.push_back(oliver_base)
	

	# Adding the allies to the ally array
	Globals.ALLY_ARR.push_back(mole)
	Globals.ALLY_ARR.push_back(mole2)
	Globals.ALLY_ARR.push_back(resource)
	Globals.ALLY_ARR.push_back(resource2)
	Globals.ALLY_ARR.push_back(miner_mole)
	Globals.ALLY_ARR.push_back(music_mole)
	Globals.ALLY_ARR.push_back(doctor_mole)

	# Adding the enemies to the enemy array
	Globals.ENEMY_ARR.push_back(enemy)
	Globals.ENEMY_ARR.push_back(enemy2)

func _process(_delta: float) -> void:

	# Take select off cooldown
	Globals.SELECT_COOLDOWN = false

	# Incrementing the time passed
	Globals.TIME			+= _delta
	

#Capture input for testing funtionality
func _input(event: InputEvent) -> void:
	return #NOTE remove this if you want to test some arbitrary funtionality
	if event is InputEventKey and event.pressed:
		if event.keycode  == KEY_Z:
			print("taking damage")
			mole_base.take_damage(400)
		elif event.keycode  == KEY_X:
			print("taking healing")
			mole_base.receive_healing(400)
		elif event.keycode  == KEY_C:
			print("Upgrading")
			mole_base.trigger_upgrade(mole_base)
