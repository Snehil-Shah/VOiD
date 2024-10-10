extends CharacterBody2D

var rotation_speed = 1.0
var speed: float = 150.0
var friction: float = 0.9

@onready var gun_sprite = $AnimatedSprite2D
@onready var base_sprite = $TankBase
@onready var muzzle = gun_sprite.get_node("Muzzle")
@onready var raycast = $RayCast2D

@onready var animated_sprite = $AnimatedSprite2D2

@onready var score_label = $"../../CanvasLayer2/Panel/HBoxContainer/Label2"

@onready var main = get_parent().get_parent()

var Bullet = preload("res://Scenes/Red/enemy_bullet.tscn")
var can_shoot = true
var shoot_delay = 2.0

var is_destroyed = false

var player: Node2D
var detection_range = 800
var min_distance = 600

var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()

func _process(delta):
	if player and not main.end and not is_destroyed:
		var distance_to_player = global_position.distance_to(player.global_position)
		
		# Stop chasing if within min_distance, just shoot
		if distance_to_player > min_distance:
			follow_player(delta)
		else:
			rotate_gun_to_player()  # Rotate gun towards player even if not chasing
			attempt_to_shoot()

	apply_friction(delta)  # Apply friction before moving
	move_and_slide()  # Moves the tank based on velocity

func set_player(p):
	player = p

func follow_player(delta):
	if not player:
		return
	
	var direction = global_position.direction_to(player.global_position)
	var distance = global_position.distance_to(player.global_position)
	
	if distance > min_distance:
		move_in_direction(direction, delta)

func move_in_direction(direction, delta):
	raycast.target_position = direction * 100
	raycast.force_raycast_update()
	
	if raycast.is_colliding():
		direction = direction.rotated(PI / 2)
	
	velocity = direction * speed * (0.8 + rng.randf() * 0.4)  # Add some randomness to speed
	rotation = lerp_angle(rotation, direction.angle(), rotation_speed * delta)

func rotate_gun_to_player():
	if player:
		var angle_to_player = (player.global_position - global_position).angle()
		gun_sprite.global_rotation = angle_to_player + PI / 2

func apply_friction(delta) -> void:
	velocity = velocity.lerp(Vector2.ZERO, friction * delta)  # Apply friction over time

func attempt_to_shoot():
	if can_shoot and player and global_position.distance_to(player.global_position) < detection_range:
		shoot()

func shoot():
	can_shoot = false  # Prevent further shooting
	gun_sprite.play("shoot")

	# Wait before firing the bullet
	await get_tree().create_timer(0.3).timeout

	# Instantiate the bullet and set its position at the muzzle of the gun
	var bullet = Bullet.instantiate()
	bullet.position = muzzle.global_position

	# Add random spread to the bullet's direction
	var random_angle = (rng.randf() - 0.5) * 0.1  # +/- 0.05 radians
	var shoot_direction = Vector2.RIGHT.rotated(gun_sprite.global_rotation - PI / 2 + random_angle)

	# Set the bullet's direction and rotation
	bullet.set_direction(shoot_direction)
	bullet.rotation = gun_sprite.global_rotation - PI / 2 + random_angle  # Set bullet's rotation to match the direction with spread

	# Add the bullet to the scene tree root instead of the tank's parent
	get_parent().get_parent().add_child(bullet)

	# Wait for the shoot delay
	await get_tree().create_timer(shoot_delay).timeout

	# Allow shooting again
	can_shoot = true
	
func take_damage():
	is_destroyed = true
	Globals.score += 150
	score_label.text = str(Globals.score) + "   "
	
	_trigger_explosion()

func _trigger_explosion():
	GlobalAudio.audio_player2.stream = load("res://assets/Music/chip-explosion_150bpm.wav")
	GlobalAudio.audio_player2.play()
	# Hide the rocket sprite
	velocity = Vector2.ZERO
	base_sprite.hide()
	gun_sprite.hide()

	# Show and play the animated sprite
	animated_sprite.show()
	animated_sprite.play("explode")

	# Connect to the animation_finished signal
	animated_sprite.animation_finished.connect(_on_transition_finished)

func _on_transition_finished():
	# Queue this node for deletion instead of its parent
	get_parent().queue_free()
