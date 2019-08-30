extends KinematicBody

var playback : AnimationNodeStateMachinePlayback

export var ACCELERATION = 350
export var MAX_MOVEMENT_SPEED = 500
export var MAX_SLOPE_ANGLE = 60

export var STOP_RADIUS : float = 2
export var AGGRO_RADIUS : float = 5
export var ATTACK_RANGE : float = 3
export var ATTACK_REACH_RANGE : float = 5
export var GRAVITY = -2000
export var TARGET_RECALC_DISTANCE = 10
export var DRAG = 250
export var DEATH_DECAY = 5


var path = null
var path_ind = 0
var nav

var decay_counter = 0

var current_target
# Where the target was last seen
var target_last_pos
export var current_velocity = Vector3(0,0,0)
export var flying_velocity = Vector3(0,0,0)
export var in_the_air = false
var is_dead = false

var player
var aggro_ray
onready var skeleton = get_node("MonkeyHolder/Armature/Skeleton")

export var ATTACK_DAMAGE = 15
export var MAX_HEALTH = 30
onready var current_health = MAX_HEALTH

func _ready():
    add_to_group("units")
    nav = get_tree().get_root().get_node("Main/Navigation")
    playback = get_node("AnimationTree").get("parameters/playback")
    player = find_player_node()
    aggro_ray = get_node("MonkeyHolder/AggroRay")


func _physics_process(delta):
    if !is_dead:
        if is_on_floor():
            if in_the_air:
                in_the_air = false
                current_velocity = Vector3(0,0,0)
                flying_velocity = current_velocity
                path = null
        elif in_the_air:
            apply_flying_movement(delta)

        if current_target == null:
            select_target()
        if current_target != player:
            if will_aggro():
                aggro_player()

        if can_attack():
            look(get_target_pos())
            process_movement(delta)
            playback.travel("Attack")
        elif !in_the_air && playback.get_current_node() != "Attack":
            process_movement(delta)
        else:
            playback.travel("Idle")
    else:
        decay_counter += delta
        move_and_slide(Vector3(0,GRAVITY,0) * delta, Vector3(0,1,0), deg2rad(MAX_SLOPE_ANGLE))
        if decay_counter >= DEATH_DECAY:
            queue_free()

func die():
    is_dead = true
    playback.travel("Death")
   # get_node("BodyCollider").disabled = true
   # get_node("HeadCollider").disabled = true

func bullet_hit(damage):
    current_health -= damage
    flying_velocity = Vector3(0,2000,0) + (global_transform.origin-player.transform.origin) * 20
    in_the_air = true
    apply_flying_movement(0.1)
    if current_health <= 0:
       die()

func find_pods():
    return get_tree().get_nodes_in_group("pods")

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

func target_in_range(r):
    return (get_target_pos()-global_transform.origin).length() <= r

func is_walking():
    return path == null

func select_target():
    # Check if any pods to attack
    var pods = find_pods()
    var closest_pod = null
    for p in pods:
        if closest_pod == null || (p.global_transform.origin - global_transform.origin).length() < (closest_pod.global_transform.origin - global_transform.origin).length():
            closest_pod = p
    current_target = closest_pod
    if current_target == null:
        current_target = player
    target_last_pos = get_target_pos()

func aggro_player():
    current_target = player

func will_aggro():
    return (player.global_transform.origin - global_transform.origin).length() <= AGGRO_RADIUS

func get_target_pos():
    return current_target.global_transform.origin

func target_has_moved():
    return (get_target_pos() - target_last_pos).length() >= TARGET_RECALC_DISTANCE

func can_attack():
    return target_in_range(ATTACK_RANGE)

func apply_flying_movement(delta):
    flying_velocity.y += GRAVITY * delta
    move_and_slide(flying_velocity * delta, Vector3(0,1,0), deg2rad(MAX_SLOPE_ANGLE))
  #  apply_air_drag(delta)

func apply_movement(direction, speed, delta):
    current_velocity += direction * speed
    current_velocity.y += GRAVITY * delta
    var hvel = current_velocity
    hvel.y = 0

    if hvel.length() > MAX_MOVEMENT_SPEED:
        var vel_clamp = hvel.normalized() * MAX_MOVEMENT_SPEED
        current_velocity.x = vel_clamp.x
        current_velocity.z = vel_clamp.z
    move_and_slide(current_velocity * delta, Vector3(0,1,0), deg2rad(MAX_SLOPE_ANGLE))
    apply_ground_drag(delta)

func apply_ground_drag(delta):
    var applied_drag = min(current_velocity.length(), DRAG)
    current_velocity -= current_velocity.normalized() * applied_drag

func apply_air_drag(delta):
    var applied_drag = min(flying_velocity.length(), DRAG)
    flying_velocity -= flying_velocity.normalized() * applied_drag

func process_movement(delta):
    if current_target == player && false:
        aggro_ray.transform.basis.z  = (get_target_pos() - global_transform.origin)*10000
        aggro_ray.force_raycast_update()
        # If we can walk directly towards the player
        if aggro_ray.is_colliding():
            if aggro_ray.get_collider() == player:
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

func hit_target():
    if target_in_range(ATTACK_REACH_RANGE):
        if current_target.has_method("take_damage"):
            current_target.take_damage(ATTACK_DAMAGE)
        else:
            print("WARNING: Attacked target has no take_damage method")
