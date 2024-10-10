extends Sprite2D

# Variables for movement
var speed: float = 800.0
var acceleration: float = 2000.0
var velocity: Vector2 = Vector2.ZERO
var friction: float = 0.9

# Rotation speed
var rotation_speed: float = 3.0

# Reference to Camera2D
var camera: Camera2D

# Set the rocket's position to the center of the viewport
func _ready() -> void:
	position = get_viewport().size / 2


# Physics processing for smooth movement
func _physics_process(delta: float) -> void:
	handle_input(delta)
	apply_friction()
	move_and_rotate(delta)

# Handle input for moving the rocket
func handle_input(delta: float) -> void:
	var direction: Vector2 = Vector2.ZERO

	# Move forward/backward
	if Input.is_action_pressed("ui_up") or Input.is_action_pressed("w"):
		direction.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_action_pressed("s"):
		direction.y += 1

	# Rotate left/right
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("a"):
		rotation -= rotation_speed * delta
	if Input.is_action_pressed("ui_right") or Input.is_action_pressed("d"):
		rotation += rotation_speed * delta

	# Update velocity based on direction
	if direction != Vector2.ZERO:
		direction = direction.rotated(rotation)
		velocity += direction * acceleration * delta

# Apply friction to slow the rocket down over time
func apply_friction() -> void:
	velocity *= friction

# Move and rotate the rocket
func move_and_rotate(delta: float) -> void:
	position += velocity * delta
