extends Spatial

export var MAX_LAUNCH_RANGE = 10.0
export var MIN_LAUNCH_RANGE = 1.0

var launch_angle_margin = 0.02

var pod_queue = []
var next_pod = null


func _physics_process(delta):
    if next_pod == null && pod_queue.size() > 0:
        initiate_next_pod()
    if next_pod != null:
        pass


func initiate_next_pod():
    next_pod = pod_queue.pop_front()
    var next_pod_location = Vector3(5,0,0)


func queue_pod(pod_template):
    pod_queue.push_back(pod_template)

func launch_pod(next_pod):

    # IF LOOKING AT POD DIRECTION
    pass

func find_next_pod_location():
    # A. Set number of positions through list of spatial objects in scene?
    # B. Find random location based on choosing a random coordinate in range and ray-tracing from top
    # C. Use NavMesh to somehow find a point within playable area to launch pod 
    pass