extends Node

export var DEBUG : bool = false 

export var animation_name = ""
export var animation_speed = 1.0

signal finish

func enter(anim_player):
    if anim_player != null and animation_name != "":
        anim_player.playback_speed = animation_speed
        anim_player.play(animation_name)
    debug_print("Entered %s" % name)


func init(init_values):
    debug_print("Initializing %s" % name)

func exit():
    debug_print("Exiting %s" % name)

func finished():
    emit_signal("finish", self)
    debug_print("Finished %s" % name)
    
func debug_print(message):
    if DEBUG:
        print(message)