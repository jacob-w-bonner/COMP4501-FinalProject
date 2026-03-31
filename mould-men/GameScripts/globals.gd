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
var COAL_NUM:						int				= 0
var GOLD_NUM:						int				= 0
var DIAMOND_NUM:					int				= 0
var AMETHYST_NUM:					int				= 0

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
