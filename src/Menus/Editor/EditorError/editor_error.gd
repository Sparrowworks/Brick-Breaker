class_name EditorError extends Control

signal btn_pressed()

@onready var error: AudioStreamPlayer = $Error

@onready var title: Label = $Panel/VBoxContainer/Title
@onready var content: Label = $Panel/VBoxContainer/Content

@onready var no_button: TextureButton = $Panel/VBoxContainer/Buttons/NoButton
@onready var cancel_button: TextureButton = $Panel/VBoxContainer/Buttons/CancelButton
@onready var ok_label: Label = $Panel/VBoxContainer/Buttons/OkButton/OkLabel
@onready var no_label: Label = $Panel/VBoxContainer/Buttons/NoButton/NoLabel

var last_btn_pressed: String = ""

func show_error(title_txt: String, content_txt: String, ok_text: String = "ok", show_no: bool = false, show_cancel: bool = false) -> void:
	error.play()
	title.text = title_txt
	content.text = content_txt

	ok_label.text = ok_text
	no_button.visible = show_no
	cancel_button.visible = show_cancel

	show()

func hide_error() -> void:
	hide()

func _on_ok_button_pressed() -> void:
	Globals.button_click.play()
	last_btn_pressed = ok_label.text
	btn_pressed.emit()

func _on_no_button_pressed() -> void:
	Globals.button_click.play()
	last_btn_pressed = no_label.text
	btn_pressed.emit()

func _on_cancel_button_pressed() -> void:
	Globals.button_click.play()
	last_btn_pressed = "Cancel"
	btn_pressed.emit()
