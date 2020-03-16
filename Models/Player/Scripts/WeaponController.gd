extends AnimationTree

export var damage = 5
export var MAGAZINE_SIZE = 30
export var hitmark : NodePath

var playback : AnimationNodeStateMachinePlayback
onready var player = get_node("..")
var fire_ray

var bullets_left

var ammo_label

var BULLET_HIT = preload("res://Scenes/Visuals/BulletHit.tscn")
var BULLET_PARTICLE_HIT = preload("res://Scenes/Visuals/BulletParticleHit.tscn")

var start_reload_sound = preload("res://Models/Player/Audio/StartReload.wav")
var reload_sound = preload("res://Models/Player/Audio/Reload.wav")

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
    $"../GunSound".play()
    fire_ray.force_raycast_update()
    if fire_ray.is_colliding():
        var body = fire_ray.get_collider()
        if body.has_method("bullet_hit"):
            body.bullet_hit(damage)
            player.current_kube_power += player.kube_power_per_damage_dealt * damage
            var bh = BULLET_HIT.instance()
            get_tree().root.add_child(bh)
            var kekos = fire_ray.get_collision_point()
            bh.global_transform.origin = fire_ray.get_collision_point()
            bh.transform.basis = player.transform.basis
            $"../HitmarkSound".play()
            get_node(hitmark).show()
        else:
            var bh = BULLET_PARTICLE_HIT.instance()
            get_tree().root.add_child(bh)
            bh.global_transform.origin = fire_ray.get_collision_point()
            # TODO: Make transform basis Z the reflected vector in regard to meshes normal
            #bh.transform.basis.z = player.transform.basis.z
            

func finish_reload():
    bullets_left = MAGAZINE_SIZE
    
func play_reload_sound():
    $"../ReloadSound".stream = reload_sound
    $"../ReloadSound".play()
