extends Button

func _on_Button_pressed():
	# Play the sound when the button is pressed
	GlobalAudio.audio_player.stream = load("res://assets/Music/button-confirmation_C#_major.wav")
	GlobalAudio.audio_player.play()
