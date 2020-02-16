extends Control

var loading_screen : String = "res://Scenes/UI/LoadingScreen.tscn"

func _on_StartGame_pressed():
    visible = true

func start_game():
    get_tree().change_scene(loading_screen)

func _on_ExitGame_pressed():
    get_tree().quit()

func _on_InvasionButton_pressed():
    Globals.invasion = true
    start_game()

func _on_SurvivalButton_pressed():
    Globals.invasion = false
    start_game()
