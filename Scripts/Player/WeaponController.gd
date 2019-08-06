extends AnimationTree


var playback : AnimationNodeStateMachinePlayback
var player
var fire_ray

var damage = 5

var MAGAZINE_SIZE = 30
var bullets_left

var ammo_label

func _ready():
    playback = get("parameters/playback")
    playback.start("idle")
    active = true
    player = $"../AnimationPlayer"
    fire_ray = $"../RotationHelper/Camera/FirePoint/FireRay"
    bullets_left = MAGAZINE_SIZE
    ammo_label = $"../HUD/AmmoBar/AmmoText"

func _process(delta):
    ammo_label.text = str(bullets_left) + "/" + str(MAGAZINE_SIZE)
    if playback.get_current_node() != "reload":
        if Input.is_action_pressed("player_shoot"):
            playback.travel("fire")
        elif Input.is_action_just_released("player_shoot"):
            playback.travel("idle")
    if Input.is_action_just_pressed("reload") && bullets_left < MAGAZINE_SIZE || bullets_left == 0:
        playback.travel("reload")


func fire_bullet():
    if bullets_left == 0:
        return
    bullets_left -= 1
    fire_ray.force_raycast_update()
    if fire_ray.is_colliding():
        var body = fire_ray.get_collider()
        if body.has_method("bullet_hit"):
            body.bullet_hit(damage)
    pass

func finish_reload():
    bullets_left = MAGAZINE_SIZE