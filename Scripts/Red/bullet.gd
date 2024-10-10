extends RigidBody2D

var speed = 750
var direction = Vector2.RIGHT
@onready var sprite = $Sprite2D
@onready var exploder = $AnimatedSprite2D

func _ready():
	GlobalAudio.audio_player.stream = load("res://assets/Music/527857-Laser_01.wav")
	GlobalAudio.audio_player.play()
	add_to_group("player_bullets")
	linear_velocity = direction * speed

func set_direction(new_direction: Vector2):
	direction = new_direction.normalized()
	linear_velocity = direction * speed

func _on_RigidBody2D_body_entered(body):
	linear_velocity = Vector2(0,0)
	sprite.hide()
	exploder.play("explode")
	var target_body = find_character_body(body)
	
	if target_body and target_body.has_method("take_damage"):
		target_body.take_damage()  # Deal damage to the body on collision
	else:
		GlobalAudio.audio_player3.stream = load("res://assets/Music/1147094.audio-Dsgn_8_Bit_Explosion_01.wav")
		GlobalAudio.audio_player3.play()
	
	set_physics_process(false)
	await get_tree().create_timer(0.35).timeout
	
	queue_free()  # Destroy the bullet after the collision

func find_character_body(node):
	# Check if the node itself is a CharacterBody2D
	if node is CharacterBody2D:
		return node
	
	# If not, check its children
	for child in node.get_children():
		if child is CharacterBody2D:
			return child
	# If no CharacterBody2D is found, return null
	return null

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
