extends Button

@onready var time_label: Label = $Counter/Value
@export var base: Base = null
@export var cooldown: float
const PLAIN_SQUARE = preload("uid://cbivaag7skt2g")

# Code remixed from this tutorial: https://kidscancode.org/godot_recipes/3.x/ui/cooldown_button/index.html

func _ready():
	cooldown = base.request_spawn(self.name)
	$Timer.wait_time = cooldown
	time_label.hide()
	$Sweep.texture_progress = PLAIN_SQUARE
	$Sweep.value = 0
	set_process(false)

func _process(_delta):
	time_label.text = "%3.1f" % $Timer.time_left
	$Sweep.value = int(($Timer.time_left / cooldown) * 100)

func _on_pressed() -> void:
	base.request_spawn(self.name)
	disabled = true
	set_process(true)
	$Timer.start()
	time_label.show()

func _on_timer_timeout() -> void:
	$Sweep.value = 0
	disabled = false
	time_label.hide()
	set_process(false)
