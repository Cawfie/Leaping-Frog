extends Area2D

enum Type { HOUSEFLY, BUTTERFLY, BEE, HEART_MOTH }

@export var type: Type = Type.HOUSEFLY

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var anim_timer: float = 0.0
var flight_timer: float = 0.0
var base_pos: Vector2 = Vector2.ZERO
var is_eaten: bool = false

var points: int = 10

var tex_housefly: Texture2D = preload("res://assets/sprites/housefly_strip5.png")
var tex_butterfly: Texture2D = preload("res://assets/sprites/butterfly_strip5.png")
var tex_bee: Texture2D = preload("res://assets/sprites/bee_strip5.png")
var tex_heart_moth: Texture2D = preload("res://assets/sprites/heart_moth_strip5.png")

func _ready() -> void:
	base_pos = position
	flight_timer = randf_range(0.0, 10.0)
	_setup_bug()

func _setup_bug() -> void:
	sprite.hframes = 5
	match type:
		Type.HOUSEFLY:
			sprite.texture = tex_housefly
			points = 10
		Type.BUTTERFLY:
			sprite.texture = tex_butterfly
			points = 50
		Type.BEE:
			sprite.texture = tex_bee
			points = 0
		Type.HEART_MOTH:
			sprite.texture = tex_heart_moth
			points = 25

func _process(delta: float) -> void:
	if is_eaten:
		return
		
	anim_timer += delta
	flight_timer += delta
	
	# 5-Frame wing flutter / animation loop
	var fps = 12.0 if type == Type.BEE or type == Type.HOUSEFLY else 8.0
	sprite.frame = int(anim_timer * fps) % 5
		
	# Flight path (slightly wider left/right flight)
	match type:
		Type.HOUSEFLY:
			position.x = base_pos.x + sin(flight_timer * 4.0) * 14.0
			position.y = base_pos.y + cos(flight_timer * 3.0) * 5.0
			sprite.flip_h = (cos(flight_timer * 4.0) < 0)
		Type.BUTTERFLY:
			position.x = base_pos.x + sin(flight_timer * 2.0) * 24.0
			position.y = base_pos.y + sin(flight_timer * 4.0) * 8.0
			sprite.flip_h = (cos(flight_timer * 2.0) < 0)
		Type.BEE:
			# Patrolling back and forth
			position.x = base_pos.x + sin(flight_timer * 3.5) * 28.0
			position.y = base_pos.y + sin(flight_timer * 2.0) * 4.0
			sprite.flip_h = (cos(flight_timer * 3.5) < 0)
		Type.HEART_MOTH:
			position.x = base_pos.x + sin(flight_timer * 2.5) * 18.0
			position.y = base_pos.y + cos(flight_timer * 3.0) * 6.0
			sprite.flip_h = (cos(flight_timer * 2.5) < 0)

func on_eaten(player: CharacterBody2D) -> void:
	if is_eaten:
		return
	is_eaten = true
	
	match type:
		Type.BEE:
			player.take_damage()
			queue_free()
		Type.HEART_MOTH:
			if player.has_method("on_bug_eaten"):
				player.on_bug_eaten()
			GameState.heal()
			GameState.add_score(points)
			SoundFX.play_powerup()
			queue_free()
		_:
			# Housefly or Butterfly
			GameState.add_score(points)
			SoundFX.play_eat()
			
			# Quick squash gulp animation into mouth
			var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tween.tween_property(self, "global_position", player.global_position, 0.08)
			tween.parallel().tween_property(self, "scale", Vector2.ZERO, 0.08)
			tween.tween_callback(queue_free)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		if type == Type.BEE:
			body.take_damage()
		else:
			on_eaten(body)
