extends CharacterBody2D

signal died()
signal jumped()

const BASE_GRAVITY: float = 680.0
const BASE_MOVE_SPEED: float = 140.0
const BASE_HOP_VELOCITY: float = -360.0
const BASE_SPRING_VELOCITY: float = -650.0

var current_gravity: float = 680.0
var current_move_speed: float = 140.0
var current_hop_velocity: float = -360.0
var current_spring_velocity: float = -650.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var is_dead: bool = false
var is_invulnerable: bool = false
var invuln_timer: float = 0.0
var hurt_timer: float = 0.0
var anim_timer: float = 0.0

# Death tumble animation state
var death_velocity: Vector2 = Vector2.ZERO
var death_rot_speed: float = 0.0

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	if is_dead:
		death_velocity.y += 850.0 * delta # Gravity for death fall
		position += death_velocity * delta
		rotation += death_rot_speed * delta
		anim_timer += delta
		sprite.frame = 12 if int(anim_timer * 10.0) % 2 == 0 else 13
		return
		
	# Game speed scales gently as you climb higher, capped at max 1.40x
	var speed_factor = clamp(1.0 + (GameState.current_altitude / 100.0) * 0.15, 1.0, 1.40)
	current_move_speed = BASE_MOVE_SPEED * speed_factor
	current_gravity = BASE_GRAVITY * (speed_factor ** 1.15)
	current_hop_velocity = BASE_HOP_VELOCITY * (speed_factor ** 0.55)
	current_spring_velocity = BASE_SPRING_VELOCITY * (speed_factor ** 0.55)
	
	# Apply Gravity
	velocity.y += current_gravity * delta
	
	# Horizontal Movement: Keyboard (A/D/Arrows) + Android Accelerometer Tilt + Mobile Touch
	var move_input = Input.get_axis("move_left", "move_right")
	
	# Android Controls: Check selected mode (TILT vs TOUCH)
	if GameState.android_control_mode == 0:
		# TILT MODE: Accelerometer tilt with sensitivity
		var accel = Input.get_accelerometer()
		if abs(accel.x) > 0.30:
			var divisor = GameState.get_tilt_divisor()
			move_input = clamp(-accel.x / divisor, -1.0, 1.0)
	else:
		# TOUCH MODE: Vertical split screen (left half = left, right half = right)
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var touch_x = get_viewport().get_mouse_position().x
			var screen_mid = get_viewport_rect().size.x * 0.5
			if touch_x < screen_mid:
				move_input = -1.0
			else:
				move_input = 1.0
	
	if move_input != 0:
		velocity.x = move_input * current_move_speed
		sprite.flip_h = (move_input < 0)
	else:
		velocity.x = move_toward(velocity.x, 0, current_move_speed * 8.0 * delta)
		
	# Screen Wrap (Doodle Jump style)
	if position.x < -8:
		position.x = 188
	elif position.x > 188:
		position.x = -8
		
	# Update Hurt & Invulnerability
	if hurt_timer > 0:
		hurt_timer -= delta
	if is_invulnerable:
		invuln_timer -= delta
		sprite.modulate.a = 0.4 if fmod(invuln_timer, 0.2) > 0.1 else 1.0
		if invuln_timer <= 0:
			is_invulnerable = false
			sprite.modulate.a = 1.0
			
	# Move the character
	move_and_slide()
	
	# Platform landing bounce (reliable apex/downward landing check)
	if velocity.y >= -30.0:
		for i in get_slide_collision_count():
			var col = get_slide_collision(i)
			if col.get_normal().y < -0.5:
				var collider = col.get_collider()
				if collider and collider.has_method("on_player_landed"):
					collider.on_player_landed(self)
				else:
					bounce()
				break
		
	_update_animation(delta)

func bounce(vel: float = 0.0) -> void:
	velocity.y = vel if vel != 0.0 else current_hop_velocity
	SoundFX.play_hop()
	jumped.emit()

func super_bounce() -> void:
	bounce(current_spring_velocity)

func on_bug_eaten() -> void:
	pass

func take_damage() -> void:
	if is_invulnerable or is_dead:
		return
		
	var is_game_over = GameState.damage()
	SoundFX.play_hurt()
	
	if is_game_over:
		die()
	else:
		is_invulnerable = true
		invuln_timer = 1.6
		hurt_timer = 0.45
		velocity.y = current_hop_velocity * 0.75

func die() -> void:
	if is_dead:
		return
	is_dead = true
	collision_shape.set_deferred("disabled", true)
	sprite.frame = 12 # Red hurt frog frame
	z_index = 25 # Render in front of platforms and bugs while tumbling
	
	# Initial upward death hop and spinning tumble
	var dir = -1.0 if randf() < 0.5 else 1.0
	death_velocity = Vector2(randf_range(30.0, 60.0) * dir, -260.0)
	death_rot_speed = randf_range(8.0, 11.0) * dir
	
	SoundFX.play_game_over()
	died.emit()

func _update_animation(delta: float) -> void:
	anim_timer += delta
		
	if is_dead:
		sprite.frame = 12
		return
		
	if hurt_timer > 0.0:
		# Play 2-frame hurt animation (frames 12 and 13)
		sprite.frame = 12 if int(hurt_timer * 10.0) % 2 == 0 else 13
		return
		
	if not is_on_floor():
		if velocity.y < -180:
			sprite.frame = 5
		elif velocity.y < -40:
			sprite.frame = 6
		elif velocity.y < 60:
			sprite.frame = 7
		elif velocity.y < 180:
			sprite.frame = 8
		else:
			sprite.frame = 9
	else:
		var f = int(anim_timer * 4.0) % 4
		sprite.frame = f
