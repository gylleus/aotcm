extends KinematicBody

export var aggro_range = 20
export var attack_range = 2
export var attack_damage = 15
export var movement_speed = 500
export var max_health = 100
export var gravity = 9.82
export(NodePath) var nav_path
var state_stack = []
var current_state = null

var current_target = null
var player = null


onready var current_health = max_health
onready var vision_ray = $VisionRay
onready var navmesh = get_node(nav_path)
onready var anim_player = get_node("AnimationPlayer")
onready var states = {
    "idle": $States/Idle,
    "move": $States/Move,
    "falling": $States/Falling,
    "attack": $States/Attack,
    "stagger": $States/Stagger,
    "die": $States/Die
}

func _ready():
    player = find_player_node()
    for state in $States.get_children():
        state.connect("finish", self, "on_state_exit")
    transition_to_state("idle")

func find_player_node():
    var players = get_tree().get_nodes_in_group("player")
    if len(players) == 0:
        print("WARNING: No player object defined in groups 'player'")
    elif len(players) > 1:
        print("WARNING: More than one player object in scene")
    else:
        return players[0]
    return null

func update_state(delta):
    var state_input = prepare_state_input(delta)
    var output = current_state.update(state_input)
    handle_state_output(output)

func fixed_update_state(delta):
    if in_aggro_range(player, aggro_range):
        current_target = player
    var state_input = prepare_state_input(delta)
    var output = current_state.fixed_update(state_input)
    handle_state_output(output)
    
func prepare_state_input(delta):
    var input = {
        "current_target": current_target,
        "owner": self,
        "delta": delta
    }
    if current_state == states["idle"]:
        input["player"] = player
    elif current_state == states["move"]:
        input["player"] = player
        input["vision_ray"] = vision_ray
        input["attack_range"] = attack_range
        input["navmesh"] = navmesh
        input["movement_speed"] = movement_speed
    elif current_state == states["falling"]:
        input["gravity"] = gravity
    elif current_state == states["attack"]:
        input["attack_range"] = attack_range
        input["attack_damage"] = attack_damage
    return input

func handle_state_output(output):
    if output == null:
        return
    if output.has("current_target"):
        current_target = output["current_target"]
    if output.has("in_air"):
        if output["in_air"] and current_state != states["falling"]:
            transition_to_state("falling")
            
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
    return (player.global_transform.origin - global_transform.origin).length() <= aggro_range

func _physics_process(delta):
    if current_state.has_method("fixed_update"):
        fixed_update_state(delta)

func _process(delta):
    if current_state.has_method("update"):
        update_state(delta)
    
func bullet_hit(damage):
    current_health -= damage
    if current_health > 0 and current_state != states["falling"]:
        transition_to_state("stagger")
    elif current_state != states["die"]:
        transition_to_state("die")

func add_flying_force(force):
    transition_to_state("falling")
    var init_values = {"force": force}
    current_state.init(init_values)
