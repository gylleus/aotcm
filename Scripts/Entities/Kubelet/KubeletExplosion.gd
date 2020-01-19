extends Spatial

export var explosion_size : Curve
export var explosion_duration : float
export var explosion_shape : Vector3
export var explosion_dir_elevation : float
export var explosion_force : float
export var explosion_damage : float

var time_passed : float = 0
var last_size : float = 999999999
var is_growing : bool = false

func _physics_process(delta):
    time_passed += delta
    if time_passed < explosion_duration:
        var idx = time_passed / explosion_duration
        var size = explosion_size.interpolate(idx) 
        scale = explosion_shape * size
        is_growing = size > last_size
        last_size = size
    else:
        queue_free()
    

func _on_Area_body_entered(body):
    if body.has_method("add_flying_force") and is_growing and body != Globals.get_player():
        var force_dir = body.global_transform.origin - global_transform.origin + Vector3(0, explosion_dir_elevation, 0)  
        body.add_flying_force(force_dir * explosion_force, explosion_damage)
