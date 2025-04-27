extends Control

@onready var version_text: Label = $VersionText

func _ready() -> void:
	if not Globals.menu_theme.playing:
		Globals.menu_theme.play()

	if OS.get_name() == "Web":
		$Buttons/QuitButton.hide()

	var version: String = ProjectSettings.get_setting("application/config/version") as String
	version_text.text = "v" + version

func _on_play_button_pressed() -> void:
	Globals.go_to_with_fade("res://src/Menus/LevelSelect/LevelSelect.tscn")


func _on_editor_button_pressed() -> void:
	Globals.go_to_with_fade("res://src/Menus/Editor/Editor.tscn")


func _on_options_button_pressed() -> void:
	Globals.go_to_with_fade("res://src/Menus/Settings/Settings.tscn")


func _on_help_button_pressed() -> void:
	Globals.go_to_with_fade("res://src/Menus/Help/Help.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()
