extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _process(delta):
    if Globals.invasion:
        $PodsLeftTitle.text = "PODS LOST:"
        $PodsLeft.text = String(floor(Globals.pods_lost))
    else:
        $PodsLeftTitle.text = "PODS LEFT:"
        $PodsLeft.text = String(floor(Globals.lose_when_pods_killed - Globals.pods_lost))


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass
