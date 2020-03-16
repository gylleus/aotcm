extends Node

export var game_scene : String

onready var load_thread = Thread.new()

func _ready():
    load_game()

func load_game():
    var loader = ResourceLoader.load_interactive(game_scene)
    
    while loader != null:
        var err = loader.poll()
        var current_stage = float(loader.get_stage())+1
        var total_stage = float(loader.get_stage_count())

        var attack_timer = get_tree().create_timer(0.01)
        yield(attack_timer, "timeout")
        
        update_progress( float(current_stage / total_stage)) 
        if err == ERR_FILE_EOF:
            update_progress( float(current_stage / total_stage))
            var resource = loader.get_resource()
            get_tree().change_scene_to(resource)
            return
        if err == OK:
            update_progress( float(current_stage / total_stage))        
        else:
            loader == null
        
func update_progress(progress):
    $ProgressBar.update_progress(progress)
