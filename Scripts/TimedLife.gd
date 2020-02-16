extends Spatial

export var LIFETIME : float = 1
var time_left : float

func _ready():
    time_left = LIFETIME
    
func _process(delta):
    time_left -= delta
    if time_left <= 0:
        queue_free()
