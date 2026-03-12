class_name GameCamera extends Camera3D

#Movement
var target: 					Unit = null
var tracking: 				bool = false
var dir:						Vector3 = Vector3(0,0,0)
@export var move_speed:		float = 5.0
var unit_offset:				Vector3 = Vector3(0.0, 8.235, 5.0)

#Zoom
@export var default_zoom:	float = 10.0
var zoom_bounds: 			Array[float] = [5.0, 15.0]
var zoom_incro:				float = 0.5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.size = default_zoom
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#Selected Unit stuff
	if target != null:
		global_position = target.get_global_pos()+unit_offset
	#Movement Stuff
	handle_camera_movement(delta)
	handle_camera_zoom()
	

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

func handle_camera_zoom() -> void:
	if Input.is_action_just_pressed('camera_zoom_in'):
		self.size = min(self.size+zoom_incro, zoom_bounds[1])
	elif Input.is_action_just_pressed('camera_zoom_out'):
		self.size = max(self.size-zoom_incro, zoom_bounds[0])
func unit_clicked_on(unit: Unit) -> void:
	target = unit
	self.size = default_zoom #reset zoom to have unit proporly in view
