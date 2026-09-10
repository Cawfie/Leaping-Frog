extends AnimatableBody2D

enum Type { NORMAL, BREAKING, SPRING, MOVING }

@export var type: Type = Type.NORMAL

@onready var sprite: Sprite2D = $Sprite2D
@onready var mushroom_sprite: Sprite2D = $MushroomSprite
@onready var plat_collision: CollisionShape2D = $PlatCollision
@onready var shroom_shape: CollisionShape2D = $ShroomArea/ShroomShape
@onready var spike_trap: Area2D = $SpikeTrap
@onready var spike_shape: CollisionShape2D = $SpikeTrap/SpikeShape

var is_broken: bool = false
var break_timer: float = 0.0
var is_breaking_active: bool = false
var has_bounced: bool = false
var has_spike_trap: bool = false
var spike_trap_offset: float = 0.0

var move_speed: float = 38.0
var move_dir: float = 1.0
const MIN_X: float = 28.0
const MAX_X: float = 152.0

var tex_normal: Texture2D = preload("res://assets/sprites/platform_normal.png")
var tex_breaking: Texture2D = preload("res://assets/sprites/platform_breaking_strip5.png")

func _ready() -> void:
	plat_collision.one_way_collision = true
	move_dir = 1.0 if randf() > 0.5 else -1.0
	move_speed = randf_range(32.0, 48.0)
	_setup_visuals()
	if has_spike_trap and spike_trap:
		spike_trap.visible = true
		spike_trap.position = Vector2(spike_trap_offset, -7.0)
		spike_shape.set_deferred("disabled", false)

func _setup_visuals() -> void:
	match type:
		Type.NORMAL, Type.MOVING:
			sprite.visible = true
			sprite.texture = tex_normal
			sprite.hframes = 1
			sprite.frame = 0
			mushroom_sprite.visible = false
			plat_collision.disabled = false
			shroom_shape.disabled = true
		Type.BREAKING:
			sprite.visible = true
			sprite.texture = tex_breaking
			sprite.hframes = 5
			sprite.frame = 0
			mushroom_sprite.visible = false
			plat_collision.disabled = false
			shroom_shape.disabled = true
		Type.SPRING:
			# Standalone small mushroom: risky side target, no log
			sprite.visible = false
			mushroom_sprite.visible = true
			mushroom_sprite.position = Vector2(0, -9)
			mushroom_sprite.frame = 0
			plat_collision.disabled = true
			shroom_shape.disabled = false

func _physics_process(delta: float) -> void:
	if type == Type.MOVING and not is_broken:
		position.x += move_speed * move_dir * delta
		if position.x >= MAX_X:
			position.x = MAX_X
			move_dir = -1.0
		elif position.x <= MIN_X:
			position.x = MIN_X
			move_dir = 1.0

func _process(delta: float) -> void:
	if is_breaking_active and not is_broken:
		break_timer -= delta
		var progress = 1.0 - (break_timer / 0.45)
		sprite.frame = int(clamp(progress * 5.0, 0, 4))
		sprite.position.x = randf_range(-1.0, 1.0)
		
		if break_timer <= 0:
			is_broken = true
			plat_collision.set_deferred("disabled", true)
			SoundFX.play_break()
			
			var tween = create_tween()
			tween.tween_property(self, "modulate:a", 0.0, 0.2)
			tween.tween_callback(queue_free)

# Area2D signal: frog touches mushroom from any direction
func _on_shroom_body_entered(body: Node2D) -> void:
	if has_bounced:
		return
	if body.has_method("super_bounce"):
		has_bounced = true
		body.super_bounce()
		_play_mushroom_animation()
		var timer = get_tree().create_timer(0.5)
		timer.timeout.connect(func(): has_bounced = false)

func _play_mushroom_animation() -> void:
	mushroom_sprite.frame = 1
	var tween = create_tween()
	tween.tween_interval(0.06)
	tween.tween_callback(func(): mushroom_sprite.frame = 2)
	tween.tween_interval(0.14)
	tween.tween_callback(func(): mushroom_sprite.frame = 3)
	tween.tween_interval(0.1)
	tween.tween_callback(func(): mushroom_sprite.frame = 0)

func on_player_landed(player: CharacterBody2D) -> void:
	match type:
		Type.BREAKING:
			player.bounce()
			if not is_breaking_active:
				is_breaking_active = true
				break_timer = 0.45
				SoundFX.play_break()
		_:
			player.bounce()

func setup_spike_trap(offset_x: float) -> void:
	if type == Type.BREAKING or type == Type.SPRING:
		return
	has_spike_trap = true
	spike_trap_offset = offset_x
	if is_inside_tree() and spike_trap:
		spike_trap.visible = true
		spike_trap.position = Vector2(offset_x, -7.0)
		spike_shape.set_deferred("disabled", false)

func _on_spike_trap_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage()