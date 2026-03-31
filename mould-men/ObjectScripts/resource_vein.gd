@abstract
class_name ResourceVein extends StaticUnit

# The type of resource it is
var _res_type:				Globals.RESOURCES 	= 0

# The colour of the resource
var _res_col:				Color				= Color(0.0, 0.0, 0.0, 1.0)

# A mesh for the resource part
var _res_mesh:				MeshInstance3D		= null

# Constants for the resource maximums
var _COAL_MAX:				int					= 100
var _GOLD_MAX:				int					= 50
var _DIAMOND_MAX:			int					= 25
var _AMYTHEST_MAX:			int					= 10

# Shader for the resource veins
@onready var _shader:		Shader				= preload("res://Shaders/resource.gdshader")

# How much of the resource is in the vein
@export var _res_max: 		int					= 100
@export var _res_amount: 	int					= 100

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	# Instantiating parent first
	super._ready()

	# Resource veins are for allies
	if self.name == "Resource":
		_is_enemy							= true
	_health = 50

	# Setting the rock base
	_mesh.mesh							= (load("res://Assets/ResourceAssets/RockBase/BaseRock.tres") as Mesh).duplicate()
	_mesh.rotation_degrees				= Vector3(90.0, 0.0, 0.0)

	# Instantiating the resource mesh mesh
	_res_mesh							= MeshInstance3D.new()
	_mesh.add_child(_res_mesh)

	# Instantiating the collision shape
	_collision_shape					= CollisionShape3D.new()
	_physics_body.add_child(_collision_shape)

	# Finding the size of the collision box
	var bounding_box					= _mesh.mesh.get_aabb()
	var box_size						= bounding_box.size

	# Creating a collision box for the object
	var box_shape						= BoxShape3D.new()
	box_shape.size						= box_size

	# Setting the collision box
	_collision_shape.shape				= box_shape
	_collision_shape.position 			= bounding_box.get_center()

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
			shader_mat.set_shader_parameter("modify_col", false)
			_mesh.mesh.surface_set_material(i, shader_mat)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

	# Setting the shader parameters that need to be set by frame
	for i in range(_mesh.mesh.get_surface_count()):

		# Sending the hover value
		_mesh.mesh.surface_get_material(i).set_shader_parameter("is_hovered", _is_hovered)
		_res_mesh.mesh.surface_get_material(i).set_shader_parameter("is_hovered", _is_hovered)

		# Send health and resource percentage to affect colouring
		_mesh.mesh.surface_get_material(i).set_shader_parameter("health_percent", 1.0 - (float(_health) / float(_max_health)))
		_res_mesh.mesh.surface_get_material(i).set_shader_parameter("res_percent", (1.0 - (float(_res_amount) / float(_res_max))) / 2.0)

# Getter for the resource type
func get_resource_type() -> Globals.RESOURCES:
	return _res_type

# Getter for the amount of a resource left
func get_resource_amount() -> int:
	return _res_amount

# Setter for the amount of resources
func set_resource_amount(new_amount: int) -> void:
	_res_amount = new_amount

# Called to deplete the resource and return how much was depleted
func deplete_resource(taken: int) -> int:

	# If there is not enough to be taken just give the rest
	if taken > _res_amount:
		self.destroy_self()
		return _res_amount
	else:
		_res_amount -= taken
		if _res_amount <= 0:
			self.destroy_self()
		return taken
