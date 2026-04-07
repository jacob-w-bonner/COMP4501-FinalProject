extends Node3D

@onready var units: Node3D = $Units
@onready var resources: Node3D = $Resources
@onready var camera = $Camera3D

#@onready var mole_base  = $Units/MoleBase
#@onready var oliver_base  = $Units/OliverBase

func _ready() -> void:
	#Adding bases, dynamic units to the arrays
	var children = units.get_children()
	for child in children:
		if child._is_enemy:
			Globals.ENEMY_ARR.push_back(child)
		elif not child._is_enemy:
			Globals.ALLY_ARR.push_back(child)
	
	# Add resources to the ally array
	var res = resources.get_children()
	for r in res:
		Globals.ALLY_ARR.push_back(r)

func _process(_delta: float) -> void:

	# Take select off cooldown
	Globals.SELECT_COOLDOWN = false

	# Incrementing the time passed
	Globals.TIME			+= _delta

#Capture input for testing funtionality
#func _input(event: InputEvent) -> void:
	#return #NOTE remove this if you want to test some arbitrary funtionality
	#if event is InputEventKey and event.pressed:
		#if event.keycode  == KEY_Z:
			#print("taking damage")
			#mole_base.take_damage(400)
		#elif event.keycode  == KEY_X:
			#print("taking healing")
			#mole_base.receive_healing(400)
		#elif event.keycode  == KEY_C:
			#print("Upgrading")
			#mole_base.trigger_upgrade(mole_base)
