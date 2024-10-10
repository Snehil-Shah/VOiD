extends AnimatedSprite2D  # or any other appropriate node type

func _ready():
	# Set the sprite position to the bottom right corner of the viewport
	update_sprite_position()

func _process(delta):
	# If you want it to stay at the same position in case of any size change
	update_sprite_position()

func update_sprite_position():
	var viewport_size = get_viewport_rect().size
	self.position = viewport_size / 2
