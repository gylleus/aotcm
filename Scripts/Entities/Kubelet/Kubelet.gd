extends Spatial

export var MAX_LAUNCH_RANGE = 10.0
export var MIN_LAUNCH_RANGE = 1.0
# Controls how many points are created when interpolating launch angle vector
export var LAUNCH_GRANULARITY = 0.5
var POD_GRAVITY_FACTOR = 1

export var MIN_SPIN_ANGLE = 60
#export var MIN_POD_DISTANCE= 2.0
export var MAX_SPIN_ANGLE = 90
export var POD_AIR_TIME = 2.0
export var SPIN_TIME = 1.0

var pod_queue = []
var next_pod = null

var pod_launch_vector : Vector3

var last_launch_angle : int
var spin_start : Transform
var spin_lerp_value : float = 0
var resting_look_direction : Vector3
# Random number generator
var rng = RandomNumberGenerator.new()

const PodTemplate = preload("res://Scripts/Entities/PodTemplate.gd")
onready var playback = get_node("KubeletModel/KubeletArmature/AnimationTree").get("parameters/playback")
var explosion_scene = preload("res://Models/Entities/Kubelet/Explosion.tscn")

signal spit_pod

func _ready():
    rng.randomize()
    add_to_group("kubelet")
    resting_look_direction = global_transform.basis.z
    # Set a random "previous" launch angle 
    last_launch_angle = rng.randf_range(0.0, 360.0)
    queue_pod(PodTemplate.new(50,"test"))
    queue_pod(PodTemplate.new(50,"test"))
    # queue_pod(PodTemplate.new(50,"test"))
    # queue_pod(PodTemplate.new(50,"test"))
    # queue_pod(PodTemplate.new(50,"test"))
    # queue_pod(PodTemplate.new(50,"test"))
    # queue_pod(PodTemplate.new(50,"test"))
    # queue_pod(PodTemplate.new(50,"test"))
    # queue_pod(PodTemplate.new(50,"test"))
    # queue_pod(PodTemplate.new(50,"test"))
    # queue_pod(PodTemplate.new(50,"test"))
    # queue_pod(PodTemplate.new(50,"test"))
    # queue_pod(PodTemplate.new(50,"test"))
    # queue_pod(PodTemplate.new(50,"test"))
    # queue_pod(PodTemplate.new(50,"test"))
    # queue_pod(PodTemplate.new(50,"test"))
    initiate_next_pod()
    

func _physics_process(delta):
    if next_pod != null:
        spin_lerp_value += delta / SPIN_TIME
        rotate_towards_direction(pod_launch_vector, spin_lerp_value, spin_start)
        if spin_lerp_value >= 1:
            emit_signal("spit_pod", pod_launch_vector)
    elif len(pod_queue) == 0:
        spin_lerp_value += delta / SPIN_TIME
        rotate_towards_direction(resting_look_direction, spin_lerp_value, spin_start)
        
func rotate_towards_direction(direction, lerp_value, rotate_from):
    if lerp_value >= 1:
        lerp_value = 1
    var rotate_to = rotate_from.looking_at(global_transform.origin + direction, Vector3(0,1,0))
    var a = Quat(rotate_from.basis)
    var new_rot = a.slerp(rotate_to.basis, lerp_value)
    set_transform(Transform(new_rot, rotate_from.origin))

func initiate_next_pod():
    if len(pod_queue) > 0:
        next_pod = pod_queue.pop_front()
        var pod_launch_location = find_next_pod_location(last_launch_angle)
        if pod_launch_location == null:
            print("ERROR: Could not find a valid pod launch location")
            return
        pod_launch_vector = find_launch_vector(pod_launch_location)
    else:
        next_pod = null
    spin_start = get_transform().orthonormalized()
    spin_lerp_value = 0

func queue_pod(pod_template):
    pod_queue.push_back(pod_template)

# Find the velocity vector that launched pod needs to be assigned to land at target position 
func find_launch_vector(target_position) -> Vector3:
    var dir = target_position - get_global_transform().origin
    var vel = dir / POD_AIR_TIME
    # v0 = (s - s0 - at^2) / t
    var pod_gravity = POD_GRAVITY_FACTOR * ProjectSettings.get("physics/3d/default_gravity")
    vel.y = (target_position.y - get_global_transform().origin.y + pod_gravity * POD_AIR_TIME * POD_AIR_TIME / 2) / POD_AIR_TIME
    return vel

# Find the next position to launch a pod based on the last launch angle
func find_next_pod_location(last_angle) -> Vector3:
    var next_angle = next_launch_angle(last_angle)
    var rad_angle = next_angle * PI / 180 
    var angle_vector = Vector2(cos(rad_angle), sin(rad_angle))
    var possible_positions = interpolate_angle_vector(angle_vector)
    var next_pod_position = find_valid_pod_position(possible_positions)
    last_launch_angle = next_angle
    return next_pod_position

func next_launch_angle(last_angle) -> int:
    var angle_from = int(last_angle + MIN_SPIN_ANGLE) % 360 
    var angle_to = int(last_angle + MAX_SPIN_ANGLE) % 360
    if angle_from > angle_to:
        angle_to += 360
    # NOTE: godot RNG contains randfn for normal distribution simulation
    return int(rng.randf_range(angle_from, angle_to)) % 360

func interpolate_angle_vector(angle_vector):
    var possible_positions = []
    for i in range ((MAX_LAUNCH_RANGE - MIN_LAUNCH_RANGE)/LAUNCH_GRANULARITY):
        # Choose a random insertion index to shuffle positions
        var insert_at = rng.randi_range(0, possible_positions.size())
        # Scale angle vector from minimum launch range according to current step and granularity
        var pos = angle_vector * (MIN_LAUNCH_RANGE + LAUNCH_GRANULARITY*i)
        possible_positions.insert(insert_at, pos)
    return possible_positions

func is_valid_launch_point(launch_point):
    if launch_point == null:
        return false
    return true

func raycast_from_sky(pos2d):
    var world_state = get_world().direct_space_state
    var from = Vector3(pos2d.x, 500, pos2d.y)
    var to = Vector3(pos2d.x, -5, pos2d.y)
    var col_info = world_state.intersect_ray(from, to)
    if col_info.size() > 0:
        return col_info.position
    else:
        return null

func find_valid_pod_position(possible_positions):
    var next_launch_pos = null
    # Iterate until we find a valid launch position or there are no possible positions left
    while next_launch_pos == null && possible_positions.size() > 0:
        var pos2d = possible_positions.pop_front()
        var world_pos = raycast_from_sky(pos2d)
        if is_valid_launch_point(world_pos):
            next_launch_pos = world_pos
    if next_launch_pos == null:
        print("ERROR: No valid launch position could be found")
    return next_launch_pos

func trigger_emergency_clear():
    playback.travel("Purge")
    explode()

func explode():
    var explosion = explosion_scene.instance()
    get_tree().get_root().add_child(explosion)
    explosion.global_transform.origin = global_transform.origin

func _on_next_pod():
    initiate_next_pod()
