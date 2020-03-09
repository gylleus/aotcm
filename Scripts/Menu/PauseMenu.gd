extends Panel

export var main_menu_scene : String

func _back_to_menu():
    unpause()
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    Globals.clean_scene()
    get_tree().change_scene(main_menu_scene)

func _process(delta):
    if Input.is_action_just_pressed("ui_cancel"):
        if Globals.paused:
            unpause()
        else:
            pause()        

func pause():
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    get_tree().paused = true
    Engine.time_scale = 0.0
    Globals.paused = true
    visible = true
    
func unpause():
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    get_tree().paused = false
    Engine.time_scale = 1.0
    Globals.paused = false
    visible = false
