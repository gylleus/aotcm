extends KinematicBody

const JUMP_VELOCITY = 20
const GRAVITY = -40
const MOUSE_SENSITIVITY = 0.05
const WEIGHT = 1.0

var accel = 8
var deaccel = 11
var max_speed = 14
var velocity = Vector3()

const MAX_SLOPE_ANGLE = 90

var camera
var rotation_helper

# Called when the node enters the scene tree for the first time.
func _ready():
	camera = $RotationHelper/Camera
	rotation_helper = $RotationHelper
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")

func _physics_process(delta):
	move(delta)
	# Capturing/Freeing the cursor
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func move(delta):
	var dir = Vector3()
	var cam_xform = camera.get_global_transform()
	var input_movement_vector = Vector2()

	if Input.is_action_pressed("move_forward"):
		input_movement_vector.y += 1
	if Input.is_action_pressed("move_backward"):
		input_movement_vector.y -= 1
	if Input.is_action_pressed("strafe_left"):
		input_movement_vector.x -= 1
	if Input.is_action_pressed("strafe_right"):
		input_movement_vector.x += 1
	input_movement_vector = input_movement_vector.normalized()
	
	dir -= input_movement_vector.y * cam_xform.basis.z
	dir += input_movement_vector.x * cam_xform.basis.x
	dir.y = 0
	dir = dir.normalized()
	
	var hvel = velocity
	hvel.y = 0

	var a = accel if dir.dot(hvel) > 0 else deaccel
	hvel = hvel.linear_interpolate(dir * max_speed, accel * delta)
	velocity.x = hvel.x
	velocity.z = hvel.z
	velocity = move_and_slide(velocity, Vector3(0, 1, 0), 0.05, 4, deg2rad(MAX_SLOPE_ANGLE))

	if Input.is_action_just_pressed("player_jump") && is_on_floor():
		velocity.y = JUMP_VELOCITY
	# Apply gravity
	if !is_on_floor():
		velocity.y += delta * GRAVITY

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation_helper.rotate_x(deg2rad(event.relative.y * MOUSE_SENSITIVITY))
		self.rotate_y(deg2rad(event.relative.x * MOUSE_SENSITIVITY * -1))

		var camera_rot = rotation_helper.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -70, 70)
		rotation_helper.rotation_degrees = camera_rot

func take_damage(amount):
	print("Took " + str(amount) + "damage")

func add_flying_force(force):
	velocity += force/WEIGHT
