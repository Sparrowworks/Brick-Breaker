class_name EditorLoad extends Control

signal level_edit_pressed(level: Level)
signal back_pressed()

const EDITOR_LOAD_FILE = preload("res://src/Menus/Editor/EditorLoadFile/EditorLoadFile.tscn")

@onready var button_container: VBoxContainer = %ButtonContainer
@onready var no_files: Label = %NoFiles
@onready var editor_error: EditorError = $EditorError

func _ready() -> void:
	editor_error.hide()

func initialize() -> void:
	var files: Array = load_files()
	if files.size() == 0:
		no_files.show()
		return

	no_files.hide()
	create_buttons(files)

func load_files() -> Array:
	var dir: DirAccess = DirAccess.open("user://Levels")
	if dir == null:
		print("Error opening directory user://Levels/ with error code: " + str(DirAccess.get_open_error()))
		return []

	var files: PackedStringArray = dir.get_files()
	for idx in range(files.size()-1, -1, -1):
		if not files[idx].ends_with(".lvl"):
			files.remove_at(idx)

	return files

func load_file(path: String, buttons_found: Array[String]) -> Level:
	var file: FileAccess = FileAccess.open("user://Levels/" + path, FileAccess.READ)
	if file == null:
		print("Error opening file: " + path + " with error code: " + str(FileAccess.get_open_error()))
		return null

	var loaded_data: Variant = file.get_var(true)
	file.close()

	if not loaded_data is Dictionary:
		return null

	var data: Dictionary = loaded_data as Dictionary

	if not data.has("name") or not data.has("data") or not data.has("author"):
		return null

	if buttons_found.has(data["name"]):
		buttons_found.erase(data["name"])
		return null

	var level_data: Level = Level.new()
	level_data.level_name = data.get("name", "My level")
	level_data.level_author = data.get("author", "Anon")
	level_data.level_path = "user://Levels/" + path
	level_data.game_ver = data.get("ver", "")

	var level_dict: Dictionary[Vector2i, BrickLevelType]
	for key: Vector2i in data["data"].keys():
		if data["data"][key] is BrickLevelType:
			level_dict[key] = data["data"][key] as BrickLevelType
		else:
			level_data.free()
			continue

	level_data.level_dict = level_dict

	return level_data

func create_buttons(files: PackedStringArray) -> void:
	var buttons_found: Array[String] = []

	for child in button_container.get_children():
		if child.name == "NoFiles":
			continue

		buttons_found.append(child.name)

	for path in files:
		var button_data: Level = load_file(path, buttons_found)

		var file_button: EditorLoadFile = EDITOR_LOAD_FILE.instantiate()
		file_button.level_data = button_data

		file_button.edit_pressed.connect(_on_file_edit_pressed)
		file_button.del_pressed.connect(_on_file_del_pressed)

		button_container.add_child(file_button)

	for button_name in buttons_found:
		button_container.get_node(button_name).queue_free()

	if button_container.get_child_count() == 1:
		no_files.show()

func _on_file_edit_pressed(button: EditorLoadFile) -> void:
	if not Level.accepted_versions.has(button.level_data.game_ver):
		editor_error.show_error("Invalid File", "The file you are trying to open is not supported in this game version.")
		await editor_error.btn_pressed
		editor_error.hide()
		return

	level_edit_pressed.emit(button.level_data)

func _on_file_del_pressed(button: EditorLoadFile) -> void:
	editor_error.show_error("Confirm Delete", "Are you sure you want to remove this level? It cannot be undone.", "Yes", true)
	await editor_error.btn_pressed
	editor_error.hide()

	if editor_error.last_btn_pressed == "No":
		return

	var error: Error = DirAccess.remove_absolute(button.level_data.level_path)
	if error != OK:
		editor_error.show_error("Error", "The level couldn't be deleted. Error code: " + str(error))
		await editor_error.btn_pressed
		editor_error.hide()
		return

	button.queue_free()

func _on_back_button_pressed() -> void:
	Globals.button_click.play()
	back_pressed.emit()

func _on_folder_button_pressed() -> void:
	Globals.button_click.play()
	OS.shell_show_in_file_manager(OS.get_user_data_dir() + "/Levels")
