extends Node

@export var base: Base = null

var units = {
	"mole" : false,
	"miner_mole" : false
}
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
# Called to handle input events
func _input(event: InputEvent) -> void:
	# Checking for left mouse click
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		for unit in units.keys():
			if units[unit]:
				print("Spawned ", unit)
				var cool_down_time: float = base.request_spawn(unit)
				if cool_down_time != -1:
					pass
					#TODO Then it went through, visualize this with a simple partial opacity shader that takes cool_down_time seconds to clear up

func _on_mole_mouse_entered():
	units['mole'] = true

func _on_mole_mouse_exited():
	units['mole'] = false

func _on_miner_mouse_entered():
	units['miner_mole'] = true

func _on_miner_mouse_exited():
	units['miner_mole'] = false
