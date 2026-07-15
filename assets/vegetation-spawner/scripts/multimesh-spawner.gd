@tool
extends Node3D
class_name MultimeshSpawner3D


enum ChunkSize {
	Size_32 = 32,
	Size_64 = 64,
	Size_128 = 128,
	Size_256 = 256,
	Size_512 = 512,
	Size_1024 = 1024
}


@export_group("Geometry Settings")
@export var geometry_mesh : Mesh 

@export_range(0.0, 1.0) var minimum_slope : float = 0.5 

@export var minimum_height : float = 0.0 
@export var maximum_height : float = 100.0



#@export_range(0.0, 1.0) var geometry_dispersion : float = 0.5 
@export_range(0.0, 1.0) var geometry_density : float = 0.125 

@export var instance_offset : Vector3 = Vector3.ZERO

@export_range(0.0, 0.9) var mesh_scale_variation : float = 0.5
@export var mesh_scale_variation_splitted : bool = false

@export_group("Geometry Grouping")

@export_range(0.0, 20.0) var geometry_group_radius : float = 10.0
@export_range(1, 50) var geometry_group_size : int = 5
@export_range(0.0, 20) var geometry_group_minumum_distance : float = 2.0


@export_group("Terrain Settings")
@export var terrain : Node3D = null

@export var terrain_chunk_size : ChunkSize = ChunkSize.Size_64


@export_flags_3d_physics var collision_layers : int = 1

@export_group("Noise Settings")
@export var noise_seed : int = 0
@export var noise_scale : float = 0.5
@export var noise_offset : Vector2 = Vector2( 0.0, 0.0 )
#	Help for Island / Beaches / smooth mountain sides
@export var soft_exp : float = 1.0


@export_group("Visibility Range")
@export var visibility_range_apply : bool = false
# Set the MultiMeshInstance3D to appear 
# when the camera is further than <visibility_range_begin> units
# and disappear when further than <visibility_range_end> units.
@export var visibility_range_begin : float = 0.0
@export var visibility_range_end : float = 0.0
# Optionally, add margins for smoother transitions
@export var visibility_range_begin_margin : float = 0.0
@export var visibility_range_end_margin : float = 0.0
# Set the fade mode
@export var visibility_range_fade_mode : GeometryInstance3D.VisibilityRangeFadeMode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED



@export_group("Physics Settings")

@export var add_colliders : bool = true
@export var use_custom_colliders : bool = true
#@export var custom_collision_shape : Shape3D
@export var custom_collision_offset : Vector3
@export var custom_collision_size : Vector3 = Vector3(0.5, 2.0, 0.5)
@export var custom_collision_layer : int = 2


#	Actions
@export_category("Actions")

@export_tool_button("Update Geometry") var update_geometry_action = update_geometry_instances
@export_tool_button("Clear") var clear_action = clear_all_children



var lod_scale : float = 1.0

var rng

var terrain_aabb : AABB


func update_geometry_instances():
	
	clear_all_children()
	
	#	Get terrain dimension
	if !terrain	:
		print("Terrain not assigned")
		return
	
	rng = RandomNumberGenerator.new()
	rng.seed = noise_seed
	
	var mesh_instance: MeshInstance3D 
	for c in terrain.get_children(true):
		if c is MeshInstance3D:
			mesh_instance = c
			break

	var terrain_local_aabb : AABB = mesh_instance.get_mesh().get_aabb()
	print(terrain_local_aabb)
	terrain_aabb = terrain.global_transform * terrain_local_aabb
	#terrain_aabb = mesh_instance.global_transform * terrain_local_aabb
	print(terrain_aabb)
	
	#	Generate Transforms
	var geometry_transforms : Array[Transform3D] = generate_geometry_transforms(
		Vector2(terrain_aabb.position.x, terrain_aabb.position.z) , 
		Vector2(terrain_aabb.size.x, terrain_aabb.size.z) 
		)
	

	var chunk_size : Vector2 = Vector2(terrain_chunk_size, terrain_chunk_size)
	var chunk_start : Vector2
	
	var mesh_chunks : Vector2 = ceil(Vector2(terrain_aabb.size.x, terrain_aabb.size.z) / terrain_chunk_size)

	for z in range(mesh_chunks.y):
		for x in range(mesh_chunks.x):
			
			chunk_start = Vector2(terrain_aabb.position.x, terrain_aabb.position.z) + chunk_size * Vector2(x, z)
			
			var chunk_name = "Chunk-%02d-%02d" % [x, z]

			var filtered_transforms : Array[Transform3D] = filter_transforms(chunk_start, chunk_size, geometry_transforms)
			var multiMeshInstance3D : MultiMeshInstance3D = instanstiate_geometry(chunk_start, chunk_name, filtered_transforms)
			
			if add_colliders && multiMeshInstance3D:
				generate_colliders(multiMeshInstance3D, filtered_transforms)

	geometry_transforms.clear()
	
	
	
func clear_all_children():

	for child in get_children():
		remove_child(child)
	
		
func instanstiate_geometry(chunk_position : Vector2, chunk_name : String, geometry_transforms : Array[Transform3D]) -> MultiMeshInstance3D:
	
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

	if visibility_range_apply:
		# Set the MultiMeshInstance3D to appear 
		# when the camera is further than <visibility_range_begin> units
		# and disappear when further than <visibility_range_end> units.
		multiMeshInstance3D.visibility_range_begin = visibility_range_begin
		multiMeshInstance3D.visibility_range_end = visibility_range_end
		# Optionally, add margins for smoother transitions
		multiMeshInstance3D.visibility_range_begin_margin = visibility_range_begin_margin
		multiMeshInstance3D.visibility_range_end_margin = visibility_range_end_margin
		# Set the fade mode
		multiMeshInstance3D.visibility_range_fade_mode = visibility_range_fade_mode

		
	multiMeshInstance3D.transform.origin = Vector3(chunk_position.x, 0.0, chunk_position.y)

	return multiMeshInstance3D
	
	
func filter_transforms(chunk_start : Vector2, chunk_size : Vector2, transforms : Array[Transform3D] ) -> Array[Transform3D] :

	var filtered_transforms : Array[Transform3D] = []
	
	for t in transforms:
		
		if t.origin.x >= chunk_start.x and t.origin.z >= chunk_start.y and t.origin.x < chunk_start.x + chunk_size.x and t.origin.z < chunk_start.y + chunk_size.y :			
			#	Adjust the transforms to the chunk for
			#	LOD visibility configuration
			var local_t = t 
			local_t.origin -= Vector3(chunk_start.x, 0.0, chunk_start.y)
			filtered_transforms.append(local_t) 
			
	return filtered_transforms


func generate_colliders(multiMeshInstance3D : MultiMeshInstance3D, geometry_transforms : Array[Transform3D]):

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



func generate_geometry_transforms(chunk_start : Vector2, chunk_size : Vector2) -> Array[Transform3D] :
	
	var geometry_transforms : Array[Transform3D]  = []
	
	var geometry_groups_qty : int = int((chunk_size.x * chunk_size.y) / geometry_group_radius / geometry_group_radius * geometry_density)
	if geometry_groups_qty == 0:
		geometry_groups_qty = 1
	
	for i in geometry_groups_qty :

		var center_x: float = chunk_start.x + rng.randf() * chunk_size.x 
		var center_z: float = chunk_start.y + rng.randf() * chunk_size.y
					
		for g in geometry_group_size:
		
			var in_radius_position : Vector3 = Vector3(
				rng.randf_range(center_x - geometry_group_radius, center_x + geometry_group_radius), 
				0, 
				rng.randf_range(center_z - geometry_group_radius, center_z + geometry_group_radius)
			)
			
			if check_close_geometry(geometry_transforms, in_radius_position.x, in_radius_position.z, geometry_group_minumum_distance):
				continue
							
			var height = find_height_at(in_radius_position.x, in_radius_position.z)
			
			if height:
				
				# Set position for the instance
				var instance_origin = Vector3(in_radius_position.x, height, in_radius_position.z)
				instance_origin += instance_offset
				
				# Rotate the mesh
				var instance_basis = Basis()
				instance_basis = instance_basis.rotated(Vector3.UP, 2.0 * PI * rng.randf() )
				var instance_transform : Transform3D = Transform3D(instance_basis, instance_origin)

				# Scale the mesh
				var scale_factor = rng.randf_range(1.0 - mesh_scale_variation, 1.0 + mesh_scale_variation)
				var scale_factor_2 = rng.randf_range(1.0 - mesh_scale_variation, 1.0 + mesh_scale_variation)
				#	If not enabled use the same scale for height (y) and width (x and z)
				if !mesh_scale_variation_splitted:
					scale_factor_2 = scale_factor

				var instance_scale = Vector3(scale_factor, scale_factor_2, scale_factor)
				instance_transform = instance_transform.scaled_local(instance_scale) 
				
				geometry_transforms.append(instance_transform)

	return geometry_transforms
	

#func find_height_at(x:float, z:float):
	#
	##RayCast3D
	#var origin = Vector3(x, 1000, z)
	#var target = origin  + Vector3(0, -1100, 0)
	#
	#var space_state = get_world_3d().direct_space_state
	#
	#var query = PhysicsRayQueryParameters3D.create(origin, target, collision_layers)
	#var result = space_state.intersect_ray(query)
#
	#if result:
		#if (result["normal"].y < minimum_slope):
			#return null
		#else:
			#
			#var position_y : float = result["position"].y
#
			#if position_y >= minimum_height and position_y <= maximum_height:
				#return position_y
			#else:
				#return null
	#else:
		#return null
	


		
			
func check_close_geometry(geometry_transforms : Array[Transform3D], x : float, z : float, distance : float) -> bool:
	
	var pos_origin : Vector2 = Vector2( x, z )
	var distance_sgr : float = distance * distance
	for t in geometry_transforms:
		var test_distance_sqr : float = pos_origin.distance_squared_to(Vector2(t.origin.x, t.origin.z)) 
		if test_distance_sqr <= distance_sgr:
			return true
			
	return false	


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
	
