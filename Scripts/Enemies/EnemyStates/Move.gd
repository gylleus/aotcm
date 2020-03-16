extends "res://Scripts/Entities/Enemies/EnemyStates/FSMState.gd"

"""
Input:

navmesh : NavMesh
owner : Object
current_target : Object
vision_ray : RayCast
attack_range : float
delta : float
movement_speed : float

Output:

can_attack : bool
current_target : Object
in_air : bool

"""

export var max_slope_angle = 60
# If target moved more than path_update_range path needs to be updated
export var path_update_range = 1.0
export var waypoint_reach_margin = 0.1
export var draw_path : bool

var path = null
var path_ind = 0
var last_target_pos = null
var travelling_on_path = false

var m = SpatialMaterial.new()

func enter(anim_player):
    path = null
    path_ind = 0
    last_target_pos = null
    travelling_on_path = false
    .enter(anim_player)
    
func fixed_update(input):
    var output = {
        "current_target": input["current_target"]
    }
    travelling_on_path = false
    if !is_instance_valid(output["current_target"]):
        output["current_target"] = null
        return output
    output["can_attack"] = target_in_attack_range(input["owner"], input["current_target"], input["attack_range"])
    if !output["can_attack"]:
        var movement_speed = input["movement_speed"] * input["movement_multiplier"]
        input["anim_player"].playback_speed = animation_speed * input["movement_multiplier"]

        var destination = get_destination(input)
        var move_direction

        if destination != null:
            destination.y = owner.get_global_transform().origin.y
            owner.transform = owner.transform.looking_at(destination, Vector3(0,1,0))
            move_direction = (destination - input["owner"].get_global_transform().origin).normalized()
        else:
            move_direction = Vector3(0,0,0)
            output["current_target"] = null
  #      move_direction.y = -0.05
        move_direction = move_direction.normalized()
        var move_vector = move_direction * movement_speed * input["delta"]
        move_vector += Vector3(0,-0.1,0)# * input["delta"]
        var kekos = input["owner"].global_transform.origin
        owner.move_and_slide_with_snap(move_vector, Vector3(0,-1,0), Vector3(0,1,0), deg2rad(max_slope_angle))
        output["in_air"] = !owner.is_on_floor()# and move_direction.y < 0
    return output

func get_destination(input):
    var owner_pos = input["owner"].get_global_transform().origin
    var target_pos = input["current_target"].get_global_transform().origin
    var vision_ray_pos = input["vision_ray"].get_global_transform().origin
    
    if target_in_los(input["owner"], input["current_target"], input["vision_ray"]):
        return target_pos
    elif input.has("navmesh"):
        if !path_is_valid(target_pos):
            path = find_path(input["navmesh"], owner_pos, target_pos)
            if !path_is_valid(target_pos):
                debug_print("No valid path to target")
                return null
        travelling_on_path = true
        return travel_on_path(owner_pos)
    else:
        print("No navmesh in input to %s" % name)
        return null
 

func travel_on_path(owner_pos):
    if path != null && path_ind < path.size():
        var walk_target_pos = path[path_ind]
        var distance_to_target = (walk_target_pos - owner_pos).length()
        if distance_to_target < waypoint_reach_margin:
            path_ind += 1
        return walk_target_pos
    return null

func find_path(navmesh, from, to):
    path_ind = 1
    last_target_pos = to
    var new_path = navmesh.get_simple_path(from, to)
    if draw_path:
        var im = get_tree().get_root().get_node("Spatial/draw")
        im.set_material_override(m)
        im.clear()
        im.begin(Mesh.PRIMITIVE_POINTS, null)
        im.add_vertex(from)
        im.add_vertex(to)
        im.end()
        im.begin(Mesh.PRIMITIVE_LINE_STRIP, null)
        for x in new_path:
            im.add_vertex(x)
        im.end()
    
    return new_path 
     

func path_is_valid(target_pos):
    if path == null:
        debug_print("Path is null")
        return false
    elif path_ind >= path.size():
        debug_print("Path index greater than size")
        return false
    elif last_target_pos != null and (last_target_pos - target_pos).length() >= path_update_range:
        debug_print("Target moved away from path")
        return false
    return true


func target_in_attack_range(owner, target, attack_range):
    var owner_pos = owner.get_global_transform().origin
    var target_pos = target.get_global_transform().origin
    return (owner_pos - target_pos).length() <= attack_range

func target_in_los(owner, target, vision_ray):
    var vision_ray_pos = vision_ray.get_global_transform().origin
    var target_pos = target.get_global_transform().origin
    target_pos.y = vision_ray_pos.y
    var ray_hit = owner.get_world().get_direct_space_state().intersect_ray(vision_ray_pos, target_pos, [owner])
    if draw_path:
        var im = get_tree().get_root().get_node("Spatial/draw")
        im.set_material_override(m)
        im.clear()
        im.begin(Mesh.PRIMITIVE_POINTS, null)
        im.add_vertex(vision_ray_pos)
        im.add_vertex(target_pos)
        im.end()
        im.begin(Mesh.PRIMITIVE_LINE_STRIP, null)
        im.add_vertex(vision_ray_pos)
        im.add_vertex(target_pos)
        im.end()
    if ray_hit:
        return ray_hit.collider == target
    return false
