extends Spatial

export var MAX_HEALTH : float = 100
export var EXPLOSION_FORCE : float = 10.0
export var EXPLOSION_DIR_ELEVATION : float = 2
onready var health_left = MAX_HEALTH

#onready var playback = get_node("AnimationTree").get("parameters/playback")
onready var explosion_area : Area = get_node("ExplosionArea")

func _ready():
    add_to_group("pods")

func take_damage(amount):
    health_left -= amount
    if health_left <= 0:
        explode(EXPLOSION_FORCE)
#    playback.travel("BeginAttacked")

func die():
    # TODO: Send signal that Pod has died
    queue_free()

func explode(force):
    var blast_targets = explosion_area.get_overlapping_bodies()
    for target in blast_targets:
        if target.has_method("add_central_impulse"):
            var force_dir = target.global_transform.origin - global_transform.origin + Vector3(0, EXPLOSION_DIR_ELEVATION, 0)  
            target.add_central_impulse(force_dir * force)
    die()