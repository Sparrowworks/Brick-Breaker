class_name LevelButtonCustom extends Panel

signal play_pressed(button: LevelButtonCustom)

@export var level_id: int = 0

@onready var level_title: Label = $HBoxContainer/Title
@onready var level_author: Label = $HBoxContainer/Author

var title: String:
	set(val):
		title = val.replace("_", " ")

		if level_title != null:
			level_title.text = title

var author: String:
	set(val):
		author = val

		if level_author != null:
			level_author.text = author

func _ready() -> void:
	level_title.text = title
	level_author.text = author

func _on_play_button_pressed() -> void:
	Globals.button_click.play()
	play_pressed.emit(self)
