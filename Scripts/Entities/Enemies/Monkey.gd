extends KinematicBody

var playback : AnimationNodeStateMachinePlayback

var path = []
var path_ind = 0
const ACCELERATION = 350
const MAX_MOVEMENT_SPEED = 500
const MAX_SLOPE_ANGLE = 60
var nav

var STOP_RADIUS = 2
var AGGRO_RADIUS = 5
var ATTACK_RANGE = 3
var GRAVITY = -2000
var TARGET_RECALC_DISTANCE = 10
var DRAG = 250

var current_target
# Where the target was last seen
var target_last_pos
export var current_velocity = Vector3(0,0,0)
export var flying_velocity = Vector3(0,0,0)
export var in_the_air = false

var player
var aggro_ray
onready var skeleton = get_node("MonkeyHolder/Armature/Skeleton")

export var MAX_HEALTH = 30
onready var current_health = MAX_HEALTH

func _ready():
    add_to_group("units")
    nav = get_tree().get_root().get_node("Main/Navigation")
    playback = get_node("AnimationTree").get("parameters/playback")
    player = find_player_node()
    aggro_ray = get_node("MonkeyHolder/AggroRay")
    skeleton.physical_bones_start_simulation()

func die():
    queue_free()

func bullet_hit(damage):
    print(damage)
    print(current_health)
    current_health -= damage
    flying_velocity = Vector3(0,200,0) + (global_transform.origin-player.transform.origin) * 20
    in_the_air = true
    apply_flying_movement(0.1)
   # if current_health <= 0:
       # die()

# Get reference to player
func find_player_node():
    var players = get_tree().get_nodes_in_group("player")
    if len(players) == 0:
        print("WARNING: No player object defined in groups 'player'")
    elif len(players) > 1:
        print("WARNING: More than one player object in scene")
    else:
        return players[0]
    return null

func target_in_attack_range():
    return (get_target_pos()-global_transform.origin).length() <= ATTACK_RANGE

func is_walking():
    return path == null

func select_target():
    # Check if any pods to attack
    current_target = player
    target_last_pos = get_target_pos()

func aggro_player():
    current_target = player

func will_aggro():
    pass

func get_target_pos():
    return current_target.global_transform.origin

func target_has_moved():
    return (get_target_pos() - target_last_pos).length() >= TARGET_RECALC_DISTANCE

func can_attack():
    return target_in_attack_range()

func apply_flying_movement(delta):
    flying_velocity.y += GRAVITY * delta
    move_and_slide(flying_velocity * delta, Vector3(0,1,0), deg2rad(MAX_SLOPE_ANGLE))
  #  apply_air_drag(delta)

func apply_movement(direction, speed, delta):
    current_velocity += direction * speed
    current_velocity.y += GRAVITY * delta

    if current_velocity.length() > MAX_MOVEMENT_SPEED:
        var vel_clamp = current_velocity.normalized() * MAX_MOVEMENT_SPEED
        current_velocity = vel_clamp
    move_and_slide(current_velocity * delta, Vector3(0,1,0), deg2rad(MAX_SLOPE_ANGLE))
    apply_ground_drag(delta)

func apply_ground_drag(delta):
    var applied_drag = min(current_velocity.length(), DRAG)
    current_velocity -= current_velocity.normalized() * applied_drag

func apply_air_drag(delta):
    var applied_drag = min(flying_velocity.length(), DRAG)
    flying_velocity -= flying_velocity.normalized() * applied_drag

func process_movement(delta):
    if current_target == player:
        aggro_ray.transform.basis.z  = (get_target_pos() - global_transform.origin)*10000
        aggro_ray.force_raycast_update()
        # If we can walk directly towards the player
        if aggro_ray.is_colliding():
            if aggro_ray.get_collider() == player:
                print("I SEE YOU")
                var dir = get_target_pos() - global_transform.origin
                apply_movement(dir, ACCELERATION, delta)
                return

    if (path == null || target_has_moved()):
        update_path(get_target_pos())

    if path != null && path_ind < path.size():
        var walk_target_pos = path[path_ind]
        var move_vec = (walk_target_pos - global_transform.origin)
        if move_vec.length() < STOP_RADIUS || path_ind == path.size()-1 && move_vec.length() < ATTACK_RANGE:
            path_ind += 1
            if path_ind >= path.size():
                path = null
        else:
            apply_movement(move_vec, ACCELERATION, delta)
        if walk_target_pos != null:
            look(walk_target_pos)
            playback.travel("Walking")

func _physics_process(delta):
    if is_on_floor():
        if in_the_air:
            in_the_air = false
            current_velocity = Vector3(0,0,0)
            flying_velocity = current_velocity
    elif in_the_air:
        apply_flying_movement(delta)

    if current_target == null:
        select_target()
    if current_target != player:
        if will_aggro():
            aggro_player()

    if !target_in_attack_range() && !in_the_air && playback.get_current_node() != "Attack":
        process_movement(delta)
    elif can_attack():
        look(get_target_pos())
        playback.travel("Attack")
        pass
    else:
        pass
        playback.travel("Idle")

func look(target_pos):
    var zdir = (target_pos - global_transform.origin)
    zdir.y = 0
    zdir = zdir.normalized()
    transform.basis.z = zdir
    transform.basis.x = zdir.cross(transform.basis.y)

func update_path(target_pos):
    target_last_pos = target_pos
    path = nav.get_simple_path(global_transform.origin, target_pos)
    path_ind = 0
