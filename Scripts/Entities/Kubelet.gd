extends Spatial

export var MAX_LAUNCH_RANGE = 10.0
export var MIN_LAUNCH_RANGE = 1.0
# Controls how many points are created when interpolating launch angle vector
export var LAUNCH_GRANULARITY = 0.5

export var MIN_SPIN_ANGLE = 60
export var MIN_POD_DISTANCE= 2.0
export var POD_AIR_TIME = 2.0

var launch_angle_margin = 0.02

var pod_queue = []
var next_pod = null

var pod_launch_location = null
var last_launch_angle = null
# Random number generator
var rng = RandomNumberGenerator.new()

const PodTemplate = preload("PodTemplate.gd")
onready var globals = get_node("/root/Globals")

func _ready():
    rng.randomize()
    # Set a random "previous" launch angle 
    last_launch_angle = rng.randf_range(0.0, 360.0)
    queue_pod(PodTemplate.new(50,"test"))

func _physics_process(delta):
    global_rotate(Vector3(0,1,0), 0.05)
  #  print(get_global_transform().basis.z)
    if next_pod == null && pod_queue.size() > 0:
        initiate_next_pod()
    if next_pod != null:
       # var launch_dir = print(pod_launch_location - get_global_transform().pos)
        print(find_launch_vector(Vector3(10,3,0)))
        pass
   # print(find_next_pod_location(last_launch_angle))


func initiate_next_pod():
    next_pod = pod_queue.pop_front()
    pod_launch_location = find_next_pod_location(last_launch_angle)


func queue_pod(pod_template):
    pod_queue.push_back(pod_template)

func launch_pod(next_pod):

    # IF LOOKING AT POD DIRECTION
    pass

# Find the velocity vector that launched pod needs to be assigned to land at target position 
func find_launch_vector(target_position):
    var dir = target_position - get_global_transform().origin
    var vel = dir / POD_AIR_TIME
    # v0 = (s - s0 - at^2) / t
    vel.y = (target_position.y - get_global_transform().origin.y - globals.POD_GRAVITY * POD_AIR_TIME * POD_AIR_TIME / 2) / POD_AIR_TIME
    return vel

# Find the next position to launch a pod based on the last launch angle
func find_next_pod_location(last_angle):
    var next_angle = next_launch_angle(last_angle)
    var angle_vector = Vector2(cos(next_angle), sin(next_angle))
    var possible_positions = interpolate_angle_vector(angle_vector)
    var next_pod_position = find_valid_pod_position(possible_positions)

    last_launch_angle = next_angle
    return next_pod_position

func next_launch_angle(last_angle):
    var angle_from = int(last_launch_angle + MIN_SPIN_ANGLE) % 360 
    var angle_to = int(last_launch_angle - MIN_SPIN_ANGLE) % 360
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
