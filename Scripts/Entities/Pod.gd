extends Spatial

export var POD_MAX_HEALTH = 100
onready var health_left = POD_MAX_HEALTH

onready var playback = get_node("AnimationTree").get("parameters/playback")

func _ready():
    add_to_group("pods")

func take_damage(amount):
    health_left -= amount
    playback.travel("BeginAttacked")
