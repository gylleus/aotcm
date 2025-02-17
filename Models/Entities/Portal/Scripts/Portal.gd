extends Spatial

export var enemy_spawn_interval : float = 0.5
export var fade_time : float = 1


var mat : Material
var start_alpha : float = 1
var spawn_effect = preload("res://Models/Particles/PortalSpawn.tscn")

var enemies = []
var enemy_spawn_timer : float = 0

func _ready():
	add_to_group("portals")
	mat = $Spatial/Portal.mesh.get("surface_1/material")
	mat = mat.duplicate()
	$Spatial/Portal.mesh.set("surface_1/material", mat)
	start_alpha = mat.get("shader_param/alpha")

func stop():
	enemies = []

func _process(delta):
	if enemies != null && len(enemies) > 0:
		enemy_spawn_timer += delta
		if enemy_spawn_timer > enemy_spawn_interval:
			spawn_next_enemy()
			enemy_spawn_timer = 0
	else:
		var new_alpha = $Spatial/Portal.mesh.get("surface_1/material").get("shader_param/alpha") - start_alpha * delta / fade_time
		$Spatial/Portal.mesh.get("surface_1/material").set("shader_param/alpha", new_alpha)
	if $Spatial/Portal.mesh.get("surface_1/material").get("shader_param/alpha") <= 0:
		queue_free()

func spawn_next_enemy():
	var spawn_pos = $Spatial/SpawnPosition.global_transform.origin
	var next_enemy = enemies.pop_front()
	if !Globals.is_max_enemies() and next_enemy != null:
		var new_enemy = next_enemy.scene.instance()
		var new_effect = spawn_effect.instance()
		get_tree().get_root().add_child(new_effect)
		get_tree().get_root().add_child(new_enemy)
		new_effect.global_transform.origin = spawn_pos
		new_enemy.global_transform.origin = spawn_pos
		if Globals.chaos_active:
			new_enemy.start_chaos()
