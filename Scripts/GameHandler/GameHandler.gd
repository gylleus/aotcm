extends Spatial

signal spawn_wave

#export var chaos_spawn_multiplier : float = 1

export var chaos_music = "res://Audio/DoomChaos.wav"
export var game_over_scene : String
export var score_per_second = 75
export var spawn_interval = 15
export var chaos_spawn_multiplier = 2.5
export var chaos_spawn_divider = 2
export var start_difficulty : float = 1
export var difficulty_increment_per_minute : float = 1

onready var chaos_start_timer = get_node("ChaosStartTimer")
onready var chaos_stop_timer = get_node("ChaosStopTimer")
onready var spawn_timer = get_node("ChaosStopTimer")
onready var music_player = get_node("MusicPlayer")
onready var spawn_pos = $PlayerSpawn

var k8s_handler
onready var current_difficulty : float = start_difficulty
var chaos_active = false


func _ready():
    chaos_start_timer.start()
    Globals.connect("kill_player", self, "kill_player")

func _process(delta):
#    k8s_handler = KubernetesStateHandler.new("https://localhost", 16443)
    #k8s_handler.get_pod_list()
    Globals.total_score += delta * score_per_second
    current_difficulty += difficulty_increment_per_minute * delta / 60
    for enemy in get_tree().get_nodes_in_group("enemies"):
        enemy.movement_speed = enemy.base_movement_speed + enemy.base_movement_speed * current_difficulty / 8.0
    if Globals.pods_lost >= Globals.lose_when_pods_killed and !Globals.invasion:
        get_tree().change_scene(game_over_scene)
        
func get_next_spawn_timer():
    var time = spawn_interval / current_difficulty
    if Globals.chaos_active:
        time /= chaos_spawn_multiplier
    return time

func _on_EnemySpawnTimer_timeout():
    $EnemySpawnTimer.wait_time = get_next_spawn_timer()
    var wave_difficulty = current_difficulty
    if Globals.chaos_active:
        wave_difficulty /= chaos_spawn_divider
    emit_signal("spawn_wave", wave_difficulty)

func _start_chaos():
    music_player.stream = load(chaos_music)
    music_player.play()
    var enemies = get_tree().get_nodes_in_group("enemies")
    for enemy in enemies:
        enemy.start_chaos()
    chaos_stop_timer.start()
    Globals.chaos_active = true

func _stop_chaos():
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
