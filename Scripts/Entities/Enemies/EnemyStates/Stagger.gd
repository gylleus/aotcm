extends "res://Scripts/FSMState.gd"

"""
Input:

Output:

"""

func fixed_update(input):
    var output = input
    output["in_air"] = !input["owner"].is_on_floor()
    return output