class_name GameCamera extends Camera3D

#Movement
var target: 					Unit = null
var moving_to_target: 		bool = false
var zooming_to_target:		bool = false
var moving_to_target_max_speed: float = 60.0
var moving_to_target_speed:	float = 60.0
var zooming_to_target_speed:	float = 40.0
var dir:						Vector3 = Vector3(0,0,0)
@export var move_speed:		float = 15.0
var unit_offset:				Vector3 = Vector3(0.0, 20, 17.0)

#Zoom
@export var default_zoom:	float = 20.0
var zoom_bounds: 			Array[float] = [5.0, 25.0]
var zoom_incro:				float = 0.5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.size = default_zoom

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#Movement Stuff
	handle_camera_movement(delta)
	handle_camera_zoom()
	
	#Smooth transition to target Stuff
	if target != null and (moving_to_target or zooming_to_target):
		if moving_to_target:
			var dist_to_target = ((target.get_global_pos()+unit_offset) - global_position)
			dist_to_target.y = 0.0
			
			if dist_to_target.length() < 0.01:
				moving_to_target_speed = moving_to_target_max_speed
				global_position = ((target.get_global_pos() + unit_offset) * Vector3(1,0,1)) + (self.global_position * Vector3(0,1,0))
				moving_to_target = false
			else:
				while will_overshoot(dist_to_target, delta):
					#If the camera is about to overshoot, cut the speed and check again
					moving_to_target_speed /= 2
				self.global_position+= dist_to_target.normalized() * moving_to_target_speed * delta
		if zooming_to_target:
			if abs(self.size - default_zoom) < 0.5:
				self.size = default_zoom #reset zoom to have unit proporly in view
				zooming_to_target = false
			else:
				var zoom_dir = (default_zoom - self.size) / abs(self.size - default_zoom)
				self.size += zooming_to_target_speed * zoom_dir * delta

func handle_camera_movement(delta: float) -> void:
	if Input.is_action_just_pressed('camera_left'):
		dir+= Vector3.LEFT
	if Input.is_action_just_pressed('camera_right'):
		dir+= Vector3.RIGHT
	if Input.is_action_just_pressed('camera_forward'):
		dir+= Vector3.FORWARD
	if Input.is_action_just_pressed('camera_back'):
		dir+= Vector3.BACK
	if Input.is_action_just_released('camera_left'):
		dir-= Vector3.LEFT
	if Input.is_action_just_released('camera_right'):
		dir-= Vector3.RIGHT
	if Input.is_action_just_released('camera_forward'):
		dir-= Vector3.FORWARD
	if Input.is_action_just_released('camera_back'):
		dir-= Vector3.BACK
	if dir != Vector3(0,0,0): #If we are moving stop focusing on unit
		global_position += dir.normalized() * move_speed * delta * max(self.size / (zoom_bounds[1] / 2), 0.5)
		target = null

func handle_camera_zoom() -> void:
	if Input.is_action_just_pressed('camera_zoom_in'):
		self.size = min(self.size+zoom_incro, zoom_bounds[1])
	elif Input.is_action_just_pressed('camera_zoom_out'):
		self.size = max(self.size-zoom_incro, zoom_bounds[0])
func unit_clicked_on(unit: Unit) -> void:
	target = unit
	moving_to_target = true
	zooming_to_target = true


func will_overshoot(dist_to_target: Vector3, delta: float) -> bool:
	var new_loc = self.global_position + (dist_to_target.normalized() * moving_to_target_speed * delta)
	var new_dist_to_target = ((target.get_global_pos()+unit_offset) - new_loc)
	new_dist_to_target.y = 0.0
	
	if new_dist_to_target.normalized() * dist_to_target.normalized() < Vector3(0,0,0):
		return true
	return false
