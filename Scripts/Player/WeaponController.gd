extends AnimationTree

var playback : AnimationNodeStateMachinePlayback
onready var player = get_node("..")
var fire_ray

var damage = 5
var MAGAZINE_SIZE = 300
var bullets_left

var ammo_label

var BULLET = preload("res://Scenes/Bullet.tscn")
var BULLET_HIT = preload("res://Scenes/Visuals/BulletHit.tscn")
var BULLET_PARTICLE_HIT = preload("res://Scenes/Visuals/BulletParticleHit.tscn")
onready var FIREPOINT = get_node("RotationHelper/Camera/FirePoint")

onready var globals = get_node("/root/Globals")

func _ready():
    playback = get("parameters/playback")
    playback.start("idle")
    active = true
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
    globals.play_sound("RifleShot", false, player.global_transform.origin)
    fire_ray.force_raycast_update()
    if fire_ray.is_colliding():
        print(fire_ray.get_collider())
        var body = fire_ray.get_collider()
        if body.has_method("bullet_hit"):
            body.bullet_hit(damage)
            var bh = BULLET_HIT.instance()
            bh.global_transform.origin = fire_ray.get_collision_point()
            bh.transform.basis = player.transform.basis
            get_tree().root.add_child(bh)
        else:
            print("spawned")
            var bh = BULLET_PARTICLE_HIT.instance()
            bh.global_transform.origin = fire_ray.get_collision_point()
            # TODO: Make transform basis Z the reflected vector in regard to meshes normal
            #bh.transform.basis.z = player.transform.basis.z
            get_tree().root.add_child(bh)
            

func finish_reload():
    bullets_left = MAGAZINE_SIZE