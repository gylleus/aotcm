extends "res://Scripts/FSMState.gd"

"""
Input:

Output:

"""

export var decay_time = 10

onready var decay_time_remaining = decay_time

func update(input):
	decay_time_remaining -= input["delta"]
	if decay_time_remaining <= 0:
		finished()