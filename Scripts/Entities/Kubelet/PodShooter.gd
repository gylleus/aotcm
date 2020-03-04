extends Spatial

var next_launch_vector : Vector3

var POD_SCENE = preload("res://Models/Entities/Pod/PodScene.tscn")
onready var playback = get_node("KubeletArmature/AnimationTree").get("parameters/playback")

signal next_pod
var next_template

func launch_pod():
    var pod_to_launch = POD_SCENE.instance()
    get_tree().get_root().add_child(pod_to_launch)
    pod_to_launch.transform.origin = global_transform.origin
    pod_to_launch.set_linear_velocity(next_launch_vector)
    pod_to_launch.initialize(next_template)
    emit_signal("next_pod")
    Globals.pod_launched(pod_to_launch)

func _on_Kubelet_spit_pod(launch_vector, template):
    if playback.get_current_node() != "SpitPod":
        next_template = template
        next_launch_vector = launch_vector
        playback.travel("SpitPod")
