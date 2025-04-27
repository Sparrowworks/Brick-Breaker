class_name EditorLoadFile extends Panel

signal edit_pressed(button: EditorLoadFile)
signal del_pressed(button: EditorLoadFile)

@onready var level_title: Label = $HBoxContainer/Title
@onready var level_author: Label = $HBoxContainer/Author

var level_data: Level:
	set(val):
		level_data = val

		if level_title != null:
			level_title.text = level_data.level_name.replace("_", " ")

		if level_author != null:
			level_author.text = level_data.level_author

func _ready() -> void:
	level_title.text = level_data.level_name.replace("_", " ")
	level_author.text = level_data.level_author

func _on_edit_button_pressed() -> void:
	Globals.button_click.play()
	edit_pressed.emit(self)

func _on_del_button_pressed() -> void:
	Globals.button_click.play()
	del_pressed.emit(self)
