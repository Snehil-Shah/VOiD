extends CharacterBody2D

var rotation_speed = 1.5
var speed: float = 300.0
var friction: float = 0.8

@onready var gun_sprite = $AnimatedSprite2D
@onready var base_sprite = $TankBase
@onready var muzzle = gun_sprite.get_node("Muzzle")  # Add a Position2D node as a child of the gun sprite and name it "Muzzle"

@onready var main = get_parent().get_parent()
var end_game_scene = preload("res://Scenes/end.tscn")
@onready var animated_sprite = $AnimatedSprite2D2

@onready var score_label = $"../../CanvasLayer2/Panel/HBoxContainer/Label2"

var Bullet = preload("res://Scenes/Red/bullet.tscn")  # Make sure this path matches your Bullet scene location
var can_shoot = true
var shoot_delay = 0.5  # Half a second between shots

var health

var is_destroyed = false

# Define the boundaries for the tank's movement
var min_x = 0
var max_x = 2800  # Adjust this to your game's width
var min_y = 0
var max_y = 2800  # Adjust this to your game's height

func _ready():
	score_label.text = str(Globals.score) + "   "
	health = $CanvasLayer/ProgressBar
	health.value = 100

func _process(delta):
	handle_input(delta)
	apply_friction()
	move_and_rotate(delta)
	clamp_position()
	rotate_gun_to_mouse()

func rotate_gun_to_mouse():
	var mouse_position = get_global_mouse_position()
	var angle_to_mouse = (mouse_position - global_position).angle()
	gun_sprite.global_rotation = angle_to_mouse + PI / 2

func apply_friction() -> void:
	velocity *= friction

func handle_input(delta: float) -> void:
	
	if main.end or is_destroyed:
		health.hide()
		return
	
	var direction: Vector2 = Vector2.ZERO

	if Input.is_action_pressed("ui_up") or Input.is_action_pressed("w"):
		direction.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_action_pressed("s"):
		direction.y += 1

	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("a"):
		rotation -= rotation_speed * delta
	if Input.is_action_pressed("ui_right") or Input.is_action_pressed("d"):
		rotation += rotation_speed * delta

	if direction != Vector2.ZERO:
		direction = direction.rotated(rotation)
		velocity = direction * speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	if Input.is_action_just_pressed("shoot") and can_shoot:
		shoot()

func move_and_rotate(delta: float) -> void:
	move_and_slide()

func clamp_position():
	position.x = clamp(position.x, min_x, max_x)
	position.y = clamp(position.y, min_y, max_y)

func shoot():
	gun_sprite.play("shoot")

	# Delay for muzzle flash or any animation if necessary
	await get_tree().create_timer(0.3).timeout

	# Instantiate the bullet and set its position at the muzzle of the gun
	var bullet = Bullet.instantiate()
	bullet.position = muzzle.global_position

	# Set the direction for the bullet based on the gun's rotation
	var bullet_direction = Vector2.RIGHT.rotated(gun_sprite.global_rotation - PI / 2)
	bullet.set_direction(bullet_direction)

	# Set the bullet's rotation to match the gun's rotation
	bullet.rotation = gun_sprite.global_rotation - PI / 2

	# Add the bullet to the scene
	get_parent().add_child(bullet)

	# Handle the shooting cooldown
	can_shoot = false
	await get_tree().create_timer(shoot_delay).timeout
	can_shoot = true


func take_damage():
	health.value -= 10
	Globals.score -= 50
	score_label.text = str(Globals.score) + "   "
	if health.value == 0:
		_trigger_explosion()
	else:
		GlobalAudio.audio_player3.stream = load("res://assets/Music/1147094.audio-Dsgn_8_Bit_Explosion_01.wav")
		GlobalAudio.audio_player3.play()
		
func _trigger_explosion():
	# Hide the rocket sprite
	velocity = Vector2.ZERO
	is_destroyed = true
	
	GlobalAudio.audio_player3.stream = load("res://assets/Music/chip-explosion_150bpm.wav")
	GlobalAudio.audio_player3.play()
	base_sprite.hide()
	gun_sprite.hide()

	# Show and play the animated sprite
	animated_sprite.show()
	animated_sprite.play("explode")

	# Connect to the animation_finished signal
	animated_sprite.animation_finished.connect(_on_transition_finished)

func _on_transition_finished():
	# Queue this node for deletion instead of its parent
	main.end = true
	Input.set_custom_mouse_cursor(null)
	get_parent().queue_free()
	get_tree().change_scene_to_packed(end_game_scene)
	
	
