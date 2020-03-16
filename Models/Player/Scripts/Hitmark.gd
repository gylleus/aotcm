extends TextureRect

export var lifetime : float = 1.0

const max_alpha : float = 1.0
var alpha : float = 0

func _process(delta):
    if alpha > 0:
        print(alpha)
        alpha -= max_alpha * delta / lifetime
        self_modulate = Color(4,4,4,alpha)

func show():
    alpha = max_alpha
    self_modulate = Color(4,4,4,alpha)
