@tool
extends MultiMeshInstance3D

@export_group("Geometry Settings")
@export var geometry_mesh : Mesh 
@export var geometry_materials : Array[Material] = [] 

@export_range(0.0, 1.0) var minimum_slope : float = 0.5 
@export_range(0.0, 1.0) var geometry_dispersion : float = 0.5 
@export_range(0.0, 1.0) var geometry_density : float = 0.125 

@export var add_colliders : bool = true
@export var custom_collision_shape : Shape3D
@export var custom_collision_offset : Vector3

@export_group("Terrain Settings")
@export var terrain_size = 20

@export_group("Noise Settings")
@export var noise_seed : int = 0
@export var noise_scale : float = 0.5
@export var noise_offset : Vector2 = Vector2( 0.0, 0.0 )
#	Help for Island / Beaches / smooth mountain sides
@export var soft_exp : float = 1.0

#	Actions
@export_category("Actions")

@export var update_geometry : bool :
	set(value):
		update_geometry_instances()
#var update_instances = false

@export var clear_geometry : bool :
	set(value):
		clear_geometry_instances()


var lod_scale : float = 1.0

var geometry_transforms : Array[Transform3D] = [] 
var rng
#var noise_map : PackedFloat32Array = PackedFloat32Array()



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func update_mesh():
	pass


func update_material():
	pass

func update_geometry_instances():
	
	print_debug("update_geometry_instances")
	
	clear_geometry_instances()
	
	rng = RandomNumberGenerator.new()
	rng.seed = noise_seed

#	noise_map = NoiseUtils.generate_noise_map(noise_seed,noise_scale,terrain_size,noise_offset,soft_exp,lod_scale)

	generate_geometry()
	instanstiate_geometry()
	
	if add_colliders:
		generate_colliders()


func clear_geometry_instances():
	
	print_debug("clear_geometry_instances")
	
#	noise_map.clear()
	multimesh = null
	geometry_transforms.clear()
	#	Clear colliders
	clear_colliders()

	
func clear_colliders():
	for child in get_children():
		#print_debug(child.name)
		remove_child(child)
	
		
func instanstiate_geometry():
	
	print_debug("instanstiate_geometry")
	
	if geometry_transforms.size() <= 0:
		return
	
	# Create the multimesh.
	multimesh = MultiMesh.new()
	# Set the format first.
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	# Then resize (otherwise, changing the format is not allowed).
	multimesh.instance_count = geometry_transforms.size()
	# Maybe not all of them should be visible at first?
	multimesh.visible_instance_count = geometry_transforms.size()
	

	# Set geometry
	multimesh.mesh = geometry_mesh
	for i in geometry_materials.size():
		multimesh.mesh.surface_set_material(i, geometry_materials[i])
		#material_override =geometry_materials[i]

	
	# Set the transform of the instances.
	for i in multimesh.visible_instance_count:

		# Add the new mesh instance				
		multimesh.set_instance_transform(i, geometry_transforms[i])
		#multimesh.set_instance_transform(i, Transform3D(Basis(), geometry_transforms[i]))
					


func generate_colliders():

	print_debug("generate_colliders")
	
	#var new_node = Node3D.new()
	#add_child(new_node)
	#new_node.owner = owner
	
	#var new_node = Node3D.new()
	#$"../StaticBody3D".add_child(new_node)
	#new_node.owner = $"../StaticBody3D".owner
	#
	#var static_body = StaticBody3D.new()
	#new_node.add_child(static_body)
	#static_body.owner = new_node.owner
	 #
	#var collision_shape = CollisionShape3D.new()
#
	#var box : BoxShape3D = BoxShape3D.new()
	#box.size = Vector3(4.0,4.0,4.0)
	#collision_shape.shape = box
	#collision_shape.global_transform = Transform3D(Basis(), Vector3(0.0, 0.0, 0.0))
#
	#static_body.add_child(collision_shape)
	#collision_shape.owner = static_body.owner
	
	#var static_body = StaticBody3D.new()
	#add_child(static_body)
	#static_body.owner = owner

	#var collision_shape = CollisionShape3D.new()
	#var box : BoxShape3D = BoxShape3D.new()
	#box.size = Vector3(4.0,4.0,4.0)
	#collision_shape.shape = box
	#collision_shape.global_transform = Transform3D(Basis(), Vector3(0.0, 0.0, 0.0))

	#static_body.add_child(collision_shape)
	
	# Re-use the same shape
	var shape = multimesh.mesh.create_trimesh_shape()
	
	var box_shape : BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(0.5,1.4,0.5)
	

	# Create one static body
	var collision_parent = StaticBody3D.new()
	add_child(collision_parent)
	collision_parent.owner = owner
	collision_parent.set_as_top_level(true)

	for i in multimesh.visible_instance_count:

		# Create many collision shapes
		var collider = CollisionShape3D.new()
		#collider.shape = box_shape
		#collider.global_transform = Transform3D(Basis(), geometry_transforms[i].origin + Vector3(0.0, 0.7, 0.0))
		collider.shape = shape
		collider.global_transform = geometry_transforms[i]

		collision_parent.add_child(collider)
		collider.owner = collision_parent.owner


func generate_geometry():
	
	var mesh_size : Vector3 = geometry_mesh.get_aabb().size
	var mesh_size_factor = mesh_size.x
	if mesh_size.z > mesh_size_factor:
		mesh_size_factor = mesh_size.z
		
	for i in terrain_size * terrain_size * geometry_density / mesh_size_factor:

		var x: float = rng.randf() * terrain_size;
		var y: float = 0.0;
		var z: float = rng.randf() * terrain_size;
		
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
				var scale_factor = (rng.randf() - 0.5) * 0.5 + 1.5
				var instance_scale = Vector3(scale_factor, scale_factor, scale_factor)
				instance_transform = instance_transform.scaled_local(instance_scale) 
				
				geometry_transforms.append(instance_transform)


func find_height_at(x:float, z:float):
	
	#RayCast3D
	var origin = Vector3(x, 1000, z)
	var target = origin  + Vector3(0, -1000, 0)
	
	var space_state = get_world_3d().direct_space_state
	
	var query = PhysicsRayQueryParameters3D.create(origin, target)
	var result = space_state.intersect_ray(query)

	#print_debug(result["normal"].y)
	
	if result:
		if (result["normal"].y < minimum_slope):
			return null
		else:
			#print_debug(result["position"])
			return result["position"].y
	else:
		return null
	
