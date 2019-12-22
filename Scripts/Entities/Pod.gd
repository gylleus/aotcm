extends RigidBody

export var MAX_HEALTH : float = 100
export var EXPLOSION_FORCE : float = 500.0
export var EXPLOSION_DIR_ELEVATION : float = 5

onready var health_left = MAX_HEALTH
onready var playback = get_node("Pod/PodArmature/AnimationTree").get("parameters/playback")
onready var explosion_area : Area = get_node("ExplosionArea")
var explosion_particles_scene = preload("res://Models/Entities/Pod/PodExplosion.tscn")

func _ready():
    add_to_group("pods")

func _physics_process(delta):
    if get("contact_monitor") && len(get_colliding_bodies()) > 0:
        land()

func land():
    set("contact_monitor", false)
    set("axis_lock_linear_x", true)
    set("axis_lock_linear_z", true)

func bullet_hit(_damage):
    take_damage(0)

func take_damage(amount):
    health_left -= amount
    if health_left <= 0:
        playback.travel("Explode")
    else:
        playback.travel("Attacked")

func emitt_particles():
    var explosion_particles = explosion_particles_scene.instance()
    get_tree().get_root().add_child(explosion_particles)
    explosion_particles.transform.origin = global_transform.origin
    explosion_particles.emitting = true

func die():
    # TODO: Send signal that Pod has died
    queue_free()

func explode():
    var force = EXPLOSION_FORCE
    var blast_targets = explosion_area.get_overlapping_bodies()
    for target in blast_targets:
        if target.has_method("add_flying_force"):
            var force_dir = target.global_transform.origin - global_transform.origin + Vector3(0, EXPLOSION_DIR_ELEVATION, 0)  
            target.add_flying_force(force_dir * force)
    die()