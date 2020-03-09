extends Spatial

export var explosion_size : Curve
export var explosion_duration : float
export var explosion_shape : Vector3
export var explosion_dir_elevation : float
export var explosion_force : float
export var implosion_force : float
export var explosion_damage : float
export var implosion_time_scale : float = 0.5

export var camera_shake_magnitude : float = 0.4
export var camera_shake_duration : float = 3.0

var time_passed : float = 0
var last_size : float = 999999999
var is_growing : bool = false

var exploded = false
var original_sound_pitch

func _ready():
    Engine.time_scale = implosion_time_scale
    original_sound_pitch = $ExplosionSound.pitch_scale
    $ExplosionSound.pitch_scale = original_sound_pitch * implosion_time_scale
    $ExplosionSound.play()
    
func _physics_process(delta):
    time_passed += delta
    if time_passed < explosion_duration:
        var idx = time_passed / explosion_duration
        var size = explosion_size.interpolate(idx) 
        scale = explosion_shape * size
        is_growing = size > last_size
        last_size = size
        if is_growing and !exploded:
            start_explode()
    else:
        queue_free()

func start_explode():
    exploded = true
    Engine.time_scale = 1
    $ExplosionSound.pitch_scale = original_sound_pitch
    Globals.shake_camera(camera_shake_magnitude, camera_shake_duration)
    
func _on_Area_body_entered(body):
    if body.has_method("add_flying_force") and body != Globals.get_player() and is_growing:
        var force_dir = body.global_transform.origin - global_transform.origin + Vector3(0, explosion_dir_elevation, 0)  
        body.add_flying_force(force_dir * explosion_force, explosion_damage)
            
func _on_Area_body_exited(body):
    if body.has_method("add_flying_force") and body != Globals.get_player() and !is_growing:
            var force_dir = global_transform.origin - body.global_transform.origin + Vector3(0, explosion_dir_elevation/2, 0)  
            body.add_flying_force(force_dir * implosion_force, 0)
