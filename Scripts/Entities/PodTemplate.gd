var max_health
var pod_name
var color

func _init(pod_name, health=100):
    self.max_health = health
    self.pod_name = pod_name
    self.color = Color(25,25,25)
