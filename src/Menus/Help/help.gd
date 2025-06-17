extends Control

@onready var help_title: Label = $ScrollContainer/Text/HelpTitle
@onready var help: Label = $ScrollContainer/Text/Help
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var is_switching: bool = false
var page: int = 0

var headings: Array[String] = [
	"How to play:",
	"Controls:",
	"Credits:",
]
var content: Array[String] = [
	"""Move the paddle around to bounce the ball and destroy the bricks.
	To finish a level, you must destroy all of them. Bricks with white outlines need 2 hits to be destroyed. Black ones are indestructible and do not count towards your goal.
	You might also gain a powerup, which may give you a buff or a debuff, depending on your luck.""",

	"""Gameplay:
	A or Left arrow - Move left
	d or Right arrow - Move right
	Esc - Back to menu
	R - Reset the level
	P - Pause or Unpause the game

	Editor shortcuts:
	LCTRL + S - Save
	LCTRL + L - Load
	LCTRL + N - New
	LCTRL + P - Test the level
	LCTRL + Z - Undo
	LCTRL + Y - Redo""",

	"""game developed by sparrowworks

	programming: sp4r0w
	testing: vargadot

	Graphics made by Kenney and SP4R0W

	Music made by Benjamin Burnes
	Sound effects made by Kenney"""
]

func _ready() -> void:
	help_title.text = headings[page]
	help.text = content[page]

func _on_switch_button_pressed() -> void:
	Globals.button_click.play()

	if is_switching:
		return

	is_switching = true
	page = (page + 1) % content.size()

	animation_player.play("FadeIn")
	await animation_player.animation_finished

	help_title.text = headings[page]
	help.text = content[page]

	animation_player.play("FadeOut")
	await animation_player.animation_finished

	is_switching = false

func _on_back_button_pressed() -> void:
	Globals.go_to_with_fade("res://src/Menus/MainMenu/MainMenu.tscn")
