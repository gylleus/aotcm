extends Node

var total_score : float = 0
var monkeys_killed = 0
var pods_lost = 0
var lose_when_pods_killed = 35
var invasion = false

var audio_clips = {
    "RifleShot": preload("res://Audio/RifleShot.wav"),
    "MonkeyAttack1": preload("res://Audio/MonkeyAttack1.wav"),
    "MonkeyAttack2": preload("res://Audio/MonkeyAttack2.wav"),
    "MonkeyAttack3": preload("res://Audio/MonkeyAttack3.wav"),
    "MonkeyAttack4": preload("res://Audio/MonkeyAttack4.wav")
}

const AUDIO_PLAYER_SCENE = preload("res://Scenes/AudioPlayer.tscn")
var created_audio = []

var chaos_active : bool = false
var player

signal kill_player

func play_sound(sound_name, sound_position=null):
    if audio_clips.has(sound_name):
        var new_audio = AUDIO_PLAYER_SCENE.instance()
#        new_audio.should_loop = loop_sound
        add_child(new_audio)
        created_audio.append(new_audio)
        new_audio.play_sound(audio_clips[sound_name], sound_position)
    else:
        print ("ERROR: cannot play sound that does not exist in audio_clips!")

func load_new_scene(new_scene_path):
    return get_tree().change_scene(new_scene_path)

func get_player():
    if player == null:
        player = find_player_node()
    return player
    
func find_player_node():
    var players = get_tree().get_nodes_in_group("player")
    if len(players) == 0:
        print("WARNING: No player object defined in groups 'player'")
    elif len(players) > 1:
        print("WARNING: More than one player object in scene")
    else:
        return players[0]
    return null

func kill_player():
    emit_signal("kill_player")
