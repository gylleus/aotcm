extends Spatial

const KubernetesStateHandler = preload("KubernetesStateHandler.gd")

var k8s_handler

func _process(delta):
    k8s_handler = KubernetesStateHandler.new("https://localhost", 16443)
    k8s_handler.get_pod_list()

