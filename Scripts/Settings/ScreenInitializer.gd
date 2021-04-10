extends Node

func _ready():
	var screen_size = OS.get_screen_size()
	OS.set_window_size(screen_size)
