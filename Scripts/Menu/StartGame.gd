extends Control

var loading_screen : String = "res://Scenes/UI/LoadingScreen.tscn"

func _on_StartGame_pressed():
    visible = true

func start_game():
    get_tree().change_scene(loading_screen)

func _on_ExitGame_pressed():
    get_tree().quit()

func _on_InvasionButton_pressed():
    Globals.survival = false
    start_game()

func _on_SurvivalButton_pressed():
    Globals.survival = true
    Globals.pods_lost = 0
    Globals.monkeys_killed = 0
    start_game()

func _on_Back_pressed():
    visible = false
