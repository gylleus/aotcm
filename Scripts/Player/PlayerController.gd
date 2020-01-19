extends KinematicBody

export var JUMP_VELOCITY = 20
export var GRAVITY = -40
export var MOUSE_SENSITIVITY = 0.05
export var WEIGHT = 1.0
export var MAX_HEALTH = 100

export var accel = 8
export var deaccel = 11
export var max_speed = 14

const MAX_SLOPE_ANGLE = 60

var velocity = Vector3()
onready var current_health = MAX_HEALTH

var camera
var rotation_helper
var is_alive = true

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
    if Input.is_action_just_pressed("kubelet_clear"):
        for k in get_tree().get_nodes_in_group("kubelet"):
            k.trigger_emergency_clear()

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

    if Input.is_action_pressed("player_jump") && is_on_floor():
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

func die():
    $RespawnTimer.start()
    Globals.kill_player()
    is_alive = false

func take_damage(amount):
    current_health -= amount
    if current_health <= 0:
        die()

func add_flying_force(force, damage=0):
    velocity += force/WEIGHT
    take_damage(damage)

func revive():
    current_health = MAX_HEALTH
    is_alive = true