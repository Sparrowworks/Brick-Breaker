class_name EditorTypeButton extends Control

signal type_pressed(button: EditorTypeButton)

@export_enum("Normal: 1", "Armoured: 2", "Immune: 3") var type_id: int

@onready var arrow: TextureRect = $VBoxContainer/Arrow
@onready var button_text: Label = $VBoxContainer/Button/ButtonText


func _ready() -> void:
	# A button that selects which type of brick we want to add
	arrow.hide()
	match type_id:
		1:
			button_text.text = "Normal"
		2:
			button_text.text = "Armoured"
		3:
			button_text.text = "Immune"

func _on_button_pressed() -> void:
	Globals.button_click.play()
	type_pressed.emit(self)
