extends Node

# Enum for the different states a unit can have
enum STATES {
	IDLE,
	MOVING,
	ATTACKING,
	SENTRY,
	BURROW,
	MINE,
	GROOVING,
	HEALING,
	MENDING,
	RALLYING,
	CANNONING,
	MORTARING
}

# Enum for the types of resources
enum RESOURCES {
	COAL,
	GOLD,
	DIAMOND,
	AMETHYST
}

#Can tweek these later, but I think the winning philosaphy here is 
#1. Moles and Minner Moles should have relativly cheep upgrades, Music and Doctor shouldnt. Base is medium cost, cannon is large
#2. Diamonds should be the main upgrade resource, gives them a unique identity
#3. You should allways say thank you to people who hold the door open for you, like who doesnt do that? Scum, thats who, scum.
var dynamic_levels = {
	'Mole': {
		'cur_level': 1,
		'cost': {
			2: {Globals.RESOURCES.COAL: 0, Globals.RESOURCES.GOLD: 0, Globals.RESOURCES.AMETHYST: 0, Globals.RESOURCES.DIAMOND: - 10},
			3: {Globals.RESOURCES.COAL: 0, Globals.RESOURCES.GOLD: 0, Globals.RESOURCES.AMETHYST: 0, Globals.RESOURCES.DIAMOND: - 30},
		},
		'description ': {
			2: 'A medium upgrade to health and a small one to damage',
			3: 'A large upgrade to health and a medium one to damage',
		}
	},
	'MinerMole': {
		'cur_level': 1,
		'cost': {
			2: {Globals.RESOURCES.COAL: 0, Globals.RESOURCES.GOLD: 0, Globals.RESOURCES.AMETHYST: 0, Globals.RESOURCES.DIAMOND: - 15},
			3: {Globals.RESOURCES.COAL: - 90, Globals.RESOURCES.GOLD: - 25, Globals.RESOURCES.AMETHYST: - 10, Globals.RESOURCES.DIAMOND: - 20},
		},
		'description ': {
			2: 'A medium upgrade to mining speed and a small one to health',
			3: 'A MASSIVE upgrade to mining speed',
		}
	},
	'MusicMole': {
		'cur_level': 1,
		'cost': {
			2: {Globals.RESOURCES.COAL: 0, Globals.RESOURCES.GOLD: 0, Globals.RESOURCES.AMETHYST: - 5, Globals.RESOURCES.DIAMOND: - 10},
			3: {Globals.RESOURCES.COAL: 0, Globals.RESOURCES.GOLD: - 100, Globals.RESOURCES.AMETHYST: 0, Globals.RESOURCES.DIAMOND: - 20}
		},
		'description ': {
			2: 'A medium increase in music radius',
			3: 'A medium upgrade to health and a large upgrade to music amplification',
		}
	},
	'DoctorMole': {
		'cur_level': 1,
		'cost': {
			2: {Globals.RESOURCES.COAL: 0, Globals.RESOURCES.GOLD: 0, Globals.RESOURCES.AMETHYST: 0, Globals.RESOURCES.DIAMOND: - 35},
			3: {Globals.RESOURCES.COAL: 0, Globals.RESOURCES.GOLD: 0, Globals.RESOURCES.AMETHYST: 0, Globals.RESOURCES.DIAMOND: - 80},
		},
		'description ': {
			2: 'Medium upgrades to health, damage, healing radius, and healing strength',
			3: 'A HUGE upgrade to healing radius and healing strength',
		}
	}
}

var static_levels = {
	'Base': {
		'cur_level': 1,
		'cost': {
			2: {Globals.RESOURCES.COAL: - 125, Globals.RESOURCES.GOLD: 0, Globals.RESOURCES.AMETHYST: 0, Globals.RESOURCES.DIAMOND: 0},
			3: {Globals.RESOURCES.COAL: - 250, Globals.RESOURCES.GOLD: 0, Globals.RESOURCES.AMETHYST: 0, Globals.RESOURCES.DIAMOND: - 10},
		},
		'description ': {
			2: 'A HUGE upgrade to max health, all units cost 1 less of each resource',
			3: 'Heal to full, reduce all spawn cooldowns by a HUGE amount. Now go WIN',
		}
	},
	'Cannon': {
		'cur_level': 1,
		'cost': {
			2: {Globals.RESOURCES.COAL: - 25, Globals.RESOURCES.GOLD: - 5, Globals.RESOURCES.AMETHYST: - 5, Globals.RESOURCES.DIAMOND: - 5},
			3: {Globals.RESOURCES.COAL: 0, Globals.RESOURCES.GOLD: - 25, Globals.RESOURCES.AMETHYST: 0, Globals.RESOURCES.DIAMOND: - 25},
			4: {Globals.RESOURCES.COAL: 0, Globals.RESOURCES.GOLD: 0, Globals.RESOURCES.AMETHYST: - 25, Globals.RESOURCES.DIAMOND: - 50},
		},
		'description ': {
			2: 'Unlock a powerful stationary cannon to protect your base',
			3: 'Medium increase to attack speed, heal to full',
			4: 'large increase to attack speed, medium damage increase, heal to full',
		}
	}
}

# Total time that has elapsed
var TIME: float = 0.0

# Tracking the amount of resources the player has
var COAL_NUM: int = 999 # 100
var GOLD_NUM: int = 999 # 15
var DIAMOND_NUM: int = 999 # 0
var AMETHYST_NUM: int = 999 # 0

# Array that contains each of the enemies
var ENEMY_ARR: Array = []

# Array that contains each of the allies
var ALLY_ARR: Array = []

# Value that holds a selected unit
var SELECTED_UNIT: Unit = null

# Value of the height of the world floor
var FLOOR_HEIGHT: float = 1.6

# Unit selection timer
var SELECT_COOLDOWN: bool = false

# Resource Locations
@onready var gold_label: RichTextLabel = get_tree().root.get_node("CaveLevel/GUI/Resources/GridContainer/HBoxContainer/GoldLabel")
@onready var coal_label: RichTextLabel = get_tree().root.get_node("CaveLevel/GUI/Resources/GridContainer/HBoxContainer2/CoalLabel")
@onready var amethyst_label: RichTextLabel = get_tree().root.get_node("CaveLevel/GUI/Resources/GridContainer/HBoxContainer3/AmethystLabel")
@onready var diamond_label: RichTextLabel = get_tree().root.get_node("CaveLevel/GUI/Resources/GridContainer/HBoxContainer4/DiamondLabel")

func _ready() -> void:
	print(get_tree().root.get_children()[0].get_name())

func update_resource(resource: RESOURCES, amt: int) -> int:
	if (resource == RESOURCES.COAL):
		COAL_NUM += amt
		coal_label.text = str(COAL_NUM)
		return COAL_NUM
	elif (resource == RESOURCES.GOLD):
		GOLD_NUM += amt
		gold_label.text = str(GOLD_NUM)
		return GOLD_NUM
	elif (resource == RESOURCES.AMETHYST):
		AMETHYST_NUM += amt
		amethyst_label.text = str(AMETHYST_NUM)
		return AMETHYST_NUM
	elif (resource == RESOURCES.DIAMOND):
		DIAMOND_NUM += amt
		diamond_label.text = str(DIAMOND_NUM)
		return DIAMOND_NUM
	return -1

func check_valid_resource_transaction(resource: RESOURCES, amt: int) -> bool:
	if (resource == RESOURCES.COAL and COAL_NUM + amt < 0):
		return false
	elif (resource == RESOURCES.GOLD and GOLD_NUM + amt < 0):
		return false
	elif (resource == RESOURCES.AMETHYST and AMETHYST_NUM + amt < 0):
		return false
	elif (resource == RESOURCES.DIAMOND and DIAMOND_NUM + amt < 0):
		return false
	return true
