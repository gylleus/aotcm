extends AudioStreamPlayer3D

var audio_node = null
var should_loop = false
var globals = null

func _ready():
    self.connect("finished", self, "sound_finished")

    globals = get_node("/root/Globals")


func play_sound(audio_stream, position=null):
    print(position)
    if audio_stream == null:
        print ("No audio stream passed; cannot play sound")
        globals.created_audio.remove(globals.created_audio.find(self))
        queue_free()
        return

    self.stream = audio_stream

    if position != null:
        global_transform.origin = position

    self.play(0.0)


func sound_finished():
    if should_loop:
        audio_node.play(0.0)
    else:
        globals.created_audio.remove(globals.created_audio.find(self))
        self.stop()
        queue_free()