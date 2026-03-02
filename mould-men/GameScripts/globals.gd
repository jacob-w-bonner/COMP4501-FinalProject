extends Node

# Enum for the different states a unit can have
enum STATES {
	IDLE,
	MOVING,
	ATTACKING,
	SENTRY
}

# Array that contains each of the enemies
var ENEMY_ARR: Array = []

# Array that contains each of the allies
var ALLY_ARR:  Array = []

# Called to determine the closest opposing unit to the given position
func closest_opponent(unit: Unit) -> Unit:

	# Values that will contain the closest enemy position and distance
	var closest_pos  = Vector3(10000.0, 10000.0, 10000.0)
	var closest_dist = 10000.0
	var closest_unit = null

	# If the unit is an enemy then check for the closest ally
	if unit.is_enemy():

		# First make sure that there are allies to track
		if ALLY_ARR.size() == 0:
			return null

		# Check the array for the closest ally
		for ally in ALLY_ARR:
			var distance = ally.global_position.distance_to(unit.get_global_pos())
			if distance < closest_dist:
				closest_pos  = ally.global_position
				closest_dist = distance
				closest_unit = ally

	# Otherwise check for the closest enemy
	else:

		# First make sure that there are enemies to track
		if ENEMY_ARR.size() == 0:
			return null

		# Check the array for the closest enemy
		for enemy in ENEMY_ARR:
			var distance = enemy.global_position.distance_to(unit.get_global_pos())
			if distance < closest_dist:
				closest_pos  = enemy.global_position
				closest_dist = distance
				closest_unit = enemy

	return closest_unit
