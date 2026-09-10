extends Control

@onready var digits_container: HBoxContainer = $Scoreboard/DigitsContainer
@onready var audio_btn: TextureButton = $AudioBtn

var digit_textures: Array[Texture2D] = [
	preload("res://assets/sprites/numbers/digit_0.png"),
	preload("res://assets/sprites/numbers/digit_1.png"),
	preload("res://assets/sprites/numbers/digit_2.png"),
	preload("res://assets/sprites/numbers/digit_3.png"),
	preload("res://assets/sprites/numbers/digit_4.png"),
	preload("res://assets/sprites/numbers/digit_5.png"),
	preload("res://assets/sprites/numbers/digit_6.png"),
	preload("res://assets/sprites/numbers/digit_7.png"),
	preload("res://assets/sprites/numbers/digit_8.png"),
	preload("res://assets/sprites/numbers/digit_9.png"),
]

var tex_sound_on: Texture2D = preload("res://assets/sprites/btn_sound_on.png")
var tex_sound_on_lit: Texture2D = preload("res://assets/sprites/btn_sound_on_lit.png")
var tex_sound_off: Texture2D = preload("res://assets/sprites/btn_sound_off.png")
var tex_sound_off_lit: Texture2D = preload("res://assets/sprites/btn_sound_off_lit.png")

func _ready() -> void:
	GameState.load_game()
	_update_high_score_display()
	_update_audio_display()

func _update_high_score_display() -> void:
	if not digits_container:
		return
	for child in digits_container.get_children():
		child.queue_free()
		
	var score_str = str(GameState.high_score)
	var num_digits = score_str.length()
	if num_digits == 0:
		return
		
	var max_width: float = 35.0 # Available wood width after colon before right vines
	var base_h: float = 6.8     # Matches letter height in 'Best Score:'
	var aspect: float = 200.0 / 268.0 # Average aspect ratio of digit sprites
	var base_w: float = base_h * aspect
	var base_sep: float = 1.0
	
	# Compute required width at standard scale
	var needed_width: float = num_digits * base_w + (num_digits - 1) * base_sep
	var scale: float = 1.0
	if needed_width > max_width:
		scale = max_width / needed_width
		
	var digit_h: float = max(3.5, base_h * scale)
	var digit_w: float = digit_h * aspect
	var cur_sep: int = int(round(base_sep * scale)) if scale > 0.85 else 0
	
	# Vertically center with the 'Best Score:' text (center_y = 15.56 in 39px scoreboard)
	var center_y: float = 15.56
	var top_y: float = center_y - (digit_h / 2.0)
	
	digits_container.position.x = 64.0
	digits_container.position.y = top_y
	digits_container.size.x = max_width
	digits_container.size.y = digit_h
	digits_container.add_theme_constant_override("separation", cur_sep)
	
	for ch in score_str:
		var d = ch.to_int()
		if d >= 0 and d <= 9:
			var tr = TextureRect.new()
			tr.texture = digit_textures[d]
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.custom_minimum_size = Vector2(digit_w, digit_h)
			digits_container.add_child(tr)

func _on_play_pressed() -> void:
	SoundFX.play_hop()
	get_tree().change_scene_to_file("res://scenes/gameplay.tscn")

func _on_audio_toggled() -> void:
	GameState.sound_enabled = not GameState.sound_enabled
	GameState.save_game()
	SoundFX.update_music_state()
	_update_audio_display()
	if GameState.sound_enabled:
		SoundFX.play_hop()

func _update_audio_display() -> void:
	if GameState.sound_enabled:
		audio_btn.texture_normal = tex_sound_on
		audio_btn.texture_pressed = tex_sound_on_lit
		audio_btn.texture_hover = tex_sound_on_lit
	else:
		audio_btn.texture_normal = tex_sound_off
		audio_btn.texture_pressed = tex_sound_off_lit
		audio_btn.texture_hover = tex_sound_off_lit

func _on_coffee_pressed() -> void:
	SoundFX.play_hop()
	OS.shell_open("https://buymeacoffee.com/cawfie")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE):
		_on_play_pressed()
