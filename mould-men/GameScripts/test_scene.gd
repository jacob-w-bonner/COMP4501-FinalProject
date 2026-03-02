extends Node3D

# Units to test movement
@onready var mole  = $Mole
@onready var mole2 = $Mole2
@onready var enemy = $Enemy

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	# Adding the enemy to the enemy array
	Globals.ENEMY_ARR.push_back(enemy)

# Called to move the unit to a location
func move(target: Unit) -> void:
	pass
