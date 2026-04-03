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
	RALLYING
}

# Enum for the types of resources
enum RESOURCES {
	COAL,
	GOLD,
	DIAMOND,
	AMETHYST
}

# Total time that has elapsed
var TIME:							float			= 0.0

# Tracking the amount of resources the player has
var COAL_NUM:						int				= 999
var GOLD_NUM:						int				= 99
var DIAMOND_NUM:						int				= 0
var AMETHYST_NUM:					int				= 5

# Array that contains each of the enemies
var ENEMY_ARR: 						Array			= []

# Array that contains each of the allies
var ALLY_ARR:  						Array			= []

# Value that holds a selected unit
var SELECTED_UNIT: 					Unit 			= null

# Value of the height of the world floor
var FLOOR_HEIGHT: 					float			= 1.6

# Unit selection timer
var SELECT_COOLDOWN:				bool			= false

# Resource Locations
@onready var gold_label: RichTextLabel = get_tree().root.get_node("TestScene/GUI/ResourcesAndMinimap/Resources/GridContainer/MarginContainer/MarginContainer/HBoxContainer/GoldLabel")
@onready var coal_label: RichTextLabel = get_tree().root.get_node("TestScene/GUI/ResourcesAndMinimap/Resources/GridContainer/MarginContainer2/MarginContainer/HBoxContainer/CoalLabel")
@onready var amethyst_label: RichTextLabel = get_tree().root.get_node("TestScene/GUI/ResourcesAndMinimap/Resources/GridContainer/MarginContainer3/MarginContainer/HBoxContainer/AmethystLabel")
@onready var diamond_label: RichTextLabel = get_tree().root.get_node("TestScene/GUI/ResourcesAndMinimap/Resources/GridContainer/MarginContainer4/MarginContainer/HBoxContainer/DiamondLabel")

func update_resource(resource: RESOURCES, amt: int) -> int:
	if(resource == RESOURCES.COAL):
		COAL_NUM += amt
		return COAL_NUM
	elif(resource == RESOURCES.GOLD):
		GOLD_NUM += amt
		gold_label.text = str(GOLD_NUM)
		return GOLD_NUM
	elif(resource == RESOURCES.AMETHYST):
		AMETHYST_NUM += amt
		return AMETHYST_NUM
	elif(resource == RESOURCES.DIAMOND):
		DIAMOND_NUM += amt
		return DIAMOND_NUM
	return -1

func check_valid_resource_transaction(resource: RESOURCES, amt: int) -> bool:
	if(resource == RESOURCES.COAL and COAL_NUM - amt < 0):
		return false
	elif(resource == RESOURCES.GOLD and GOLD_NUM - amt < 0):
		return false
	elif(resource == RESOURCES.AMETHYST and AMETHYST_NUM - amt < 0):
		return false
	elif(resource == RESOURCES.DIAMOND and DIAMOND_NUM - amt < 0):
		return false
	return true
