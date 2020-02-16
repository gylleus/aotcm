extends AudioStreamPlayer3D

var audio_node = null
var should_loop = false
var globals = null

func _ready():
    self.connect("finished", self, "sound_finished")

    globals = get_node("/root/Globals")


func play_sound(audio_stream, position=null):
    self.stream = audio_stream

    self.play(0.0)
