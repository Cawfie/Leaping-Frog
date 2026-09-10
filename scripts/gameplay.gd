extends Node2D

@onready var player: CharacterBody2D = $PlayerFrog
@onready var camera: Camera2D = $Camera2D
@onready var platforms_container: Node2D = $Platforms
@onready var bugs_container: Node2D = $Bugs
@onready var spikes_container: Node2D = $Spikes

# HUD Nodes
@onready var top_bar: Control = $HUD/TopBar
@onready var score_label: Label = $HUD/TopBar/ScoreLabel
@onready var alt_label: Label = $HUD/TopBar/AltLabel
@onready var heart1: TextureRect = $HUD/TopBar/Hearts/Heart1
@onready var heart2: TextureRect = $HUD/TopBar/Hearts/Heart2
@onready var heart3: TextureRect = $HUD/TopBar/Hearts/Heart3

# Game Over Overlay
@onready var game_over_panel: Control = $HUD/GameOverPanel
@onready var final_score_label: Label = $HUD/GameOverPanel/Box/Board/FinalScore
@onready var best_score_label: Label = $HUD/GameOverPanel/Box/Board/BestScore
@onready var bugs_eaten_label: Label = $HUD/GameOverPanel/Box/Board/BugsEaten
@onready var max_alt_label: Label = $HUD/GameOverPanel/Box/Board/MaxAlt

var platform_scene: PackedScene = preload("res://scenes/platform.tscn")
var bug_scene: PackedScene = preload("res://scenes/bug.tscn")
var indicator_scene: PackedScene = preload("res://scenes/danger_indicator.tscn")
var falling_spike_scene: PackedScene = preload("res://scenes/falling_spike.tscn")
var tex_heart_full: Texture2D = preload("res://assets/sprites/heart_full.png")
var tex_heart_empty: Texture2D = preload("res://assets/sprites/heart_empty.png")

# Configurable spawn rates (Reduced heart moth to 1, increased housefly/butterfly)
@export var weight_housefly: int = 55
@export var weight_butterfly: int = 35
@export var weight_bee: int = 9
@export var weight_heart_moth: int = 1

# Platform Spawn Rates (Spring reduced to rare 6%)
@export var weight_plat_normal: int = 70
@export var weight_plat_breaking: int = 24
@export var weight_plat_spring: int = 6

var highest_generated_y: float = 300.0
var target_camera_y: float = 160.0
var is_game_over: bool = false
var base_camera_speed: float = 13.0

# Falling Spike Hazard & Hazard Spacing Trackers
var next_danger_spike_timer: float = 8.0
var no_spike_until_y: float = 999999.0
var last_shroom_y: float = 999999.0
var platforms_since_last_spike: int = 99
var last_platform_type: int = 0
var next_bug_crowd_milestone: int = 500

func _ready() -> void:
	GameState.reset_run()
	SoundFX.play_music(1.5)
	top_bar.visible = true
	game_over_panel.visible = false
	
	GameState.score_changed.connect(_on_score_changed)
	GameState.altitude_changed.connect(_on_altitude_changed)
	GameState.hearts_changed.connect(_on_hearts_changed)
	player.died.connect(_on_player_died)
	
	_update_hearts_display(GameState.hearts)
	
	# Spawn initial safe platform under player
	var start_plat = platform_scene.instantiate()
	start_plat.position = Vector2(90, 290)
	start_plat.type = 0
	platforms_container.add_child(start_plat)
	
	highest_generated_y = 260.0
	_generate_up_to(-400.0)

func _process(delta: float) -> void:
	if is_game_over:
		return
		
	var player_lead_y = player.position.y - 20.0
	if player_lead_y < target_camera_y:
		target_camera_y = player_lead_y
		
	var current_alt = max(0.0, (160.0 - target_camera_y) / 10.0)
	# Rising Camera Pressure: Speed scales smoothly with altitude
	const MAX_CAMERA_SPEED: float = 46.0
	var speed = min(base_camera_speed + (current_alt * 0.18), MAX_CAMERA_SPEED)
	
	# Altitude-based minimum floor speed: prevents staying still indefinitely high up
	var floor_speed = clamp(8.0 + (current_alt * 0.08), 8.0, 22.0)
	
	# Rubber-band: slow camera when player falls behind, respecting floor speed
	var player_offset = player.position.y - target_camera_y
	if player_offset > 80.0:
		speed = max(speed * 0.45, floor_speed)
	elif player_offset > 40.0:
		speed = max(speed * 0.70, floor_speed)
	
	target_camera_y -= speed * delta
	camera.position.y = target_camera_y
	GameState.update_altitude(int(current_alt))
	
	# Falling Spike Hazard Spawner (Active above 35m)
	if current_alt >= 35.0:
		next_danger_spike_timer -= delta
		if next_danger_spike_timer <= 0.0:
			next_danger_spike_timer = randf_range(10.0, 15.0)
			_spawn_danger_wave(current_alt)
	
	if highest_generated_y > camera.position.y - 350.0:
		_generate_up_to(camera.position.y - 450.0)
		
	_cleanup_offscreen()
	
	var screen_bottom_offset = (get_viewport_rect().size.y * 0.5) + 35.0
	if player.position.y > camera.position.y + screen_bottom_offset and not player.is_dead:
		player.die()

func _spawn_danger_wave(current_alt: float) -> void:
	if is_game_over:
		return
		
	# Concurrent spike count:
	# 1 spike is rare (~72-82%)
	# 2 spikes is rarer (~18-20%)
	# 3 spikes is very rare (~8%, only at 60m+)
	var spike_count = 1
	var roll = randf()
	if current_alt >= 60.0:
		if roll < 0.72:
			spike_count = 1
		elif roll < 0.92:
			spike_count = 2
		else:
			spike_count = 3
	else:
		if roll < 0.82:
			spike_count = 1
		else:
			spike_count = 2
			
	var x_positions: Array[float] = []
	if spike_count == 1:
		var target_x = clamp(player.position.x + randf_range(-25.0, 25.0), 24.0, 156.0)
		x_positions.append(target_x)
	elif spike_count == 2:
		# Guarantee generous space across opposite screen halves with safe central corridor
		var left_x = randf_range(22.0, 80.0)
		var right_x = randf_range(102.0, 158.0)
		x_positions.append(left_x)
		x_positions.append(right_x)
	else:
		# 3 spikes: well-separated across three distinct lanes with safe corridors
		x_positions.append(randf_range(22.0, 52.0))
		x_positions.append(randf_range(74.0, 106.0))
		x_positions.append(randf_range(128.0, 158.0))
		
	for x_pos in x_positions:
		_create_danger_indicator_at(x_pos)

func _create_danger_indicator_at(x_coord: float) -> void:
	var ind = indicator_scene.instantiate()
	ind.position = Vector2(x_coord, 26.0)
	ind.timer_finished.connect(_on_danger_timer_finished)
	$HUD.add_child(ind)

func _on_danger_timer_finished(x_coord: float) -> void:
	if is_game_over:
		return
	SoundFX.play_shoot()
	var spike = falling_spike_scene.instantiate()
	var top_y = camera.position.y - (get_viewport_rect().size.y * 0.5) - 12.0
	spike.position = Vector2(x_coord, top_y)
	spikes_container.add_child(spike)

func _spawn_bug_crowd(base_y: float) -> void:
	var crowd_count = randi_range(5, 6)
	var x_step = 140.0 / float(crowd_count + 1)
	for i in range(crowd_count):
		# Point bugs only: Housefly (0) or Butterfly (1) - ZERO bees
		var point_bug_type = 0 if randf() < 0.55 else 1
		var bx = 20.0 + (i + 1) * x_step + randf_range(-8.0, 8.0)
		bx = clamp(bx, 16.0, 164.0)
		var by = base_y - randf_range(10.0, 50.0)
		_spawn_bug(Vector2(bx, by), point_bug_type)

func _generate_up_to(target_y: float) -> void:
	while highest_generated_y > target_y:
		var current_alt = max(0.0, (160.0 - highest_generated_y) / 10.0)
		
		# Celebratory bug swarm every 500m (5-6 point bugs, NO bees)
		if current_alt >= next_bug_crowd_milestone:
			_spawn_bug_crowd(highest_generated_y)
			next_bug_crowd_milestone += 500
			
		var p_type = _get_random_platform_type(current_alt)
		
		# Prevent close mushrooms: enforce strict minimum distance of 300px (~30 meters)
		if p_type == 2 and abs(highest_generated_y - last_shroom_y) < 300.0:
			p_type = 0 # Fallback to solid normal platform
		
		# Standard, manageable vertical jump gap ensuring manual climbing is always possible
		var gap: float
		if current_alt < 35.0:
			gap = randf_range(36.0, 46.0)
		elif current_alt < 80.0:
			gap = randf_range(38.0, 48.0)
		else:
			gap = randf_range(40.0, 50.0)
		highest_generated_y -= gap
		
		var main_plat_x: float = 0.0
		platforms_since_last_spike += 1
		
		if p_type == 2:
			# SPRING PLATFORM
			last_shroom_y = highest_generated_y
			var is_solitary_risk = (current_alt >= 35.0 and randf() < 0.20) # Rarer solitary high-risk spring (20% at 35m+)
			
			if is_solitary_risk:
				# Rarer solitary spring: suspended alone with reward point bugs
				var shroom_x = randf_range(35.0, 145.0)
				var shroom = platform_scene.instantiate()
				shroom.position = Vector2(shroom_x, highest_generated_y)
				shroom.type = 2 # SPRING
				platforms_container.add_child(shroom)
				main_plat_x = shroom_x
				
				# Ascending reward bugs above solitary spring (Flies/Butterflies only, NO bees)
				var num_reward_bugs = 2 if randf() < 0.5 else 3
				for b_idx in range(num_reward_bugs):
					var point_bug_type = 1 if randf() < 0.65 else 0 # Butterfly (50pts) or Housefly (10pts)
					var bug_pos = Vector2(
						clamp(shroom_x + randf_range(-10.0, 10.0), 18.0, 162.0),
						highest_generated_y - (26.0 + b_idx * 22.0)
					)
					_spawn_bug(bug_pos, point_bug_type)
			else:
				# Safe companion branch: mushroom + solid platform for manual climbing (80%+)
				var side = randi() % 2
				var shroom_x: float
				var plat_x: float
				if side == 0:
					shroom_x = randf_range(22.0, 60.0)
					plat_x = randf_range(105.0, 155.0)
				else:
					shroom_x = randf_range(120.0, 158.0)
					plat_x = randf_range(25.0, 75.0)
				
				var shroom = platform_scene.instantiate()
				shroom.position = Vector2(shroom_x, highest_generated_y)
				shroom.type = 2 # SPRING
				platforms_container.add_child(shroom)
				
				var companion = platform_scene.instantiate()
				companion.position = Vector2(plat_x, highest_generated_y)
				companion.type = 0 # NORMAL SOLID PLATFORM
				platforms_container.add_child(companion)
				main_plat_x = plat_x
				
				if randf() < 0.40:
					var bug_type = _get_random_bug_type()
					if bug_type == 2: bug_type = 0 # Friendly housefly near companion, no bees
					var bug_x = clamp(plat_x + (randf_range(20.0, 35.0) * (1.0 if randf() > 0.5 else -1.0)), 14.0, 166.0)
					var bug_y = highest_generated_y - randf_range(14.0, 24.0)
					_spawn_bug(Vector2(bug_x, bug_y), bug_type)
			
			# No spiky plant traps within jump height (~280px) above this mushroom
			no_spike_until_y = highest_generated_y - 280.0
		elif p_type == 3:
			# MOVING PLATFORM (slides smoothly left and right, fully pass-through from below)
			# ZERO SPIKES on moving platforms to prevent unavoidable traps!
			var plat_x = randf_range(40.0, 140.0)
			var plat = platform_scene.instantiate()
			plat.position = Vector2(plat_x, highest_generated_y)
			plat.type = 3 # MOVING
			platforms_container.add_child(plat)
			main_plat_x = plat_x
			
			# ZERO BEES ON MOVING PLATFORMS! Only friendly point bugs (Butterfly/Fly)
			if randf() < 0.45:
				var bug_type = 1 if randf() < 0.40 else 0 # Butterfly (50pts) or Housefly (10pts)
				var bug_x = clamp(plat_x + randf_range(-18.0, 18.0), 16.0, 164.0)
				var bug_y = highest_generated_y - randf_range(16.0, 28.0)
				_spawn_bug(Vector2(bug_x, bug_y), bug_type)
		else:
			# NORMAL (0) or BREAKING (1) PLATFORM
			var plat_x = randf_range(28.0, 152.0)
			var plat = platform_scene.instantiate()
			plat.position = Vector2(plat_x, highest_generated_y)
			plat.type = p_type
			platforms_container.add_child(plat)
			main_plat_x = plat_x
			
			# Spiky plant trap on solid normal platforms:
			# Strict anti-frustration fairness rules:
			# 1. At least 3 platforms since last spike (NEVER 2 spikes in a row!)
			# 2. Never directly after a breaking platform (gives safe recovery jump)
			# 3. Never within 280px of a mushroom launch zone
			# 4. Only placed on the far left or right edge, leaving 33px+ of safe solid ground to land on!
			var can_spawn_spike = (
				p_type == 0
				and current_alt >= 40.0
				and highest_generated_y < no_spike_until_y
				and platforms_since_last_spike >= 3
				and last_platform_type != 1
				and randf() < 0.12
			)
			if can_spawn_spike:
				platforms_since_last_spike = 0
				# Only place on extreme outer edge (-15 or +15), leaving center and other edge completely safe
				var spike_offset = -15.0 if randf() < 0.5 else 15.0
				plat.setup_spike_trap(spike_offset)
			
			# Spawn bug near platform
			if randf() < 0.50:
				var bug_type = _get_random_bug_type()
				var bug_y: float
				var bug_x: float
				
				if bug_type == 2:
					# BEE: centered over platform
					bug_x = main_plat_x
					bug_y = highest_generated_y - randf_range(16.0, 24.0)
				else:
					# Point bugs / heart moth: side open air
					var side_dir = 1.0 if randf() > 0.5 else -1.0
					bug_x = main_plat_x + (randf_range(24.0, 42.0) * side_dir)
					bug_y = highest_generated_y - randf_range(12.0, 30.0)
				bug_x = clamp(bug_x, 14.0, 166.0)
				_spawn_bug(Vector2(bug_x, bug_y), bug_type)
				
		last_platform_type = p_type

func _get_random_platform_type(current_alt: float) -> int:
	var roll = randf()
	if current_alt < 35.0:
		# Early Canopy (0 - 35m): Relaxed learning curve
		# 80% Normal, 14% Breaking, 6% Spring, 0% Moving
		if roll < 0.80:
			return 0 # NORMAL
		elif roll < 0.94:
			return 1 # BREAKING
		else:
			return 2 # SPRING
	elif current_alt < 80.0:
		# Mid Canopy (35 - 80m): Moving platforms & higher agility
		# 55% Normal, 25% Moving, 14% Breaking, 6% Spring
		if roll < 0.55:
			return 0 # NORMAL
		elif roll < 0.80:
			return 3 # MOVING
		elif roll < 0.94:
			return 1 # BREAKING
		else:
			return 2 # SPRING
	else:
		# High Canopy (80m+): Dynamic platforming
		# 44% Normal, 35% Moving, 15% Breaking, 6% Spring
		if roll < 0.44:
			return 0 # NORMAL
		elif roll < 0.79:
			return 3 # MOVING
		elif roll < 0.94:
			return 1 # BREAKING
		else:
			return 2 # SPRING

func _spawn_bug(pos: Vector2, bug_type: int) -> void:
	var bug = bug_scene.instantiate()
	bug.position = pos
	bug.type = bug_type
	bugs_container.add_child(bug)

func _get_random_bug_type() -> int:
	var total = weight_housefly + weight_butterfly + weight_bee + weight_heart_moth
	var roll = randi_range(1, total)
	
	var accum = weight_housefly
	if roll <= accum:
		return 0 # Housefly (55%)
		
	accum += weight_butterfly
	if roll <= accum:
		return 1 # Butterfly (35%)
		
	accum += weight_bee
	if roll <= accum:
		return 2 # Bee (9%)
		
	return 3 # Heart Moth (1%)

func _cleanup_offscreen() -> void:
	var threshold = camera.position.y + (get_viewport_rect().size.y * 0.5) + 50.0
	for p in platforms_container.get_children():
		if p.position.y > threshold:
			p.queue_free()
	for b in bugs_container.get_children():
		if b.position.y > threshold:
			b.queue_free()
	for s in spikes_container.get_children():
		if s.position.y > threshold:
			s.queue_free()

func _on_score_changed(new_score: int) -> void:
	score_label.text = str(new_score)

func _on_altitude_changed(meters: int) -> void:
	alt_label.text = str(meters) + "m"

func _on_hearts_changed(cur: int) -> void:
	_update_hearts_display(cur)

func _update_hearts_display(cur: int) -> void:
	heart1.texture = tex_heart_full if cur >= 1 else tex_heart_empty
	heart2.texture = tex_heart_full if cur >= 2 else tex_heart_empty
	heart3.texture = tex_heart_full if cur >= 3 else tex_heart_empty

func _on_player_died() -> void:
	if is_game_over:
		return
	is_game_over = true
	SoundFX.fade_out_music(1.0)
	
	var timer = get_tree().create_timer(1.25)
	timer.timeout.connect(func():
		top_bar.visible = false
		final_score_label.text = "Score: " + str(GameState.current_score)
		best_score_label.text = "High Score: " + str(GameState.high_score)
		bugs_eaten_label.text = "Bugs Eaten: " + str(GameState.bugs_eaten)
		max_alt_label.text = "Max Altitude: " + str(GameState.max_altitude) + "m"
		game_over_panel.visible = true
		AdManager.on_game_over()
	)

func _on_restart_pressed() -> void:
	SoundFX.play_hop()
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	SoundFX.play_hop()
	SoundFX.stop_music()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if is_game_over and game_over_panel.visible:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
			_on_restart_pressed()