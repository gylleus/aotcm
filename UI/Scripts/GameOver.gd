extends Node

export var main_menu_scene : String


func _back_to_menu():
	get_tree().change_scene(main_menu_scene)
