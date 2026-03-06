class_name MusicMole extends Mole

# Properties that track music playing
var 		_is_playing:		bool			= false
var 		_music_radius:		float			= 10.0
var 		_music_buff:		float			= 1.5
const		_MUSIC_DURATION:	float			= 1.0
var			_music_time:		float			= 0.0
var			_buff_given:		bool			= false
var 		_dance_direction:	float			= 10.0
var			_units_buffed:		Array[Mole]		= []
var			_music_particles:	GPUParticles3D	= null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	# Instantiating parent first
	super._ready()

	# Moles are not enemies
	#_is_enemy							= false

	# Setting the mesh
	_mesh.mesh							= (load("res://Assets/MoleAssets/MusicMole/MusicMole.tres") as Mesh).duplicate()

	# Grabbing the material from each surface for use in the shader
	for i in range(_mesh.mesh.get_surface_count()):

		# Getting the standard material from the surface
		var standard_mat 	= _mesh.mesh.surface_get_material(i)

		# Only transform if what was retrieved is a standard material
		if standard_mat is StandardMaterial3D:

			# Initializing shader material for the mesh
			var shader_mat		= ShaderMaterial.new()
			shader_mat.shader 	= _shader

			# Setting the shader surface colour to the old material
			shader_mat.set_shader_parameter("tex", standard_mat.albedo_texture)
			_mesh.mesh.surface_set_material(i, shader_mat)

# Called to handle input events
func _input(event: InputEvent) -> void:

	# Checking all mole click events first
	super._input(event)

	# Checking for right mouse click
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and self._is_hovered:

		# Toggling music
		self._is_playing = !_is_playing

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

	# Running the standard mole process first
	super._process(delta)

# Called to handle the grooving action
func grooving(delta: float) -> void:

	# Checking to see if each ally should be buffed
	for ally in Globals.ALLY_ARR:

		# Only buff moles
		if ally is Mole:

			# If the ally 

# Getter for if the music is playing
func is_playing() -> bool:
	return _is_playing

# Called when movement is finished
func nav_finish() -> void:

	# If the mole is playing music when it reaches a target then keep grooving
	if _closest_op is Mole and self.is_playing():
		_state		= Globals.STATES.GROOVING

	# If the closest target is an enemy then attack it
	elif _closest_op.is_enemy():
		_state		= Globals.STATES.ATTACKING

	# Move towards the closest target
	else:
		_closest_op = closest_opponent(self)
		_state		= Globals.STATES.MOVING
