extends Node

var menu_theme: AudioStreamPlayer
var button_click: AudioStreamPlayer

var master_volume: float = 100.0
var music_volume: float = 100.0
var sfx_volume: float = 100.0

var high_score: int = 0

var end_time: int
var end_score: int

var is_mouse_left_held: bool = false
var is_mouse_right_held: bool = false

var transition: FadeScreen

func go_to_with_fade(scene: String, data: Dictionary[String, Variant] = {}) -> void:
	transition = Composer.setup_load_screen("res://src/Composer/LoadingScreens/Fade/FadeScreen.tscn")

	button_click.play()
	if transition:
		await transition.finished_fade_in
		if data != {}:
			Composer.load_scene(scene, data)
		else:
			Composer.load_scene(scene)
#
