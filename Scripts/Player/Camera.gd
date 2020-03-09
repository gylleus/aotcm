extends Camera

export var magnitude_curve : Curve

var magnitude_start : float
var current_magnitude : float
var current_duration : float
var duration_counter : float

var original_pos : Vector3

func _ready():
    original_pos = transform.origin
    Globals.connect("shake_camera", self, "shake")

func finished_shaking():
    return duration_counter >= current_duration

func _process(delta):
    if !finished_shaking():
        duration_counter += delta
        current_magnitude = magnitude_curve.interpolate(duration_counter/current_duration) * magnitude_start
        var offset = Vector3()
        if !finished_shaking():        
            offset.x = rand_range(-current_magnitude, current_magnitude) 
            offset.y = rand_range(-current_magnitude, current_magnitude) 
        transform.origin = original_pos + offset        

func shake(magnitude, duration):
    if magnitude >= current_magnitude or finished_shaking():
        magnitude_start = magnitude
        current_magnitude = magnitude
        current_duration = duration
        duration_counter = 0
