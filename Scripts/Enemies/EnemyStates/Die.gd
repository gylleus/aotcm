extends "res://Scripts/Enemies/EnemyStates/FSMState.gd"

"""
Input:

Output:

"""

export var score = 100
export var decay_time = 10

onready var decay_time_remaining = decay_time

func update(input):
    input["owner"].set_collision_layer_bit(2, false)
    input["owner"].set_collision_mask_bit(2, false)
    decay_time_remaining -= input["delta"]
    if decay_time_remaining <= 0:
        finished()
