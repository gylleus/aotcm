extends Node

var max_health
var pod_name
var color

func _init(name, health=100):
	self.max_health = health
	self.pod_name = name
	self.color = Color(25,25,25)
