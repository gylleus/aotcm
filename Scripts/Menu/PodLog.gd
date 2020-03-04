extends RichTextLabel

export var max_length = 5

var lines = []

func _ready():
    Globals.connect("pod_died", self, "pod_died")
    Globals.connect("pod_launched", self, "pod_launched")
    pass # Replace with function body.

func pod_death_string(pod):
    return "Pod %s lost\n" % pod.template.name

func pod_launch_string(pod):
    return "New pod %s launched\n" % pod.template.name

func pod_died(pod):
    add_line(pod_death_string(pod))
    
func pod_launched(pod):
    add_line(pod_launch_string(pod))

func add_line(string):
    while len(lines) >= max_length:
        lines.pop_back()
    lines.push_front(string)
    var t = ""
    for l in lines:
        t += l
    text = t
