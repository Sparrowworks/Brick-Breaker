class_name EditorBrickButton extends Control

signal brick_pressed(button: EditorBrickButton)

@export var button_texture: CompressedTexture2D
@export var armoured_button_texture: CompressedTexture2D
@export_enum("Blue: 1", "Green: 2", "Grey: 3", "Orange: 4", "Red: 5", "Yellow: 6", "Black: 7") var button_id: int

@onready var arrow: TextureRect = $VBoxContainer/Arrow
@onready var texture_button: TextureButton = $VBoxContainer/TextureButton

func _ready() -> void:
	arrow.hide()
	texture_button.texture_normal = button_texture

func _on_texture_button_pressed() -> void:
	Globals.button_click.play()
	brick_pressed.emit(self)

func _on_editor_type_changed(type_id: int) -> void:
	if type_id == 1 or type_id == 3:
		texture_button.texture_normal = button_texture
	elif type_id == 2:
		texture_button.texture_normal = armoured_button_texture
