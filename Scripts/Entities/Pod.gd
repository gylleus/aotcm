extends Spatial

export var MAX_HEALTH = 100
export var EXPLOSION_FORCE = 10
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
    pass

func explode(force):
    var bodies = explosion_area.get_overlapping_bodies()