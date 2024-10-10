extends Node2D

@onready var rocket = $RocketScene/RocketSprite
@onready var rocketChar = $RocketScene/CharacterBody2D
@onready var camera = $Camera2D
@onready var score_label = $CanvasLayer2/Panel/HBoxContainer/Label2
@onready var score_panel = $CanvasLayer2/Panel

var transition_tscn = preload("res://Scenes/transition.tscn")

var asteroid_scene = preload("res://Scenes/Asteroids/asteroid.tscn")
var end_game_scene = preload("res://Scenes/end.tscn")
var rng = RandomNumberGenerator.new()

var min_spawn_distance = 150.0
var cleanup_distance = 200.0

var failed = false

var min_asteroids_per_cluster = 3
var max_asteroids_per_cluster = 7
var min_distance_between_asteroids = 55.0
var max_distance_between_asteroids = 220.0
var min_time_between_clusters = 0.5
var max_time_between_clusters = 2.5

var min_asteroid_speed = 100.0
var max_asteroid_speed = 400.0

# New variables for rotation and size
var min_rotation_speed = -1.0  # radians per second
var max_rotation_speed = 1.0
var min_asteroid_scale = 1.7
var max_asteroid_scale = 4

# New variables to track time and end the game
var game_duration = 40.0  # Game will last for 35 seconds (randomly between 30-45, you can adjust)
var elapsed_time = 0.0
var is_game_over = false

var score_update_interval = 0.1
var score_update_timer = 0.0

func _ready():
	rng.randomize()
	#GlobalAudio.music_player.stream = load("res://assets/Music/Funky-Gameplay_Looping.mp3")
	#GlobalAudio.music_player.play()
	score_label.text = str(Globals.score) + "   "
	spawn_next_cluster()

func spawn_next_cluster():
	if not is_game_over:
		spawn_asteroid_cluster()
		var next_spawn_time = rng.randf_range(min_time_between_clusters, max_time_between_clusters)
		get_tree().create_timer(next_spawn_time).connect("timeout", Callable(self, "spawn_next_cluster"))

func spawn_asteroid_cluster():
	var num_asteroids = rng.randi_range(min_asteroids_per_cluster, max_asteroids_per_cluster)
	var viewport_rect = get_viewport_rect()
	var camera_center = camera.get_screen_center_position()
	var right_edge = camera_center.x + viewport_rect.size.x / 2
	var spawn_x = right_edge + min_spawn_distance
	
	for i in range(num_asteroids):
		var spawn_y = rng.randf_range(camera_center.y - viewport_rect.size.y / 2, 
									  camera_center.y + viewport_rect.size.y / 2)
		
		var asteroid_pos = Vector2(spawn_x, spawn_y)
		var asteroid_instance = asteroid_scene.instantiate()
		asteroid_instance.position = asteroid_pos
		
		# Set random speed, rotation, and size for the asteroid
		var speed = rng.randf_range(min_asteroid_speed, max_asteroid_speed)
		var rotation_speed = rng.randf_range(min_rotation_speed, max_rotation_speed)
		var scale_factor = rng.randf_range(min_asteroid_scale, max_asteroid_scale)
		
		var rigidbody = asteroid_instance.get_node("RigidBody2D")
		if rigidbody:
			rigidbody.linear_velocity = Vector2(-speed, 0)
			rigidbody.angular_velocity = rotation_speed
			rigidbody.mass *= scale_factor  # Adjust mass based on size
			var sprite = rigidbody.get_node("Sprite2D")
			sprite.scale = Vector2(scale_factor, scale_factor)
			var collision = rigidbody.get_node("CollisionPolygon2D")
			collision.scale = Vector2(scale_factor, scale_factor)
		
		asteroid_instance.add_to_group("asteroids")
		add_child(asteroid_instance)
		
		spawn_x += rng.randf_range(min_distance_between_asteroids, max_distance_between_asteroids)

func _process(delta):
	if is_game_over:
		return  # Stop updating when the game is over
	Globals.score += 1
	elapsed_time += delta
	
	# Update the score label every 0.2 seconds
	score_update_timer += delta
	if score_update_timer >= score_update_interval:
		score_label.text = str(Globals.score) + "   "
		score_update_timer = 0

	# Track elapsed time
	elapsed_time += delta
	
	if elapsed_time >= game_duration and not is_game_over:
		_end_game()  # End the game after the defined duration
	
	cleanup_asteroids()

func cleanup_asteroids():
	var left_edge = camera.get_screen_center_position().x - get_viewport_rect().size.x / 2
	var cleanup_threshold = left_edge - cleanup_distance
	
	for asteroid in get_tree().get_nodes_in_group("asteroids"):
		if asteroid.position.x < cleanup_threshold:
			asteroid.queue_free()

func _end_game():
	is_game_over = true
	
	await get_tree().create_timer(1.5).timeout
	# Stop the camera from moving
	rocketChar.stop_camera()

	# Change the scene after a short delay
	await get_tree().create_timer(4.5).timeout
	if failed:
		return
	_change_scene()
	
func failed_game():
	is_game_over = true
	failed = true

func _change_scene():
	# Change the scene to the next one (replace with the actual scene path)
	#get_tree().call_deferred("change_scene_to_packed", load("res://Scenes/main.tscn"))
	trigger_transition(load("res://Scenes/main.tscn"))
	
func trigger_transition(new_scene):
	var transition_instance = transition_tscn.instantiate()
	get_tree().current_scene.add_child(transition_instance)

	var animated_sprite = transition_instance.get_node("AnimatedSprite2D")
	
	animated_sprite.position = camera.position
	
	score_panel.hide()
	GlobalAudio.audio_player_low.stream = load("res://assets/Music/83044-Mouseover_soft_synth_swell-BLASTWAVEFX-20183.wav")
	GlobalAudio.audio_player_low.play()
	GlobalAudio.music_player.stream = load("res://assets/Music/Factory-On-Mercury_Looping.mp3")
	GlobalAudio.music_player.play()
	animated_sprite.play()

	# Connect to the animation_finished signal
	animated_sprite.animation_finished.connect(_on_transition_finished.bind(new_scene, transition_instance))

func _on_transition_finished(new_scene, transition_instance):
	get_tree().change_scene_to_packed(new_scene)
	transition_instance.queue_free()
