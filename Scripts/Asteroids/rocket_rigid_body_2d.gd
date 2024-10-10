extends CharacterBody2D

var speed = 400  # Speed at which the rocket moves to the right
var up_down_speed = 300  # Speed for vertical movement
@onready var camera = get_node("/root/Main_asteroid/Camera2D")
@onready var sprite = $RocketSprite  # Access the Sprite node with its texture
@onready var animated_sprite = $AnimatedSprite2D  # Access the AnimatedSprite2D node for explosion/animation
@onready var main = $"../.."


var is_destroyed = false
var stop_cam = false

func _ready():
	# Place the rocket at the left side of the screen
	var viewport_size = get_viewport_rect().size
	camera.position = Vector2(viewport_size.x / 2, viewport_size.y / 2)
	position.y = viewport_size.y * 0.5
	position.x = viewport_size.x * 0.1  # Set the rocket at 10% of the screen width (adjust as needed)

	# Ensure the animated sprite is hidden initially
	animated_sprite.hide()

func _process(delta):
	# Movement vector
	velocity = Vector2.ZERO
	
	if is_destroyed:
		return
	
	# Horizontal movement (constant speed)
	velocity.x = speed

	# Vertical movement (up/down) using arrow keys
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("a"):  # Move up
		velocity.y = -up_down_speed
	elif Input.is_action_pressed("ui_right") or Input.is_action_pressed("d"):  # Move down
		velocity.y = up_down_speed
	
	# Move the rocket
	move_and_slide()

	# Move the camera with the rocket horizontally
	if not stop_cam:
		camera.position.x = position.x + get_viewport_rect().size.x / 2  # Keep camera centered on rocket

	# Clamp the rocket's y position to keep it within the viewport bounds
	var viewport_rect = get_viewport_rect()
	var texture_size = sprite.texture.get_size()  # Get the size of the Sprite's texture
	position.y = clamp(position.y, 0, viewport_rect.size.y - texture_size.y)  # Prevent from moving out of top and bottom bounds

	# Check for collision with any body
	if is_on_wall() or is_on_floor() or is_on_ceiling():
		_trigger_explosion()  # Trigger explosion animation on collision

func _trigger_explosion():
	main.failed_game()
	GlobalAudio.audio_player2.stream = load("res://assets/Music/chip-explosion_150bpm.wav")
	GlobalAudio.audio_player2.play()
	# Hide the rocket sprite
	velocity = Vector2.ZERO
	is_destroyed = true
	sprite.hide()

	# Show and play the animated sprite
	animated_sprite.show()
	animated_sprite.play("explode")  # Play the explosion animation (make sure this matches your animation name)
	
	await get_tree().create_timer(2).timeout
	get_tree().change_scene_to_packed(load("res://Scenes/end.tscn"))

func stop_camera():
	stop_cam = true
