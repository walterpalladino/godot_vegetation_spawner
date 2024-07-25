extends Node

class_name GeometrySpawnUtils

#static func generate_geometry(geometry_mesh:Mesh, terrain_size:int, geometry_density:float, rng:RandomNumberGenerator):
#
	#var mesh_size : Vector3 = geometry_mesh.get_aabb().size
	#var mesh_size_factor = mesh_size.x
	#if mesh_size.z > mesh_size_factor:
		#mesh_size_factor = mesh_size.z
		#
	#for i in terrain_size * terrain_size * geometry_density / mesh_size_factor:
#
		#var x: float = rng.randf() * terrain_size;
		#var y: float = 0.0;
		#var z: float = rng.randf() * terrain_size;
		#
		#var noise = NoiseUtils.generate_noise_at(x,z,noise_seed, noise_scale, terrain_size, noise_offset, soft_exp, lod_scale) 
		##print_debug(noise)
#
		#if (noise < geometry_dispersion):
			#var height = find_height_at(x,z)
			#if height:
				#
				#var instance_position = Vector3(x, height, z)
				#var instance_transform : Transform3D = Transform3D()
				#
				#geometry_transforms.append(instance_position)
