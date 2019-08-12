extends Camera
 
 
const ray_length = 1000
 
func _input(event):
    if event is InputEventMouseButton and event.pressed and event.button_index == 1:
        var from = project_ray_origin(event.position)
        var to = from + project_ray_normal(event.position) * ray_length
        var space_state = get_world().direct_space_state
        var result = space_state.intersect_ray(from, to, [], 1)
        if result:
            get_tree().call_group("units", "move_to", result.position)