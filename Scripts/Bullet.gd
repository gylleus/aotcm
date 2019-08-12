extends Spatial

var max_range
var travel_speed
var damage
var distance_travelled = 0

var has_hit = false

# Called when the node enters the scene tree for the first time.
func _ready():
    $Area.connect("body_entered", self, "on_hit")

func initialize_bullet(dmg, spd, max_rng):
        max_range = max_rng
        damage = dmg
        travel_speed = spd

func _physics_process(delta):
    global_translate(transform.basis.z.normalized() * travel_speed * delta)
    distance_travelled += travel_speed * delta
    
    if distance_travelled >= max_range:
        queue_free()

func on_hit(body):
    if !has_hit:
        if body.has_method("bullet_hit"):
            body.bullet_hit(damage)
    has_hit = true
   #queue_free()
