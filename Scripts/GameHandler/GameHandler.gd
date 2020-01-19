extends Spatial

export var spawn_position : NodePath

signal spawn_wave

#export var chaos_spawn_multiplier : float = 1

export var chaos_music = "res://Audio/DoomChaos.wav"

onready var chaos_start_timer = get_node("ChaosStartTimer")
onready var chaos_stop_timer = get_node("ChaosStopTimer")
onready var spawn_timer = get_node("ChaosStopTimer")
onready var music_player = get_node("MusicPlayer")
onready var spawn_pos = get_node(spawn_position)

const KubernetesStateHandler = preload("KubernetesStateHandler.gd")

var k8s_handler
var current_difficulty = 1
var chaos_active = false


func _ready():
    chaos_start_timer.start()
    Globals.connect("kill_player", self, "kill_player")

func _process(delta):
    k8s_handler = KubernetesStateHandler.new("https://localhost", 16443)
    #k8s_handler.get_pod_list()

func _on_EnemySpawnTimer_timeout():
    print("time to spawn enemies!")
    emit_signal("spawn_wave", current_difficulty)
    pass # Replace with function body.

func _start_chaos():
    print("Start chaos!")
    music_player.stream = load(chaos_music)
    music_player.play()
    var enemies = get_tree().get_nodes_in_group("enemies")
    for enemy in enemies:
        enemy.start_chaos()
    chaos_stop_timer.start()
    Globals.chaos_active = true

func _stop_chaos():
    print("Stop chaos!")
    music_player.stop()
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