extends Spatial

var next_launch_vector : Vector3

var POD_SCENE = preload("res://Models/Entities/Pod/PodScene.tscn")
onready var playback = get_node("KubeletArmature/AnimationTree").get("parameters/playback")

func print_shit():
    print("hej")

func launch_pod():
    print("heööp")
    var pod_to_launch = POD_SCENE.instance()
    get_tree().get_root().add_child(pod_to_launch)
    pod_to_launch.transform.origin = global_transform.origin
    pod_to_launch.set_linear_velocity(next_launch_vector)

func _on_Kubelet_spit_pod(launch_vector):
    next_launch_vector = launch_vector
    playback.travel("SpitPod")
