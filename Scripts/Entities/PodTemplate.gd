extends Node

var max_health
var pod_name
var color
var namespace

func _init(pod_name, ns, health=100):
    self.max_health = health
    self.name = pod_name
    self.color = Color(25,25,25)
    self.namespace = ns
