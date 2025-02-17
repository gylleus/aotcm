extends Spatial

export var SPAWN_RADIUS = 20
export var SPAWN_PADDING = 3
export var chaos_spawn_divider = 8
export var difficulty_to_points_multiplier : float
export var wave_base_points : float = 18
export var nav_path_name : String
export var portal_spawn_angle_threshold : float = 0.7

onready var navmesh = get_tree().get_root().find_node(nav_path_name, true, false)

var enemy_types = []
var rng = RandomNumberGenerator.new()
var portal_scene = preload("res://Models/Entities/Portal/Portal.tscn")
var origin_point : Vector3


func _ready():
    rng.randomize()
    for child in get_children():
        enemy_types.push_back(child)
    origin_point = raycast_from_sky(Vector2(0,0))

func get_spawn_angle():
    return rng.randf_range(0,2 * PI)

func is_valid_spawn_location(location):
    if location == null:
        return false
    var path = navmesh.get_simple_path(location, origin_point) 
    return path != null

func select_spawn_location(max_attempts=30):
    var spawn_location = null
    var attempts = 0
    while !is_valid_spawn_location(spawn_location) and attempts < max_attempts:   
        var spawn_angle = get_spawn_angle()
        var angle_vector  = Vector2(cos(spawn_angle), sin(spawn_angle)) * SPAWN_RADIUS
        spawn_location = raycast_from_sky(angle_vector)
        attempts += 1
    return spawn_location

func raycast_from_sky(pos2d):
    var world_state = get_world().direct_space_state
    var from = Vector3(pos2d.x, 5, pos2d.y)
    var to = Vector3(pos2d.x, -50, pos2d.y)
    var col_info = world_state.intersect_ray(from, to)
    if col_info.size() > 0 and col_info["normal"].dot(Vector3(0, 1, 0)) > portal_spawn_angle_threshold:
        return col_info.position
    else:
        return null

# Each enemy is worth a certain amount 
func select_enemy(points):
    if enemy_types.size() == 0:
        print("ERROR: No enemy types available to spawn")
        return null
    var enemy = null
    # TODO: Make smarter and more efficient
#    while enemy == null or enemy.difficulty_points > points:
    # TODO: Fix if ever add more enemies
    if enemy_types[0].difficulty_points <= points:
        enemy = enemy_types[0]
    return enemy

func get_wave_enemies(difficulty):
    var difficulty_points = wave_base_points + difficulty * difficulty_to_points_multiplier
    if Globals.chaos_active:
        difficulty_points /= chaos_spawn_divider
    var enemies = []
    while difficulty_points > 0:
        var next_enemy = select_enemy(difficulty_points)
        if next_enemy == null:
            break
        else:
            difficulty_points -= next_enemy.difficulty_points
            enemies.push_back(next_enemy)
    return enemies

# Function to get how far from the center of chosen spawn point specific enemy should spawn
func get_spawn_locations(origin, num_points):
    var spawn_locations = []
    var spawn_angle = 0
    for i in range(num_points):
        var offset = Vector3(cos(spawn_angle), 0, sin(spawn_angle)) * SPAWN_PADDING
        spawn_angle += 2 * PI / num_points
        spawn_locations.push_back(origin + offset)
    return spawn_locations

func spawn_enemy(location, enemy):
    var new_enemy = enemy.scene.instance()
    add_child(new_enemy)
    new_enemy.transform.origin = location
    if Globals.chaos_active:
        new_enemy.start_chaos()

func _spawn_wave(difficulty):
    print("Started spawning")
    var spawn_origin = select_spawn_location()
    if !is_valid_spawn_location(spawn_origin):
        print("ERROR: Could not find valid spawn location for enemies")
    else:
        var enemies_in_wave = get_wave_enemies(difficulty)
        var new_portal = portal_scene.instance()
        get_tree().get_root().add_child(new_portal)
        new_portal.global_transform.origin = spawn_origin
        new_portal.global_transform = new_portal.global_transform.looking_at(Vector3(0,spawn_origin.y, 0), Vector3(0,1,0))
        new_portal.enemies = enemies_in_wave  
            
