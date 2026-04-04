extends Node3D

func _ready() -> void:
	var children = get_children()
	
	for child in children:
		if child is OmniLight3D:
			# Change visibility layer of all lights so they're NOT visible on layer 1 and ARE visible on layer 2
			# Layer 1 will contain everything visible in the minimap
			# (this is because the gridmap is on layer 1 by default and i don't think its layer can be changed)
			child.set_layer_mask_value(1, false)
			# Layer 2 will contain everything visible in the "player" camera
			child.set_layer_mask_value(2, true)
