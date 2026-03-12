class_name GameCamera extends Camera3D

var target: 			Unit = null
var tracking: 		bool = false
var dir:				Vector3 = Vector3(0,0,0)
@export var move_speed:		float = 5.0
var unit_offset:		Vector3 = Vector3(0.0, 8.235, 5.0)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#Selected Unit stuff
	if target != null:
		global_position = target.get_global_pos()+unit_offset
	#Movement Stuff
	handle_camera_movement(delta)
	

func handle_camera_movement(delta: float) -> void:
	if Input.is_action_just_pressed('camera_left'):
		dir+= Vector3.LEFT
	elif Input.is_action_just_pressed('camera_right'):
		dir+= Vector3.RIGHT
	elif Input.is_action_just_pressed('camera_forward'):
		dir+= Vector3.FORWARD
	elif Input.is_action_just_pressed('camera_back'):
		dir+= Vector3.BACK
	elif Input.is_action_just_released('camera_left'):
		dir-= Vector3.LEFT
	elif Input.is_action_just_released('camera_right'):
		dir-= Vector3.RIGHT
	elif Input.is_action_just_released('camera_forward'):
		dir-= Vector3.FORWARD
	elif Input.is_action_just_released('camera_back'):
		dir-= Vector3.BACK
	if dir != Vector3(0,0,0): #If we are moving stop focusing on unit
		global_position += dir.normalized() * move_speed * delta
		target = null

func unit_clicked_on(unit: Unit) -> void:
	target = unit
