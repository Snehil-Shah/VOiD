extends Node2D

var EnemyTank = preload("res://Scenes/Red/enemy.tscn")  # Adjust this path to match your EnemyTank scene location
@onready var player = $Player/CharacterBody2D

@onready var score_panel = $CanvasLayer2/Panel

var transition_tscn = preload("res://Scenes/transition.tscn")

var spawn_interval = 5.0  # Time between spawns in seconds
var max_enemies = 4  # Maximum number of enemies on screen at once
var total_enemies = 14 # Total number of enemies to spawn in the game
var spawn_margin = 100  # Margin outside the play area to spawn enemies

var viewport_size: Vector2
var rng = RandomNumberGenerator.new()
var time_since_last_spawn = 0.0
var spawned_enemies_count = 0  # Count of spawned enemies

# Define the boundaries for the tank's movement (should match the values in the tank script)
var min_x = 0
var max_x = 2800
var min_y = 0
var max_y = 2800

var end = false

var camera

func _ready():
	Input.set_custom_mouse_cursor(load("res://Downloads/160+ Cursors Crosshairs - Pack (32x32)/160+ Cursors Crosshairs - Pack (32x32)/white/25.png"))
	viewport_size = get_viewport().get_visible_rect().size
	camera = player.get_node("Camera2D")
	rng.randomize()

func _process(delta):
	if end:
		return
	if spawned_enemies_count == total_enemies and get_tree().get_nodes_in_group("enemies").size() == 0:
		done()
	time_since_last_spawn += delta
	if time_since_last_spawn >= spawn_interval:
		if get_tree().get_nodes_in_group("enemies").size() < max_enemies and spawned_enemies_count < total_enemies:
			spawn_enemy()
		time_since_last_spawn = 0.0
	
	update_enemy_targets()

func spawn_enemy():
	var enemy = EnemyTank.instantiate()
	var enemyBody = enemy.get_node("CharacterBody2D")
	
	# Decide which side to spawn from (0: top, 1: right, 2: bottom, 3: left)
	var side = rng.randi() % 2
	
	var spawn_position = Vector2.ZERO
	match side:
		0:  # Right
			spawn_position = Vector2(max_x + spawn_margin, rng.randf_range(min_y + spawn_margin, max_y - spawn_margin))  # Avoid top and bottom
		1:  # Left
			spawn_position = Vector2(min_x - spawn_margin, rng.randf_range(min_y + spawn_margin, max_y - spawn_margin))  # Avoid top and bottom
	
	enemyBody.position = spawn_position
	enemy.add_to_group("enemies")
	add_child(enemy)
	spawned_enemies_count += 1  # Increment the count of spawned enemies
	print("enemy was spawned. Total: ", spawned_enemies_count)

func update_enemy_targets():
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		# Assuming the CharacterBody2D is a direct child of the enemy root node
		var enemy_body = enemy.get_node("CharacterBody2D")  # Adjust the path if necessary
		if enemy_body and enemy_body.has_method("set_player"):
			enemy_body.set_player(player)

# Optional: Add a method to change difficulty over time
func increase_difficulty():
	spawn_interval = max(1, spawn_interval - 0.5)  # Decrease interval, but not below 1 second
	max_enemies += 1  # Increase max enemies

# Optional: Add a method to clean up off-screen enemies
# func _on_cleanup_timer_timeout():
#	var enemies = get_tree().get_nodes_in_group("enemies")
#	for enemy in enemies:
#		if enemy.position.x < min_x - spawn_margin or enemy.position.x > max_x + spawn_margin or \
#		   enemy.position.y < min_y - spawn_margin or enemy.position.y > max_y + spawn_margin:
#			enemy.queue_free()

func done():
	end = true
	await get_tree().create_timer(0.2).timeout
	score_panel.hide()
	_change_scene()
	
func _change_scene():
	Input.set_custom_mouse_cursor(null)
	# Change the scene to the next one (replace with the actual scene path)
	#get_tree().call_deferred("change_scene_to_packed", load("res://Scenes/main.tscn"))
	trigger_transition(load("res://Scenes/main.tscn"))
	
func trigger_transition(new_scene):
	var transition_instance = transition_tscn.instantiate()
	get_tree().current_scene.add_child(transition_instance)

	var animated_sprite = transition_instance.get_node("AnimatedSprite2D")
	
	animated_sprite.position = camera.get_screen_center_position()

	GlobalAudio.audio_player_low.stream = load("res://assets/Music/83044-Mouseover_soft_synth_swell-BLASTWAVEFX-20183.wav")
	GlobalAudio.audio_player_low.play()
	GlobalAudio.music_player.stream = load("res://assets/Music/Factory-On-Mercury_Looping.mp3")
	GlobalAudio.music_player.play()
	animated_sprite.play("default")

	# Connect to the animation_finished signal
	animated_sprite.animation_finished.connect(_on_transition_finished.bind(new_scene, transition_instance))

func _on_transition_finished(new_scene, transition_instance):
	get_tree().change_scene_to_packed(new_scene)
	transition_instance.queue_free()
