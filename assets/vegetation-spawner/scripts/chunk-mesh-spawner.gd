@tool
extends Node3D

class_name ChunkMeshSpawner3D


enum MeshChunkSize {
	MCS_64 = 64,
	MCS_128 = 128,
	MCS_256 = 256,
	MCS_512 = 512,
	MCS_1024 = 1024,
	MCS_2048 = 2048,
}


@export_group("Geometry Settings")
@export var geometry_scenes : Array[PackedScene] = []

@export_range(0.0, 1.0) var minimum_slope : float = 0.5 

@export var minimum_height : float = 0.0 
@export var maximum_height : float = 100.0

@export_range(0.0, 1.0) var geometry_density : float = 0.5 

@export_range(0.0, 0.9) var mesh_scale_variation : float = 0.5

@export var instance_offset : Vector3 = Vector3.ZERO

@export_group("Geometry Grouping")

@export_range(0.0, 20.0) var geometry_group_radius : float = 10.0
@export_range(1, 50) var geometry_group_size : int = 5
@export_range(0.0, 20) var geometry_group_minumum_distance : float = 2.0


@export_group("Terrain Settings")

@export var terrain : Node3D = null

var terrain_aabb : AABB

@export var mesh_chunk_size : MeshChunkSize = MeshChunkSize.MCS_64
#@export_range(1, 128) var mesh_chunks : int = 1

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


#	Keep random generation for the run
var rng : RandomNumberGenerator




func update_geometry_instances():
	
	#print_debug("update_geometry_instances")
	
	clear_all_children()
	
	rng = RandomNumberGenerator.new()
	rng.seed = noise_seed

	if !terrain	:
		print("Terrain not assigned")
		return
		
	var mesh_instance: MeshInstance3D 
	for c in terrain.get_children(true):
		if c is MeshInstance3D:
			mesh_instance = c
			break
		
	var terrain_local_aabb : AABB = mesh_instance.get_mesh().get_aabb()
	terrain_aabb = terrain.global_transform * terrain_local_aabb
	#print(terrain_aabb)
	#print(terrain_aabb.size)
	
	
	#	Generate Transforms
	var geometry_transforms : Array[Transform3D] = generate_geometry_transforms(
		Vector2(terrain_aabb.position.x, terrain_aabb.position.z) , 
		Vector2(terrain_aabb.size.x, terrain_aabb.size.z) 
		)
	#print("Generated : " + str(geometry_transforms.size()))

	#	Validate terrain size and region size values
#	var chunk_size = Vector2(mesh_chunk_size, mesh_chunk_size)
	var chunks : Vector2i = Vector2(terrain_aabb.size.x, terrain_aabb.size.z) / mesh_chunk_size
	#print(chunks)
	#var chunk_size : Vector2 = Vector2(terrain_aabb.size.x, terrain_aabb.size.z) / mesh_chunks
	var chunk_size : Vector2 = Vector2(terrain_aabb.size.x / chunks.x, terrain_aabb.size.z / chunks.y) 
	#print(chunk_size)
	var chunk_start : Vector2


	for z in range(chunks.y):
		for x in range(chunks.x):
			
			chunk_start = Vector2( terrain_aabb.position.x, terrain_aabb.position.z) + chunk_size * Vector2(x, z)
			
			var chunk_name = "Chunk-%02d-%02d" % [x, z]
			#print(chunk_name)
			#print(chunk_start)
			#print(chunk_start + chunk_size)

			var filtered_transforms : Array[Transform3D] = filter_transforms(chunk_start, chunk_size, geometry_transforms)
			#print("Filtered : " + str(filtered_transforms.size()))
#			var geometry_transforms : Array[Transform3D] = generate_geometry_transforms(chunk_start, chunk_size)
#			print("Generated : " + str(geometry_transforms.size()))
			#var multiMeshInstance3D : MultiMeshInstance3D = instanstiate_geometry(chunk_name, geometry_transforms)
			instanstiate_geometry(chunk_name, filtered_transforms)
			
#			geometry_transforms.clear()
	
	geometry_transforms.clear()
	


func filter_transforms(chunk_start : Vector2, chunk_size : Vector2, transforms : Array[Transform3D] ) -> Array[Transform3D] :

	var filtered_transforms : Array[Transform3D] = []
	
	for t in transforms:
		
		if t.origin.x >= chunk_start.x and t.origin.z >= chunk_start.y and t.origin.x < chunk_start.x + chunk_size.x and t.origin.z < chunk_start.y + chunk_size.y :			
			filtered_transforms.append(t) 
			
	return filtered_transforms


	
func clear_all_children():
	for child in get_children():
		#print_debug(child.name)
		remove_child(child)
	

#	Instantiage geometries stored in scenes on the actual scene
#	based on the previously calculated transforms
func instanstiate_geometry(chunk_name : String, geometry_transforms : Array[Transform3D]) -> Node3D:

	var geometry_parent_node : Node3D = Node3D.new()
	
	add_child(geometry_parent_node)
	geometry_parent_node.owner = owner
	geometry_parent_node.name = chunk_name

	for t in geometry_transforms:
		
		var scene_idx : int = rng.randi_range(0, geometry_scenes.size() - 1)
		var instance = geometry_scenes[scene_idx].instantiate()
		instance.transform= t
		geometry_parent_node.add_child(instance)
		instance.owner = geometry_parent_node.owner
		
		var uuid : String = generate_uuid()
		instance.name = instance.name + "-" + uuid
		
		
	return geometry_parent_node
		


func generate_uuid() -> String:
	
	var time_ms = Time.get_unix_time_from_system() * 1000
	var random_part = rng.randi()
	return str(time_ms) + "-" + str(random_part)



func generate_geometry_transforms(chunk_start : Vector2, chunk_size : Vector2) -> Array[Transform3D] :
	
	var geometry_transforms : Array[Transform3D]  = []
	
	var geometry_groups_qty : int = (chunk_size.x * chunk_size.y) / geometry_group_radius / geometry_group_radius * geometry_density
	#print("Groupds : " + str(geometry_groups_qty))
	
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

				var instance_scale = Vector3(scale_factor, scale_factor, scale_factor)
				instance_transform = instance_transform.scaled_local(instance_scale) 
				
				geometry_transforms.append(instance_transform)

	return geometry_transforms
	

func find_height_at(x:float, z:float):
	
	#RayCast3D
	var origin = Vector3(x, 1000, z)
	var target = origin  + Vector3(0, -1100, 0)
	
	var space_state = get_world_3d().direct_space_state
	
	var query = PhysicsRayQueryParameters3D.create(origin, target, collision_layers)
	var result = space_state.intersect_ray(query)

	if result:
		if (result["normal"].y < minimum_slope):
			return null
		else:
			
			var position_y : float = result["position"].y

			if position_y >= minimum_height and position_y <= maximum_height:
				return position_y
			else:
				return null
	else:
		return null
	


		
			
func check_close_geometry(geometry_transforms : Array[Transform3D], x : float, z : float, distance : float) -> bool:
	
	for t in geometry_transforms:
		var pos_origin : Vector2 = Vector2(t.origin.x , t.origin.z)
		var test_distance : float = pos_origin.distance_to(Vector2(x,z)) 
		if test_distance <= distance:
			return true
			
	return false	
