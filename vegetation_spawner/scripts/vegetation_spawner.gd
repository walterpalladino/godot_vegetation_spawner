extends Node3D


@export var mesh: Mesh:
	get:
		return mesh
	set(value):
		set_mesh(value)



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func set_mesh(new_mesh):
	mesh = new_mesh
	update()

func update():
	print_debug("update called")
	pass
