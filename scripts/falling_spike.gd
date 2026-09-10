extends Area2D

@export var fall_speed: float = 190.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _physics_process(delta: float) -> void:
	position.y += fall_speed * delta
	
	# Cleanup if fallen below camera view
	var cam = get_viewport().get_camera_2d()
	if cam:
		var bottom_y = cam.position.y + (get_viewport_rect().size.y * 0.5) + 60.0
		if position.y > bottom_y:
			queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage()
		queue_free()