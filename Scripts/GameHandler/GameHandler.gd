extends Spatial

signal spawn_wave

#export var chaos_spawn_multiplier : float = 1

export var game_over_scene : String
export var score_per_second = 75
export var spawn_interval = 15
export var chaos_spawn_multiplier = 2.5
export var start_difficulty : float = 1
export var difficulty_increment_per_minute : float = 1
export var pod_health = 100
export var max_pod_amount = 10

export var music_min_db : float = -80
export var music_max_db : float = -4.5
export var chaos_music_max_db : float = -8.5

onready var chaos_start_timer = get_node("ChaosStartTimer")
onready var chaos_stop_timer = get_node("ChaosStopTimer")
onready var spawn_timer = get_node("ChaosStopTimer")
onready var spawn_pos = $PlayerSpawn

var k8s_handler
onready var current_difficulty : float = start_difficulty
var chaos_active = false
var dummy_pods_launched = 0

const PodTemplate = preload("res://Models/Entities/Pod/Scripts/PodTemplate.gd")

func _ready():
    $MusicPlayer.play()
    $MusicPlayer.volume_db = music_max_db
    chaos_start_timer.start()
    Globals.connect("kill_player", self, "kill_player")
    Globals.connect("pod_died", self, "_on_pod_died")
    $UpdateState.wait_time = KubernetesServer.client_poll_interval
    $UpdateState.start()
    get_initial_pods()
    
func get_initial_pods():
    if KubernetesServer.connected:
        $KubernetesStateHandler.update_state()
    else:
        queue_dummy_pods()

func queue_dummy_pods():
    var current_pods = get_tree().get_nodes_in_group("pods")
    var kubelet = get_tree().get_nodes_in_group("kubelet")[0]
    var pod_amount = max_pod_amount - (len(current_pods) + len(kubelet.pod_queue))
    var templates = []
    for p in current_pods:
        templates.push_back(p.template)
    for i in range(pod_amount):
        dummy_pods_launched += 1
        templates.push_back(PodTemplate.new("pod-%s" % dummy_pods_launched, pod_health))
    update_pods(templates)

func _process(delta):
    Globals.total_score += delta * score_per_second
    if Globals.survival:
        current_difficulty += difficulty_increment_per_minute * delta / 60
        for enemy in get_tree().get_nodes_in_group("enemies"):
            enemy.movement_speed = enemy.base_movement_speed + enemy.base_movement_speed * current_difficulty / 8.0
        if Globals.pods_lost >= Globals.lose_when_pods_killed:
            end_game()

func end_game():        
    Globals.clean_scene()
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    get_tree().change_scene(game_over_scene)

func get_next_spawn_timer():
    var time = spawn_interval / current_difficulty
    if Globals.chaos_active:
        time /= chaos_spawn_multiplier
    return time

func _on_EnemySpawnTimer_timeout():
    $EnemySpawnTimer.wait_time = get_next_spawn_timer()
    emit_signal("spawn_wave", current_difficulty)

func clear_portals():
    for portal in get_tree().get_nodes_in_group("portals"):
        portal.stop()

func _start_chaos():
    $FadeOut.interpolate_property($MusicPlayer, "volume_db", music_max_db,
    music_min_db, 2.0, Tween.TRANS_LINEAR, Tween.EASE_OUT)
    $FadeIn.interpolate_property($ChaosMusicPlayer, "volume_db", music_min_db,
    chaos_music_max_db, 0.5, Tween.TRANS_LINEAR, Tween.EASE_OUT)
    $FadeOut.start()
    $FadeIn.start()
    $ChaosMusicPlayer.volume_db = music_min_db
    $ChaosMusicPlayer.play()
    var enemies = get_tree().get_nodes_in_group("enemies")
    for enemy in enemies:
        enemy.start_chaos()
    Globals.chaos_active = true
    clear_portals()
    _on_EnemySpawnTimer_timeout()

func _stop_chaos():
    $ChaosMusicPlayer.stop()
    $FadeIn.interpolate_property($MusicPlayer, "volume_db", music_min_db,
    music_max_db, 1.5, Tween.TRANS_LINEAR, Tween.EASE_OUT)
    $FadeIn.start()
    $MusicPlayer.play()
    var enemies = get_tree().get_nodes_in_group("enemies")
    for enemy in enemies:
        enemy.stop_chaos()
    chaos_start_timer.start()
    Globals.chaos_active = false

func kill_player():
    var player = Globals.get_player()
    player.get_parent().remove_child(player)
    $RespawnTimer.start()

func respawn_player():
    var player = Globals.get_player()
    get_tree().get_root().add_child(player)
    player.global_transform.origin = spawn_pos.global_transform.origin
    print("reviving!")
    player.revive()

func update_pods(pod_templates):
    var kubelet = get_tree().get_nodes_in_group("kubelet")[0]
    var current_pods = get_tree().get_nodes_in_group("pods")
    var current_pod_templates = kubelet.pod_queue
    for p in current_pods:
        current_pod_templates += [p.template]
    var matching_templates = []
    var matching_pods = []
    for t in pod_templates:
        for pt in current_pod_templates:
            if t.name == pt.name:
                matching_templates.push_back(t)
                matching_pods.push_back(pt)
                continue
    for t in pod_templates:
        if !exists_in(t, matching_templates):
            kubelet.queue_pod(t)
    for p in current_pods:
        if !exists_in(p.template, matching_pods) and !p.exploding:
            p.explode()              
    
func exists_in(element, list):
    for i in list:
        if element == i:
            return true
        if "name" in element and element.name == i.name:
            return true
    return false

func _on_pod_died(pod):
    if KubernetesServer.connected:
        $KubernetesStateHandler.delete_pod(pod)

func _on_UpdateState_timeout():
    if !KubernetesServer.connected and len(get_tree().get_nodes_in_group("pods")) < max_pod_amount:
        queue_dummy_pods()
    else:
        $KubernetesStateHandler.update_state()
