extends "res://Scripts/FSMState.gd"

"""
Input:

current_target : Object
owner : Object
attack_damage : float
attack_range : float

Output:

can_attack : bool
current_target : Object
in_air : bool

"""

var last_input 

func update(input):
	var output = input
	last_input = input
	return output

func damage(target, attack_damage):
	if target.has_method("take_damage"):
		target.take_damage(attack_damage)

func attack_hit():
	var target = last_input["current_target"]
	var owner = last_input["owner"]
	if is_instance_valid(target) && (target.get_global_transform().origin - owner.get_global_transform().origin).length() <= last_input["attack_range"]:
		damage(target, last_input["attack_damage"])
		
