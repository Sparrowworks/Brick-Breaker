class_name LevelButtonOfficial extends TextureButton

signal level_pressed(button: LevelButtonOfficial)

@export var level_id: int = 0

@export var level_title: String = "0":
	set(val):
		level_title = val

		if level_text != null:
			level_text.text = level_title

@onready var level_text: Label = $LevelText

func _ready() -> void:
	level_text.text = level_title

func _on_pressed() -> void:
	Globals.button_click.play()
	level_pressed.emit(self)
