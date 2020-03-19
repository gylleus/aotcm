extends "res://Scripts/Enemies/EnemyStates/FSMState.gd"

"""
Input:

gravity : float
delta : float

Output:

current_target : Object

"""

var flying_force : Vector3

func init(init_values):
    #$AudioPlayer.play()
    if init_values.has("force"):
        flying_force = init_values["force"]
    else:
        flying_force = Vector3(0,0,0)
    .init(init_values)

func fixed_update(input):
    var output = {
        "current_target": input["current_target"],
        "landed": false
    }
    owner = input["owner"]
    flying_force -= Vector3(0, input["gravity"], 0)
    owner.move_and_slide(flying_force * input["delta"], Vector3(0,1,0))
    if owner.is_on_floor() and flying_force.y <= 0:
        output["landed"] = true
    
    return output
