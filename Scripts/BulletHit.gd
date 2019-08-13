extends Spatial

var LIFETIME_FRAMES = 2
var frames_left

onready var sprite = get_node("Sprite")

var texture_folder = "res://Models/Sprites/BulletHits"
var textures = ["bullet_hit1.png", "bullet_hit2.png"]
#export var textures = []

func _ready():
    frames_left = LIFETIME_FRAMES
    print(randi()%textures.size())
    sprite.texture = load(texture_folder + "/" + textures[randi()%textures.size()])

func _process(delta):
    frames_left-=1
    if frames_left == 0:
        queue_free()