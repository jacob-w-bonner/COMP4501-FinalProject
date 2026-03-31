class_name Explosion extends Node3D

@onready var debris = $Debris
@onready var smoke  = $Smoke
@onready var fire   = $Fire

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.scale = Vector3(0.5, 0.5, 0.5)
	explode()

# This function will delete the explosion at the right time
func explode() -> void:

	# Making sure particles are emitting
	debris.emitting = true
	smoke.emitting	= true
	fire.emitting	= true

	await get_tree().create_timer(2.0).timeout
	self.queue_free()
