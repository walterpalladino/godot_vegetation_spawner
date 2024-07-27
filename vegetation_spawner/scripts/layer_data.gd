extends Resource

class_name LayerData

@export var mesh : Mesh
@export var materials : Array[Material] = [] 

@export_range(0.0, 1.0) var minimum_slope : float = 0.5 
@export_range(0.0, 1.0) var geometry_dispersion : float = 0.5 
@export_range(0.0, 1.0) var geometry_density : float = 0.125 

@export var add_colliders : bool = true
@export var custom_collision_shape : Shape3D
@export var custom_collision_offset : Vector3
