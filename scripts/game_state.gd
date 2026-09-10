extends Node

signal score_changed(new_score: int)
signal altitude_changed(meters: int)
signal hearts_changed(current: int)
signal ads_status_changed(has_removed: bool)

var high_score: int = 0
var current_score: int = 0
var current_altitude: int = 0
var max_altitude: int = 0
var bugs_eaten: int = 0
var hearts: int = 3

# Monetization: Ads Removed status
var ads_removed: bool = false

# Sound settings
var sound_enabled: bool = true

# Controls settings
# Android Control Mode: 0 = "TILT" (Accelerometer), 1 = "TOUCH" (Split Screen Tap/Hold)
var android_control_mode: int = 1

# Tilt sensitivity: 1 = Low, 2 = Medium (Default), 3 = High
var tilt_sensitivity: int = 2

# PC Control scheme: 0 = "A / D + Arrows", 1 = "A / D Only", 2 = "Arrows Only"
var pc_control_scheme: int = 0

const SAVE_PATH = "user://froggy_save.json"

func _ready() -> void:
	# Enable native high-refresh display adaptation (30, 60, 90, 120, 144 Hz)
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	load_game()
	apply_pc_controls()

func get_tilt_divisor() -> float:
	match tilt_sensitivity:
		1: return 4.5 # Low sensitivity (requires more tilt)
		3: return 2.2 # High sensitivity (very responsive tilt)
		_: return 3.2 # Medium sensitivity (default)

func apply_pc_controls() -> void:
	# Clear existing keyboard events for move_left / move_right
	InputMap.action_erase_events("move_left")
	InputMap.action_erase_events("move_right")
	
	# Keycodes: A = KEY_A, D = KEY_D, Left Arrow = KEY_LEFT, Right Arrow = KEY_RIGHT
	var allow_ad = (pc_control_scheme == 0 or pc_control_scheme == 1)
	var allow_arrows = (pc_control_scheme == 0 or pc_control_scheme == 2)
	
	if allow_ad:
		var ev_a = InputEventKey.new()
		ev_a.physical_keycode = KEY_A
		InputMap.action_add_event("move_left", ev_a)
		
		var ev_d = InputEventKey.new()
		ev_d.physical_keycode = KEY_D
		InputMap.action_add_event("move_right", ev_d)
		
	if allow_arrows:
		var ev_left = InputEventKey.new()
		ev_left.physical_keycode = KEY_LEFT
		InputMap.action_add_event("move_left", ev_left)
		
		var ev_right = InputEventKey.new()
		ev_right.physical_keycode = KEY_RIGHT
		InputMap.action_add_event("move_right", ev_right)

func reset_run() -> void:
	current_score = 0
	current_altitude = 0
	max_altitude = 0
	bugs_eaten = 0
	hearts = 3
	score_changed.emit(current_score)
	altitude_changed.emit(current_altitude)
	hearts_changed.emit(hearts)

func add_score(pts: int) -> void:
	# Bug bonus points (added on top of altitude score)
	current_score += pts
	bugs_eaten += 1
	score_changed.emit(current_score)
	
	if current_score > high_score:
		high_score = current_score
		save_game()

func update_altitude(y_meters: int) -> void:
	if y_meters > max_altitude:
		# Score scales with altitude: higher = more points per meter
		var meters_gained = y_meters - max_altitude
		var multiplier = 1 + int(y_meters / 50)
		current_score += meters_gained * multiplier
		max_altitude = y_meters
		current_altitude = y_meters
		altitude_changed.emit(current_altitude)
		score_changed.emit(current_score)
		
		if current_score > high_score:
			high_score = current_score
			save_game()

func damage() -> bool:
	# Lose 1 heart
	hearts -= 1
	hearts_changed.emit(hearts)
	return hearts <= 0

func heal() -> void:
	hearts = min(hearts + 1, 3)
	hearts_changed.emit(hearts)

func unlock_remove_ads() -> void:
	ads_removed = true
	ads_status_changed.emit(true)
	save_game()

func save_game() -> void:
	var data = {
		"high_score": high_score,
		"sound_enabled": sound_enabled,
		"android_control_mode": android_control_mode,
		"tilt_sensitivity": tilt_sensitivity,
		"pc_control_scheme": pc_control_scheme,
		"ads_removed": ads_removed
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_game() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var test_json_conv = JSON.new()
			if test_json_conv.parse(file.get_as_text()) == OK:
				var data = test_json_conv.get_data()
				high_score = data.get("high_score", 0)
				sound_enabled = data.get("sound_enabled", true)
				android_control_mode = int(data.get("android_control_mode", 1))
				tilt_sensitivity = int(data.get("tilt_sensitivity", 2))
				pc_control_scheme = int(data.get("pc_control_scheme", 0))
				ads_removed = false # In-app billing disabled, ads remain enabled