extends Control

@onready var transition_tscn = preload("res://Scenes/transition.tscn")

func _on_PlayButton_pressed():
	var main_game_scene = load("res://Scenes/main.tscn")
	get_tree().change_scene_to_packed(main_game_scene)
	
func trigger_transition(new_scene):
	var transition_instance = transition_tscn.instantiate()
	get_tree().current_scene.add_child(transition_instance)

	var animated_sprite = transition_instance.get_node("AnimatedSprite2D")
	animated_sprite.play()

	# Connect to the animation_finished signal
	animated_sprite.animation_finished.connect(_on_transition_finished.bind(new_scene, transition_instance))

func _on_transition_finished(new_scene, transition_instance):
	get_tree().change_scene_to_packed(new_scene)
	transition_instance.queue_free()
