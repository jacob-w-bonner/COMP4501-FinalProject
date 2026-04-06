@tool
extends EditorScript

# The paths for the original file and save destination
@export var original_path:	String	= "res://Assets/Lamp/lantern.glb"
@export var save_path:		String	= "res://Assets/Lamp/"
@export var save_name:		String	= "Lantern"

func _run():

	# If the file path does not exist don't do anything
	if !FileAccess.file_exists(original_path):
		print("File with path '%s' does not exist" % original_path)
		return

	# If the directory save path does not exist don't do anything
	var save_dir = DirAccess.open(save_path)
	if !save_dir:
		print("Save location with path '%s' does not exist" % save_path)
		return

	# Loading the glb file
	var glb 		= load(original_path)
	var glb_scene 	= glb.instantiate()

	# Temporary node to mimic scene hierarchy
	var temp_root 	= Node3D.new()
	var editor_root = get_editor_interface().get_edited_scene_root()
	editor_root.add_child(temp_root)
	temp_root.add_child(glb_scene)

	# New array mesh that will contain the output
	var arr_mesh 	= ArrayMesh.new()

	# Processing each mesh that is apart of the scene
	process_meshes(glb_scene, arr_mesh)

	# Getting rid of the temporary scene tree
	temp_root.queue_free()

	# Saving the processed array mesh as a tres file
	ResourceSaver.save(arr_mesh, "%s%s.tres" % [save_path, save_name])
	print("New mesh successfully processed!")


# Called to process the meshes in a scene
func process_meshes(curr_node: Node, arr_mesh: ArrayMesh) -> void:

	# Checking each child of the current node to see if there are any submeshes
	for child in curr_node.get_children():

		# If there is a submesh then process it
		if child is MeshInstance3D:

			# Getting the mesh and its transform
			var new_mesh 		= child.mesh
			var mesh_transform	= child.global_transform

			# Normal matrix
			var norm_mat		= mesh_transform.basis.inverse().transposed()

			# Redrawing mesh accounting for any transformations
			for surface in new_mesh.get_surface_count():

				# Getting the arrays for surface properties
				var properties = new_mesh.surface_get_arrays(surface)

				# Applying transformations to the vertices
				var vertices   = properties[Mesh.ARRAY_VERTEX]
				if vertices:
					for i in range(vertices.size()):
						vertices[i] = mesh_transform * vertices[i]
					properties[Mesh.ARRAY_VERTEX] = vertices

				# Applying transformations to the normals
				var normals	   = properties[Mesh.ARRAY_NORMAL]
				if normals:
					for i in range(normals.size()):
						normals[i] = norm_mat * normals[i]
						normals[i] = normals[i].normalized()
					properties[Mesh.ARRAY_NORMAL] = normals

				# Applying transformations to the tangents
				var tangents   = properties[Mesh.ARRAY_TANGENT]
				if tangents:
					for i in range(0, tangents.size(), 4):
						var tangent 	= Vector3(tangents[i], tangents[i + 1], tangents[i + 2])
						tangent			= norm_mat * tangent
						tangent			= tangent.normalized()
						tangents[i] 	= tangent.x
						tangents[i + 1] = tangent.y
						tangents[i + 2] = tangent.z
					properties[Mesh.ARRAY_TANGENT] = tangents

				# Adding the surface to the array mesh
				var primitive = new_mesh.surface_get_primitive_type(surface)
				var format    = new_mesh.surface_get_format(surface)
				arr_mesh.add_surface_from_arrays(primitive, properties, [], {}, format)

				# Adding the surface material to the array mesh
				var material  = new_mesh.surface_get_material(surface)
				if material:
					arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1,material)

		# If the current node has children they will also need to be processed
		process_meshes(child, arr_mesh)
