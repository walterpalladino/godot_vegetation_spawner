extends Node

class_name NoiseUtils

static func generate_noise_map(noise_seed:int, noise_scale:float, size:int, noise_offset:Vector2, soft_exp:float, lod_scale:float):
	
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = noise_seed

	#noise.octaves = 4
	#noise.period = 20.0
	#noise.persistence = 0.4
	
	#noise.frequency = 0.01
	
	noise.fractal_octaves = 8
	noise.fractal_lacunarity = 2.75
	#noise.fractal_gain = 0.50
	noise.fractal_gain = 0.4

	var heights = PackedFloat32Array()
	var min = 2.0
	var max = -2.0
	for z in range(size + 1):
		for x in range(size + 1):

			var noise_position = Vector2(x * noise_scale, z * noise_scale)
			noise_position += noise_offset
			noise_position *= lod_scale

			var noise_value = noise.get_noise_2d(noise_position.x, noise_position.y)

			noise_value = noise_value + 0.5
			noise_value = clamp( noise_value, 0.0, 1.0 )
			
			#  Help for Island / Beaches / smooth mountain sides
			noise_value = pow(noise_value, soft_exp);
			
			if noise_value > max:
				max = noise_value
			if noise_value < min:
				min = noise_value
			
			heights.append(noise_value)

	#print(min)
	#print(max)
	
	return heights


static func generate_noise_at(x:int, z:int, noise_seed:int, noise_scale:float, size:int, noise_offset:Vector2, soft_exp:float, lod_scale:float):
	
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = noise_seed

	noise.fractal_octaves = 8
	noise.fractal_lacunarity = 2.75
	noise.fractal_gain = 0.4

	var noise_position = Vector2(x * noise_scale, z * noise_scale)
	noise_position += noise_offset
	noise_position *= lod_scale

	var noise_value = noise.get_noise_2d(noise_position.x, noise_position.y)

	noise_value = noise_value + 0.5
	noise_value = clamp( noise_value, 0.0, 1.0 )
	
	#  Help for Island / Beaches / smooth mountain sides
	noise_value = pow(noise_value, soft_exp);
	
	return noise_value
