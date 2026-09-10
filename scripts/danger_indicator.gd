extends Node2D

signal timer_finished(x_coord: float)

@onready var sprite: Sprite2D = $Sprite2D

var elapsed_time: float = 0.0
const DURATION_DARK: float = 1.0       # Frame 0: Dark
const DURATION_MEDIUM: float = 2.0     # Frame 1: Light dark
const TOTAL_DURATION: float = 3.0      # Frame 2: Bright glowing

func _ready() -> void:
	sprite.hframes = 3
	sprite.frame = 0
	# Subtle entrance scale punch
	scale = Vector2(0.7, 0.7)
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)

func _process(delta: float) -> void:
	elapsed_time += delta
	
	if elapsed_time < DURATION_DARK:
		# Frame 0: Dark
		sprite.frame = 0
	elif elapsed_time < DURATION_MEDIUM:
		# Frame 1: Light Dark
		sprite.frame = 1
	elif elapsed_time < TOTAL_DURATION:
		# Frame 2: Bright (flash / pulse warning)
		sprite.frame = 2
		# Fast urgent pulse before dropping
		var pulse = 1.0 + (sin(elapsed_time * 18.0) * 0.12)
		scale = Vector2(pulse, pulse)
	else:
		# Timer finished! Drop the spike!
		timer_finished.emit(global_position.x)
		queue_free()