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
export var TARGET_RECALC_DISTANCE = 0.5
export var DRAG = 250
export var DEATH_DECAY = 5


var path = null
var path_ind = 0
var nav

var decay_counter = 0

var current_target = null
# Where the target was last seen
var target_last_pos
export var current_velocity = Vector3(0,0,0)
export var flying_velocity = Vector3(0,0,0)
export var in_the_air = false
var is_dead = false

var player
var aggro_ray
onready var skeleton = get_node("MonkeyHolder/Armature/Skeleton")

export var ATTACK_DAMAGE : float = 15
export var MAX_HEALTH : float = 30
export var WEIGHT : float = 1.0
onready var current_health = MAX_HEALTH

func _ready():
    add_to_group("units")
    nav = get_tree().get_root().get_node("Main/Navigation")
    playback = get_node("AnimationTree").get("parameters/playback")
    player = find_player_node()
    aggro_ray = get_node("MonkeyHolder/AggroRay")

func _physics_process(delta):
    if player == null:
        find_player_node()
        return
    
    if !is_dead:
        if is_on_floor():
            if in_the_air:
                in_the_air = false
                current_velocity = Vector3(0,0,0)
                flying_velocity = Vector3(0,0,0)
                path = null
        elif in_the_air:
            apply_flying_movement(delta)

        if !is_instance_valid(current_target):
            select_target()
        if current_target != player:
            if will_aggro():
                aggro_player()

        if is_instance_valid(current_target):
            if can_attack():
                look(get_target_pos())
                playback.travel("Attack")
            elif !in_the_air && playback.get_current_node() != "Attack":
                process_movement(delta)
            else:
                playback.travel("Idle")
        else:
            playback.travel("Idle")
    else:
        decay_counter += delta
        if decay_counter >= DEATH_DECAY:
            queue_free()

func die():
    is_dead = true
    playback.travel("Death")
   # get_node("BodyCollider").disabled = true
   # get_node("HeadCollider").disabled = true

func bullet_hit(damage):
    current_health -= damage
    aggro_player()
    if current_health <= 0:
       die()

func add_flying_force(force):
    in_the_air = true
    flying_velocity += force / WEIGHT
    apply_flying_movement(0.1)

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
    # Check if we can walk directly towards the player
    var walk_target_pos = null
    if current_target == player and player_in_los():
        walk_target_pos = get_target_pos()
    else:
        if (path == null || target_has_moved()):
            update_path(get_target_pos())
        walk_target_pos = travel_on_path()
    if walk_target_pos != null:
        var dir = walk_target_pos - global_transform.origin
        apply_movement(dir, ACCELERATION, delta)
        look(walk_target_pos)
        playback.travel("Walking")

func player_in_los():
    var space_state = get_world().get_direct_space_state()
    var hit = space_state.intersect_ray(aggro_ray.global_transform.origin, get_target_pos(), [], 3)
    if hit:
        var asf = hit.collider
        if hit.collider == player:
            return true
    return false

func travel_on_path():
    if path != null && path_ind < path.size():
        var walk_target_pos = path[path_ind]
        var distance_to_target = (walk_target_pos - global_transform.origin).length()
        if distance_to_target < STOP_RADIUS:
            path_ind += 1
            if path_ind >= path.size():
                path = null
                return null
        return walk_target_pos
    return null

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
    if len(path) == 0:
        select_target()

func hit_target():
    if is_instance_valid(current_target) && target_in_range(ATTACK_REACH_RANGE):
        if current_target.has_method("take_damage"):
            current_target.take_damage(ATTACK_DAMAGE)
        else:
            print("WARNING: Attacked target has no take_damage method")
