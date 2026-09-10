extends Node

# Calm, organic 16-bit sound effects
var sfx_hop: AudioStream = preload("res://assets/sounds/hop.wav")
var sfx_tongue: AudioStream = preload("res://assets/sounds/tongue.wav")
var sfx_eat: AudioStream = preload("res://assets/sounds/eat.wav")
var sfx_spring: AudioStream = preload("res://assets/sounds/spring.wav")
var sfx_hurt: AudioStream = preload("res://assets/sounds/hurt.wav")
var sfx_break: AudioStream = preload("res://assets/sounds/break.wav")
var sfx_powerup: AudioStream = preload("res://assets/sounds/powerup.wav")
var sfx_game_over: AudioStream = preload("res://assets/sounds/game_over.wav")
var sfx_shoot: AudioStream = preload("res://assets/sounds/shoot.wav")
var bgm_stream: AudioStream = preload("res://assets/sounds/High_Above_the_Reeds.mp3")

# Master volume attenuation - soft, relaxing background levels
const MASTER_VOLUME_DB: float = -8.0
const MUSIC_TARGET_VOLUME_DB: float = -12.0

var music_player: AudioStreamPlayer = null
var music_tween: Tween = null

func _ready() -> void:
	if bgm_stream is AudioStreamMP3:
		bgm_stream.loop = true
	music_player = AudioStreamPlayer.new()
	music_player.stream = bgm_stream
	music_player.volume_db = -60.0
	add_child(music_player)

func play_music(fade_in_duration: float = 1.2) -> void:
	if not GameState.sound_enabled or not music_player:
		return
	if music_tween and music_tween.is_valid():
		music_tween.kill()
		
	if not music_player.playing:
		music_player.volume_db = -60.0
		music_player.play()
		
	music_tween = create_tween()
	music_tween.tween_property(music_player, "volume_db", MUSIC_TARGET_VOLUME_DB, fade_in_duration)

func fade_out_music(fade_out_duration: float = 1.0) -> void:
	if not music_player or not music_player.playing:
		return
	if music_tween and music_tween.is_valid():
		music_tween.kill()
		
	music_tween = create_tween()
	music_tween.tween_property(music_player, "volume_db", -60.0, fade_out_duration)
	music_tween.tween_callback(func():
		if music_player and music_player.volume_db <= -58.0:
			music_player.stop()
	)

func stop_music() -> void:
	if music_tween and music_tween.is_valid():
		music_tween.kill()
	if music_player:
		music_player.stop()
		music_player.volume_db = -60.0

func update_music_state() -> void:
	if not music_player:
		return
	if not GameState.sound_enabled:
		stop_music()
	else:
		var cur = get_tree().current_scene
		if cur and cur.name == "Gameplay":
			play_music(1.2)

func play_hop() -> void:
	if not GameState.sound_enabled: return
	# Hop is triggered frequently; keep it soft and subtle
	_play_stream(sfx_hop, MASTER_VOLUME_DB - 3.0)

func play_tongue() -> void:
	if not GameState.sound_enabled: return
	_play_stream(sfx_tongue, MASTER_VOLUME_DB - 4.0)

func play_eat() -> void:
	if not GameState.sound_enabled: return
	_play_stream(sfx_eat, MASTER_VOLUME_DB - 1.0)

func play_spring() -> void:
	if not GameState.sound_enabled: return
	_play_stream(sfx_spring, MASTER_VOLUME_DB)

func play_hurt() -> void:
	if not GameState.sound_enabled: return
	_play_stream(sfx_hurt, MASTER_VOLUME_DB)

func play_break() -> void:
	if not GameState.sound_enabled: return
	_play_stream(sfx_break, MASTER_VOLUME_DB - 2.0)

func play_powerup() -> void:
	if not GameState.sound_enabled: return
	_play_stream(sfx_powerup, MASTER_VOLUME_DB)

func play_game_over() -> void:
	if not GameState.sound_enabled: return
	_play_stream(sfx_game_over, MASTER_VOLUME_DB)

func play_shoot() -> void:
	if not GameState.sound_enabled: return
	_play_stream(sfx_shoot, MASTER_VOLUME_DB - 2.0)

func _play_stream(stream: AudioStream, vol_db: float = MASTER_VOLUME_DB) -> void:
	if not stream: return
	var p = AudioStreamPlayer.new()
	add_child(p)
	p.stream = stream
	p.volume_db = vol_db
	p.finished.connect(p.queue_free)
	p.play()
