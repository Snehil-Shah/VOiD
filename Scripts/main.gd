extends Node2D

var planet_textures: Array = [
	preload("res://Downloads/Planets/Black_hole.png"),
	preload("res://Downloads/Planets/Lava.png"),
]

var planets = []

var rng = RandomNumberGenerator.new()
var spawn_distance = 500.0
var min_planets_per_region = 40
var max_planets_per_region = 50
var planet_size_range = Vector2(5.5, 6.5)
var spawn_chance = 0.5
var min_planet_distance = 1200.0

var MAX_CHECK_DISTANCE = 2400

@onready var rocket = $RocketScene/RocketSprite
@onready var fade_layer = $CanvasLayer
@onready var fade_panel = $CanvasLayer/Control/Panel
@onready var info_label = $CanvasLayer/Control/Panel/Label
@onready var score_label = $CanvasLayer2/Panel/Label
@onready var score_panel = $CanvasLayer2/Panel
@onready var transition_scene = load("res://Scenes/transition.tscn")

var spawned_objects = {}
var explored_regions = {}
var region_size = Vector2(1800, 1800)

var is_changing_scene = false

func _ready():
	rng.randomize()
	score_label.text = "   SCORE: {0}   ".format([Globals.score])
	setup_fade_layer()
	spawn_initial_planets()  # Add this line to spawn initial planets
	
func spawn_initial_planets():
	if not is_instance_valid(rocket):
		print("Error: Rocket node not found or invalid")
		return

	var viewport_rect = get_viewport().get_visible_rect()
	var current_region = get_region(rocket.global_position)

	# Spawn planets in the current region and adjacent regions
	var regions_to_spawn = get_adjacent_regions(current_region)
	regions_to_spawn.append(current_region)  # Include the current region

	for region in regions_to_spawn:
		if not explored_regions.has(region):
			explored_regions[region] = true
			spawn_objects_in_region_around(region, viewport_rect)

func setup_fade_layer():
	fade_panel.modulate = Color(1, 1, 1, 0)  # Start fully transparent
	fade_layer.hide()  # Start hidden

func fade_in_layer():
	fade_layer.show()
	var tween = create_tween()
	tween.tween_property(fade_panel, "modulate:a", 1.0, 0.2)  # Fade to fully opaque over 1 second

func fade_out_layer():
	var tween = create_tween()
	tween.tween_property(fade_panel, "modulate:a", 0.0, 0.2)  # Fade to fully transparent over 1 second
	tween.tween_callback(fade_layer.hide)

func _process(_delta):
	if is_changing_scene:
		return
	if not is_instance_valid(rocket):
		print("Error: Rocket node not found or invalid")
		return
	check_overlaps()
	check_spawn_objects()
	clean_up_distant_objects()

func check_overlaps():
	var rocket_on_any_planet = false
	for planet in planets:
		var area2d = planet.get_node("Area2D")
		var texture = planet.get_node("Sprite2D").texture
		if area2d.rocket_on_planet:
			rocket_on_any_planet = true
			if Input.is_action_just_pressed("ui_accept"):
				fade_out_layer()
				change_to_mini_game(texture)
			break
	
	if rocket_on_any_planet and not fade_layer.visible:
		fade_in_layer()
	elif not rocket_on_any_planet and fade_layer.visible:
		fade_out_layer()

func change_to_mini_game(texture):
	var scene
	var audio
	is_changing_scene = true
	if texture == planet_textures[0]:
		scene = "res://Scenes/Asteroids/main_asteroid.tscn"
		audio = "res://assets/Music/Retro-Frantic_Looping.mp3"
	if texture == planet_textures[1]:
		scene = "res://Scenes/Red/red.tscn"
		audio = "res://assets/Music/Steamtech-Mayhem_Looping.mp3"
		
	score_panel.hide()
	var mini_game_scene = load(scene)
	if mini_game_scene:
		trigger_transition(mini_game_scene, audio)
	else:
		print("Error: Failed to load the mini-game scene.")
		is_changing_scene = false

#func trigger_transition(new_scene):
	#var transition_instance = transition_scene.instantiate()
	#get_tree().current_scene.add_child(transition_instance)
#
	#var animated_sprite = transition_instance.get_node("AnimatedSprite2D")
	#animated_sprite.play()
#
	## Connect to the animation_finished signal
	#animated_sprite.animation_finished.connect(_on_transition_finished.bind(new_scene, transition_instance))

func trigger_transition(new_scene, audio):
	var transition_instance = transition_scene.instantiate()
	get_tree().root.add_child(transition_instance)

	var animated_sprite = transition_instance.get_node("AnimatedSprite2D")
	if animated_sprite:
		# Position the transition at the center of the screen (where the rocket is)
		animated_sprite.global_position = Vector2(rocket.position.x, rocket.position.y)

		GlobalAudio.music_player.stream = load(audio)
		GlobalAudio.music_player.play()
		animated_sprite.play()
		# Connect to the animation_finished signal
		animated_sprite.animation_finished.connect(_on_transition_finished.bind(new_scene, transition_instance))
	else:
		push_error("AnimatedSprite2D not found in transition scene")
		_on_transition_finished(new_scene, transition_instance)

func _on_transition_finished(new_scene, transition_instance):
	get_tree().change_scene_to_packed(new_scene)
	transition_instance.queue_free()

func check_spawn_objects():
	if not is_instance_valid(get_viewport()):
		print("Error: Viewport is null")
		return
	var viewport_rect = get_viewport().get_visible_rect()
	var current_region = get_region(rocket.global_position)
	var adjacent_regions = get_adjacent_regions(current_region)
	
	for region in adjacent_regions:
		if not explored_regions.has(region):
			explored_regions[region] = true
			spawn_objects_in_region(region, viewport_rect)

func get_region(position):
	var x = floor(position.x / region_size.x)
	var y = floor(position.y / region_size.y)
	return Vector2(x, y)

func get_adjacent_regions(region):
	return [region, region + Vector2.RIGHT, region + Vector2.LEFT, region + Vector2.UP, region + Vector2.DOWN]

func spawn_objects_in_region(region, viewport_rect):
	var base_pos = region * region_size
	var objects_spawned = 0
	var attempts = 0
	var max_attempts = max_planets_per_region * 3

	while objects_spawned < max_planets_per_region and attempts < max_attempts:
		var object_pos = base_pos + Vector2(rng.randf_range(0, region_size.x), rng.randf_range(0, region_size.y))
		if not is_position_visible(object_pos, viewport_rect) and is_position_valid(object_pos):
			spawn_space_object(object_pos)
			objects_spawned += 1
		attempts += 1
		
		if objects_spawned >= min_planets_per_region and rng.randf() > spawn_chance:
			break

func spawn_objects_in_region_around(region, viewport_rect):
	var base_pos = region * region_size
	var objects_spawned = 0
	var attempts = 0
	var max_attempts = max_planets_per_region * 3

	while objects_spawned < max_planets_per_region and attempts < max_attempts:
		var object_pos = base_pos + Vector2(rng.randf_range(0, region_size.x), rng.randf_range(0, region_size.y))
		if is_position_valid(object_pos):
			spawn_space_object(object_pos)
			objects_spawned += 1
		attempts += 1
		
		if objects_spawned >= min_planets_per_region and rng.randf() > spawn_chance:
			break

func is_position_visible(pos, viewport_rect):
	var camera_center = rocket.global_position
	var expanded_rect = viewport_rect.grow(spawn_distance)
	expanded_rect.position += camera_center - expanded_rect.size / 2
	return expanded_rect.has_point(pos)

func is_position_valid(pos):
	for existing_pos in spawned_objects.keys():
		if pos.distance_to(existing_pos) < min_planet_distance:
			return false
	return true

func spawn_space_object(pos):
	var object_scene = load("res://Scenes/planet.tscn")
	if object_scene:
		var object_instance = object_scene.instantiate()
		
		var area2d = object_instance.get_node("Area2D")
		var collision_shape = area2d.get_node("CollisionShape2D")
		var circle_shape = collision_shape.shape
		
		var object_sprite = object_instance.get_node("Sprite2D")
		
		# Get texture of the nearest planet
		var nearest_texture = get_nearest_planet_texture(pos)
		
		# Choose a texture that's not used by the nearest planet
		var available_textures = planet_textures.duplicate()
		if nearest_texture:
			available_textures.erase(nearest_texture)
		
		# If all textures have been removed, reset the list
		if available_textures.is_empty():
			available_textures = planet_textures.duplicate()
		
		var chosen_texture = available_textures[rng.randi() % available_textures.size()]
		object_sprite.texture = chosen_texture
		
		object_instance.position = pos
		var random_scale = rng.randf_range(planet_size_range.x, planet_size_range.y)
		
		object_instance.scale = Vector2(random_scale, random_scale)
		
		if circle_shape is CircleShape2D:
			circle_shape.radius = random_scale
		
		add_child(object_instance)
		planets.append(object_instance)
		spawned_objects[pos] = object_instance
	else:
		print("Error: Could not load space object scene")

func get_nearest_planet_texture(pos):
	var nearest_distance = MAX_CHECK_DISTANCE
	var nearest_texture = null
	
	for planet_pos in spawned_objects.keys():
		var distance = planet_pos.distance_to(pos)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_texture = spawned_objects[planet_pos].get_node("Sprite2D").texture
	
	return nearest_texture

func clean_up_distant_objects():
	var viewport_rect = get_viewport().get_visible_rect()
	var camera_center = rocket.global_position
	var max_distance = max(viewport_rect.size.x, viewport_rect.size.y) * 2.5

	var objects_to_remove = []
	for pos in spawned_objects.keys():
		if pos.distance_to(camera_center) > max_distance:
			objects_to_remove.append(pos)

	for pos in objects_to_remove:
		var planet_instance = spawned_objects[pos]
		planet_instance.queue_free()
		spawned_objects.erase(pos)
		planets.erase(planet_instance)

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		# Clean up any resources, stop timers, etc.
		set_process(false)
		planets.clear()
		spawned_objects.clear()
