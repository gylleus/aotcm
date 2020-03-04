extends KinematicBody

export var score = 100
export var chaos_movement_multiplier = 1.0
export var chaos_attack_speed_multiplier = 1.0

export var aggro_range : float = 20
export var attack_range : float = 2
export var attack_damage = 15
export var base_movement_speed = 400
export var max_health = 100
export var gravity = 9.82
export var sound_pitch = 1.0
export var nav_path_name = ""
export var stuck_timeout = 0.6
export var min_y_pos = -100
export var jump_force = 4000

export(Color, RGBA) var normal_eye_color
export(Color, RGBA) var chaos_eye_color

onready var current_health = max_health
onready var vision_ray = $VisionRay
onready var navmesh = get_tree().get_root().find_node(nav_path_name, true, false)
#onready var navmesh = get_tree().get_root().find_node("MonkeyNavigation")
onready var anim_player = get_node("AnimationPlayer")
onready var movement_speed = base_movement_speed
onready var states = {
    "idle": $States/Idle,
    "move": $States/Move,
    "falling": $States/Falling,
    "attack": $States/Attack,
    "stagger": $States/Stagger,
    "die": $States/Die
}

var state_stack = []
var current_state = null

var current_target = null
var player = null
var chaos_active = false
var last_position : Vector3
var stuck_counter = 0

func _ready():
    $MonkeyHolder/Armature/Skeleton/Body.get_surface_material(4).set_shader_param("color", normal_eye_color)
    player = Globals.get_player()
    add_to_group("enemies")
    for state in $States.get_children():
        state.connect("finish", self, "on_state_exit")
    transition_to_state("idle")
    
func validate_target():
    if !is_instance_valid(current_target) or (current_target == player and !player.is_alive):
        current_target = null 

func update_state(delta):
    var state_input = prepare_state_input(delta)
    var output = current_state.update(state_input)
    handle_state_output(output)

func fixed_update_state(delta):
    var state_input = prepare_state_input(delta)
    var output = current_state.fixed_update(state_input)
    handle_state_output(output)
    
func prepare_state_input(delta):
    var input = {
        "current_target": current_target,
        "owner": self,
        "delta": delta,
        "anim_player": anim_player
    }
    if current_state == states["idle"]:
        input["player"] = player
    elif current_state == states["move"]:
        input["player"] = player
        input["vision_ray"] = vision_ray
        input["attack_range"] = attack_range
        input["navmesh"] = navmesh
        input["movement_speed"] = movement_speed
        input["movement_multiplier"] = 1
        if chaos_active:
            input["movement_multiplier"] *= chaos_movement_multiplier
    elif current_state == states["falling"]:
        input["gravity"] = gravity
    elif current_state == states["attack"]:
        input["attack_range"] = attack_range
        input["attack_damage"] = attack_damage
        input["attack_speed"] = 1
        if chaos_active:
            input["attack_speed"] *= chaos_attack_speed_multiplier
    return input

func handle_state_output(output):
    if output == null:
        return
    if output.has("current_target"):
        current_target = output["current_target"]
    if output.has("in_air"):
        if output["in_air"] and current_state != states["falling"]:
            transition_to_state("falling")
            return
    if current_health <= 0 and current_state != states["falling"]:
        transition_to_state("die")
        Globals.total_score += score
        Globals.monkeys_killed += 1
        return
            
    if current_state == states["idle"]:
        if current_target != null:
            transition_to_state("move")
    elif current_state == states["move"]:
        if current_target == null:
            transition_to_state("idle")
        elif output["can_attack"]:
            transition_to_state("attack")
    elif current_state == states["falling"]:
        if output.has("landed") and output["landed"]:
            transition_to_state("previous")

func transition_to_state(state_name):
    if current_state == states["die"]:
        return
    anim_player.stop(true)
    if current_state != null:
        current_state.exit()
    if state_name == "previous":
        state_stack.pop_back()
        current_state = state_stack[len(state_stack)-1]
        if current_state == states["attack"]:
            transition_to_state("idle")
    elif state_name == "falling" or state_name == "stagger":
        current_state = states[state_name]
        state_stack.push_back(current_state)        
    else:
        state_stack.pop_back()
        current_state = states[state_name]
        state_stack.push_back(current_state)
    current_state.enter(anim_player)

func on_state_exit(state):
    if state != current_state:
        return
    if current_state == states["falling"]:
        transition_to_state("previous")
    elif current_state == states["die"]:
        queue_free()
    elif current_state == states["stagger"]:
        transition_to_state("previous")
    else:
        transition_to_state("idle")

func in_aggro_range(player, aggro_range):
    if is_instance_valid(player) && player.is_alive:
        return (player.global_transform.origin - global_transform.origin).length() <= aggro_range
    return false

func take_damage(damage):
    current_health -= damage

func _physics_process(delta):
    validate_target()
    check_not_stuck(delta)
    check_in_bounds()
    if current_state.has_method("fixed_update"):
        fixed_update_state(delta)
    if in_aggro_range(player, aggro_range):
        current_target = player

func _process(delta):
    validate_target()
    if current_state.has_method("update"):
        update_state(delta)
    
func bullet_hit(damage):
    take_damage(damage)
    current_target = player
    if current_health > 0 and current_state != states["falling"]:
        transition_to_state("stagger")
        stuck_counter = 0

func add_flying_force(force, damage=0):
    take_damage(damage)
    transition_to_state("falling")
    var init_values = {"force": force}
    current_state.init(init_values)

func anti_stuck():
    var launch_dir : Vector3
    if current_target != null:
        launch_dir = (current_target.global_transform.origin - global_transform.origin).normalized() + Vector3(0,3,0)
    else:
        launch_dir = Vector3(rand_range(-0.5,0.5), 0.7, rand_range(-0.5,0.5))
    add_flying_force(launch_dir.normalized() * jump_force, 0)
    stuck_counter = 0

func check_in_bounds():
    if global_transform.origin.y <= min_y_pos:
        queue_free()

func check_not_stuck(delta):
    if last_position != null and (global_transform.origin-last_position).length() < 0.3 and current_state != states["attack"]:
        stuck_counter += delta
        if stuck_counter > stuck_timeout:
            anti_stuck()
    else:
        stuck_counter = 0
        last_position = global_transform.origin

func check_oob():
    if global_transform.origin.y < -50:
        queue_free()

func start_chaos():
    chaos_active = true
    $MonkeyHolder/Armature/Skeleton/Body.get_surface_material(4).set_shader_param("color", chaos_eye_color)
    get_node("MonkeyHolder/ChaosAura").emitting = true

func stop_chaos():
    chaos_active = false
    $MonkeyHolder/Armature/Skeleton/Body.get_surface_material(4).set_shader_param("color", normal_eye_color)
    get_node("MonkeyHolder/ChaosAura").emitting = false
