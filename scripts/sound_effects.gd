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
# Master volume attenuation - soft, relaxing background levels
const MASTER_VOLUME_DB: float = -8.0

func _ready() -> void:
	pass

func play_music(_fade_in_duration: float = 1.2) -> void:
	pass

func fade_out_music(_fade_out_duration: float = 1.0) -> void:
	pass

func stop_music() -> void:
	pass

func update_music_state() -> void:
	pass

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
