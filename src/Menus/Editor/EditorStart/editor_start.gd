class_name EditorStart extends Control

signal new_file_selected()
signal load_file_selected()
signal menu_selected()

func _ready() -> void:
	# Disable the loading option for HTML build
	if OS.get_name() == "Web":
		$Panel/VBoxContainer/Buttons/LoadButton.hide()

func _on_new_button_pressed() -> void:
	Globals.button_click.play()
	new_file_selected.emit()

func _on_load_button_pressed() -> void:
	Globals.button_click.play()
	load_file_selected.emit()

func _on_back_button_pressed() -> void:
	Globals.button_click.play()
	menu_selected.emit()
