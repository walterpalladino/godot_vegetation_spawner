extends CharacterBody3D


@export var speed = 5.0
@export var jump_velocity = 4.5
@export var mouse_sensitivity = 0.002


@onready var camera = $Camera3D


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	
	if event is InputEventMouseMotion:
		# Rotate the Head (Y-axis)
		rotate_y(-event.relative.x * mouse_sensitivity)
		# Rotate the Camera (X-axis)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		# Clamp camera rotation to prevent flipping
		var camera_rot = camera.rotation
		camera_rot.x = clamp(camera_rot.x, deg_to_rad(-90), deg_to_rad(90))
		camera.rotation = camera_rot

	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)



func _physics_process(delta: float) -> void:
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
