@tool
extends Node3D
class_name MultimeshSpawner3D

@export_group("Geometry Settings")
@export var geometry_mesh : Mesh 
@export var geometry_materials : Array[Material] = [] 

@export_range(0.0, 1.0) var minimum_slope : float = 0.5 

@export var minimum_height : float = 0.0 
@export var maximum_height : float = 100.0



@export_range(0.0, 1.0) var geometry_dispersion : float = 0.5 
@export_range(0.0, 1.0) var geometry_density : float = 0.125 

@export var add_colliders : bool = true
@export var use_custom_colliders : bool = true
#@export var custom_collision_shape : Shape3D
@export var custom_collision_offset : Vector3
@export var custom_collision_size : Vector3 = Vector3(0.5, 2.0, 0.5)
@export var custom_collision_layer : int = 2

@export_range(0.0, 0.9) var mesh_scale_variation : float = 0.5


@export_group("Terrain Settings")
@export var terrain_size = 20
@export var terrain_start_position : Vector2 = Vector2(0,0)
@export var terrain_end_position : Vector2 = Vector2(20,20)
@export_range(1, 64) var mesh_chunks : int = 1

@export_flags_3d_physics var collision_layers : int = 1

@export_group("Noise Settings")
@export var noise_seed : int = 0
@export var noise_scale : float = 0.5
@export var noise_offset : Vector2 = Vector2( 0.0, 0.0 )
#	Help for Island / Beaches / smooth mountain sides
@export var soft_exp : float = 1.0

#	Actions
@export_category("Actions")

@export_tool_button("Update Geometry") var update_geometry_action = update_geometry_instances
@export_tool_button("Clear") var clear_action = clear_all_children



var lod_scale : float = 1.0

var rng

#var multiMeshInstance3D : MultiMeshInstance3D = null



func update_geometry_instances():
	
	#print_debug("update_geometry_instances")
	
	clear_all_children()
	
	rng = RandomNumberGenerator.new()
	rng.seed = noise_seed

	var chunk_size : Vector2 = (terrain_end_position - terrain_start_position) / mesh_chunks
	var chunk_start : Vector2

	for z in range(mesh_chunks):
		for x in range(mesh_chunks):
			
			chunk_start = terrain_start_position + chunk_size * Vector2(x, z)
			
			var chunk_name = "Chunk-%02d-%02d" % [x, z]
			#print(chunk_name)
			#print(chunk_start)
			#print(chunk_start + chunk_size)

			var geometry_transforms : Array[Transform3D] = generate_geometry(chunk_start, chunk_size)
			
			var multiMeshInstance3D : MultiMeshInstance3D = instanstiate_geometry(chunk_name, geometry_transforms)
			
			if add_colliders:
				generate_colliders(multiMeshInstance3D, geometry_transforms)

			geometry_transforms.clear()
	
	
	
func clear_all_children():
	for child in get_children():
		#print_debug(child.name)
		remove_child(child)
	
		
func instanstiate_geometry(chunk_name : String, geometry_transforms : Array[Transform3D]) -> MultiMeshInstance3D:
	
	#print_debug("instanstiate_geometry")
	
	var multiMeshInstance3D : MultiMeshInstance3D = MultiMeshInstance3D.new()
	
	if geometry_transforms.size() <= 0:
		return
	
	# Create the multimesh.
	var new_multimesh = MultiMesh.new()

	# Set geometry
	new_multimesh.mesh = geometry_mesh

	# Set the format first.
	new_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	# Then resize (otherwise, changing the format is not allowed).
	new_multimesh.instance_count = geometry_transforms.size()
	# Maybe not all of them should be visible at first?
	new_multimesh.visible_instance_count = geometry_transforms.size()
	
	# Set the transform of the instances.
	for i in new_multimesh.visible_instance_count:
		# Add the new mesh instance				
		new_multimesh.set_instance_transform(i, geometry_transforms[i])
		
	multiMeshInstance3D.multimesh = new_multimesh
	add_child(multiMeshInstance3D)
	multiMeshInstance3D.owner = owner
	multiMeshInstance3D.name = chunk_name

	return multiMeshInstance3D
	
	

func generate_colliders(multiMeshInstance3D : MultiMeshInstance3D, geometry_transforms : Array[Transform3D]):

	#print_debug("generate_colliders")
		
	# Re-use the same shape
	var shape = multiMeshInstance3D.multimesh.mesh.create_trimesh_shape()
	
	var box_shape : BoxShape3D = BoxShape3D.new()
	box_shape.size = custom_collision_size
	

	# Create one static body
	var collision_parent = StaticBody3D.new()
	multiMeshInstance3D.add_child(collision_parent)
	collision_parent.owner = multiMeshInstance3D.owner
	collision_parent.set_as_top_level(true)
	
	collision_parent.collision_layer = custom_collision_layer

	for i in geometry_transforms.size():

		# Create many collision shapes
		var collider = CollisionShape3D.new()
		
		if use_custom_colliders:
			collider.shape = box_shape
			collider.global_transform = Transform3D(Basis(), geometry_transforms[i].origin + Vector3(0.0, box_shape.size.y / 2.0, 0.0) + custom_collision_offset)
		else:
			collider.shape = shape
			collider.global_transform = geometry_transforms[i]

		collision_parent.add_child(collider)
		collider.owner = collision_parent.owner


func generate_geometry(chunk_start : Vector2, chunk_size : Vector2) -> Array[Transform3D] :
	
	var geometry_transforms : Array[Transform3D]  = []
	
	var mesh_size : Vector3 = geometry_mesh.get_aabb().size
	var mesh_size_factor = mesh_size.x
	if mesh_size.z > mesh_size_factor:
		mesh_size_factor = mesh_size.z
			
	for i in terrain_size * terrain_size * geometry_density / mesh_size_factor / mesh_chunks / mesh_chunks:

		var x: float = chunk_start.x + rng.randf() * chunk_size.x ;
		var y: float = 0.0;
		var z: float = chunk_start.y + rng.randf() * chunk_size.y;
		
		var noise = NoiseUtils.generate_noise_at(x,z,noise_seed, noise_scale, terrain_size, noise_offset, soft_exp, lod_scale) 
		#var noise = noise_map[int(x) + int(z) * terrain_size]
		#print_debug(noise)

		if (noise < geometry_dispersion):
			var height = find_height_at(x,z)
			if height:

				# Set position for the instance
				var instance_origin = Vector3(x, height, z)
				
				# Rotate the mesh
				var instance_basis = Basis()
				instance_basis = instance_basis.rotated(Vector3.UP, 2.0 * PI * rng.randf() )
				var instance_transform : Transform3D = Transform3D(instance_basis, instance_origin)

				# Scale the mesh
				#var scale_factor = (rng.randf() - 0.5) * 0.5 + 1.5
				var scale_factor = rng.randf_range(1.0 - mesh_scale_variation, 1.0 + mesh_scale_variation)
				var instance_scale = Vector3(scale_factor, scale_factor, scale_factor)
				instance_transform = instance_transform.scaled_local(instance_scale) 
				
				geometry_transforms.append(instance_transform)

	return geometry_transforms
	

func find_height_at(x:float, z:float):
	
	#RayCast3D
	var origin = Vector3(x, 1000, z)
	var target = origin  + Vector3(0, -1000, 0)
	
	var space_state = get_world_3d().direct_space_state
	
	var query = PhysicsRayQueryParameters3D.create(origin, target, collision_layers)
	var result = space_state.intersect_ray(query)

	#print_debug(result["normal"].y)
	
	if result:
		if (result["normal"].y < minimum_slope):
			return null
		else:
			
			#print_debug(result["position"])
			var position_y : float = result["position"].y
			#print(position_y)
			if position_y >= minimum_height and position_y <= maximum_height:
				return position_y
			else:
				return null
	else:
		return null
	
