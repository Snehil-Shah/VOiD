extends Node2D  # Or whatever node type your planet is

@export var planet_radius: float = 100.0  # Adjust this to match your planet's size
@export var detection_threshold: float = 10.0  # How close the rocket needs to be to count as "on" the planet

@onready var sprite = $"../Sprite2D"

var rocket_node: Node2D  # Will store the reference to the rocket
var rocket_on_planet: bool = false

var original_scale = Vector2.ONE
var scale_increase = 1.1  # 20% size increase when overlapped

func _ready():
	# Wait a bit to ensure all nodes are in the scene tree
	await get_tree().process_frame
	original_scale = scale
	# Get the rocket node - adjust the path if necessary
	rocket_node = get_node("/root/Main/RocketScene/RocketSprite")  # Adjust this path
	if not rocket_node:
		print("Error: Couldn't find the rocket node!")

func _process(delta):
	if rocket_node:
		check_rocket_position()

func start_overlap_animation():
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(scale_increase, scale_increase), 0.3)

func stop_overlap_animation():
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1, 1), 0.3)

func check_rocket_position():
	#print(global_position, rocket_node.global_position)
	var distance_to_rocket = global_position.distance_to(rocket_node.global_position)
	
	if distance_to_rocket <= planet_radius + detection_threshold:
		if not rocket_on_planet:
			GlobalAudio.audio_player_low.stream = load("res://assets/Music/83044-Mouseover_soft_synth_swell-BLASTWAVEFX-20183.wav")
			GlobalAudio.audio_player_low.play()
			rocket_on_planet = true
			start_overlap_animation()
			# Add any other logic for when the rocket lands
	else:
		if rocket_on_planet:
			rocket_on_planet = false
			stop_overlap_animation()
			# Add any other logic for when the rocket leaves

# Optional: Function to check if a point is inside the planet
# Useful if you need to check multiple points or have a more complex shape
func is_point_inside_planet(point: Vector2) -> bool:
	return global_position.distance_to(point) <= planet_radius + detection_threshold
