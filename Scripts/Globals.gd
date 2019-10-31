extends Node

var mouse_sensitivity = 0.08
var joypad_sensitivity = 2

var audio_clips = {
    "RifleShot": preload("res://Audio/RifleShot.wav")
}

const AUDIO_PLAYER_SCENE = preload("res://Scenes/AudioPlayer.tscn")
var created_audio = []

func play_sound(sound_name, loop_sound=false, sound_position=null):
    if audio_clips.has(sound_name):
        var new_audio = AUDIO_PLAYER_SCENE.instance()
#        new_audio.should_loop = loop_sound
        add_child(new_audio)
        created_audio.append(new_audio)
        new_audio.play_sound(audio_clips[sound_name], sound_position)
    else:
        print ("ERROR: cannot play sound that does not exist in audio_clips!")

func load_new_scene(new_scene_path):
    get_tree().change_scene(new_scene_path)