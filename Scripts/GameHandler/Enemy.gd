extends Spatial

export var difficulty_points : int

export var scene_path : String
var scene

func _ready():
	scene = load(scene_path)
	print()
