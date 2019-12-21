extends "res://Scripts/FSMState.gd"

func update(input):
    var output = {}    
    var current_target = input["current_target"]
    var owner = input["owner"]
    if current_target == null:
        current_target = find_closest_pod(owner)
    output["current_target"] = current_target
    return output

func find_closest_pod(owner):
    # Check if any pods to attack
    var pods = find_pods()
    var closest_pod = null
    for p in pods:
        if closest_pod == null || (p.global_transform.origin - owner.global_transform.origin).length() < (closest_pod.global_transform.origin - owner.global_transform.origin).length():
            closest_pod = p
    return closest_pod

func find_pods():
    return get_tree().get_nodes_in_group("pods")

