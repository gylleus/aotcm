extends Spatial

var FRAMES_VISIBLE = 2
var frames_left = 0

# Called when the node enters the scene tree for the first time.
func _ready():
    visible = false
    
func _process(delta):
    if (frames_left > 0):
        frames_left -= 1
        if frames_left == 0:
            visible = false
            
func show_and_rotate():
    #rotate_z(rand_range(0.1,  PI/2))
    rotate_z(PI/2)
    visible = true
    frames_left = FRAMES_VISIBLE
