class_name Diamond extends ResourceVein

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	# Instantiating parent first
	super._ready()

	# Setting the resource type
	_res_type 					= Globals.RESOURCES.DIAMOND

	# Setting the resource colour
	_res_col					= Color(0.3059, 0.8863, 0.9255, 1.0)

	# Instantiating the rock base
	_res_mesh.mesh				= (load("res://Assets/ResourceAssets/ResourceBase/ResourceRock2.tres") as Mesh).duplicate()
	_res_mesh.scale				= Vector3(0.5, 0.5, 0.5)
	_res_mesh.rotation_degrees	= Vector3(-179, 0.0, 0.0)
	_res_mesh.position			= Vector3(0.112, -0.05, -0.72)

	# Setting the coal initial values
	_res_max					= _DIAMOND_MAX
	_res_amount					= _res_max

	# Grabbing the material from each surface for use in the shader
	for i in range(_res_mesh.mesh.get_surface_count()):

		# Getting the standard material from the surface
		var standard_mat 	= _res_mesh.mesh.surface_get_material(i)

		# Only transform if what was retrieved is a standard material
		if standard_mat is StandardMaterial3D:

			# Initializing shader material for the mesh
			var shader_mat		= ShaderMaterial.new()
			shader_mat.shader 	= _shader

			# Setting the shader surface colour to the old material
			shader_mat.set_shader_parameter("tex", standard_mat.albedo_texture)
			shader_mat.set_shader_parameter("true_col", _res_col)
			shader_mat.set_shader_parameter("modify_col", true)
			_res_mesh.mesh.surface_set_material(i, shader_mat)
	
	# Set colour of OmniLight
	light.light_color = Color(0.183, 0.77, 0.807, 1.0)
