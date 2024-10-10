extends Sprite2D

var speed = 400  # Speed at which the rocket moves to the right
var up_down_speed = 300  # Speed for vertical movement
@onready var camera = get_node("/root/Main_asteroid/Camera2D")

func _ready():
	# Place the rocket at the left side of the screen
	var viewport_size = get_viewport_rect().size
	camera.position = Vector2(viewport_size.x / 2, viewport_size.y / 2)
	position.y = viewport_size.y * 0.5
	position.x = viewport_size.x * 0.1  # Set the rocket at 10% of the screen width (adjust as needed)

func _process(delta):
	# Move the rocket towards the right at a constant speed
	position.x += speed * delta
	camera.position.x += speed * delta

	# Vertical movement (up/down) using left and right keys
	if Input.is_action_pressed("ui_left"):  # Use the left arrow key to move up
		position.y -= up_down_speed * delta
	elif Input.is_action_pressed("ui_right"):  # Use the right arrow key to move down
		position.y += up_down_speed * delta
		
	var viewport_rect = get_viewport_rect()
	position.y = clamp(position.y, 0, viewport_rect.size.y - texture.get_size().y)  # Prevent from moving out of top and bottom bounds
