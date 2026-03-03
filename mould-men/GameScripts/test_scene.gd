extends Node3D

# Units to test movement
@onready var mole  = $Mole
@onready var mole2 = $Mole2
@onready var enemy = $Enemy
@onready var enemy2 = $Enemy2

@onready var camera = $Camera3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	# Adding the allies to the ally array
	Globals.ALLY_ARR.push_back(mole)
	Globals.ALLY_ARR.push_back(mole2)

	# Adding the enemies to the enemy array
	Globals.ENEMY_ARR.push_back(enemy)
	Globals.ENEMY_ARR.push_back(enemy2)

func _process(_delta: float) -> void:

	# Take select off cooldown
	Globals.SELECT_COOLDOWN = false
