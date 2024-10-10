extends Node

var audio_player: AudioStreamPlayer
var audio_player2: AudioStreamPlayer
var audio_player3: AudioStreamPlayer
var audio_player_low: AudioStreamPlayer
var music_player: AudioStreamPlayer


func _ready():
	audio_player = AudioStreamPlayer.new()
	audio_player2 = AudioStreamPlayer.new()
	audio_player3 = AudioStreamPlayer.new()
	audio_player_low = AudioStreamPlayer.new()
	music_player = AudioStreamPlayer.new()
	audio_player_low.volume_db = -3
	add_child(audio_player)
	add_child(audio_player2)
	add_child(audio_player3)
	add_child(audio_player_low)
	add_child(music_player)
	music_player.finished.connect(on_music_finished)
	
func on_music_finished():
	music_player.play()
