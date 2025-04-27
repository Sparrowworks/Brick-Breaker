extends Control

@onready var button_click: AudioStreamPlayer = $ButtonClick
@onready var menu_theme: AudioStreamPlayer = $MenuTheme

func _ready() -> void:
	randomize()

	Globals.menu_theme = menu_theme
	Globals.button_click = button_click

	Composer.root = self
	Composer.load_scene("res://src/Menus/MainMenu/MainMenu.tscn")
