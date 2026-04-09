extends Button

@onready var time_label: Label = $Counter/Value
@export var base: Base = null
@export var cooldown: float
const PLAIN_SQUARE = preload("uid://cbivaag7skt2g")
var process: bool = false

# Code remixed from this tutorial: https://kidscancode.org/godot_recipes/3.x/ui/cooldown_button/index.html

func _ready():
	$Timer.wait_time = cooldown
	time_label.hide()
	$Sweep.texture_progress = PLAIN_SQUARE
	$Sweep.value = 0
	process = false
	# Disable buttons for things you can't afford
	if base != null:
		disabled = !base.is_spawn_possible(self.name)

func _process(_delta):
	if base != null:
		disabled = !base.is_spawn_possible(self.name)
	if process:
		time_label.text = "%3.1f" % $Timer.time_left
		$Sweep.value = int(($Timer.time_left / cooldown) * 100)

func _on_pressed() -> void:
	if base != null:
		base.request_spawn(self.name)
	disabled = true
	process = true
	$Timer.start()
	time_label.show()

func _on_timer_timeout() -> void:
	$Sweep.value = 0
	disabled = false
	time_label.hide()
	process = false
	if base != null:
		disabled = !base.is_spawn_possible(self.name)

func _on_mouse_entered() -> void:
	# Populate costs based on global values
	if base != null:
		var dict = base.get_spawn_costs(self.name)
		%GoldCost.text = str(dict.get(1))
		%CoalCost.text = str(dict.get(0))
		%AmethystCost.text = str(dict.get(2))
		%DiamondCost.text = str(dict.get(3))
		%Costs.show()

func _on_mouse_exited() -> void:
	%Costs.hide()
