extends Control

signal has_initialized()

@onready var official_levels: GridContainer = %OfficialLevels
@onready var custom_levels: ScrollContainer = %CustomLevels
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var button_container: VBoxContainer = %ButtonContainer
@onready var no_files: Label = %NoFiles

const LEVEL_BUTTON_CUSTOM = preload("res://src/Menus/LevelSelect/LevelButtonCustom/LevelButtonCustom.tscn")

var official_list: Array[String] = [
	"res://src/Game/Levels/level_1.lvl",
	"res://src/Game/Levels/level_2.lvl",
	"res://src/Game/Levels/level_3.lvl",
	"res://src/Game/Levels/level_4.lvl",
	"res://src/Game/Levels/level_5.lvl",
	"res://src/Game/Levels/level_6.lvl",
	"res://src/Game/Levels/level_7.lvl",
	"res://src/Game/Levels/level_8.lvl",
	"res://src/Game/Levels/level_9.lvl",
	"res://src/Game/Levels/level_10.lvl",
]

var custom_list: Array[String] = [

]

var is_initialized: bool = false

func _ready() -> void:
	if not Globals.menu_theme.playing:
		Globals.menu_theme.play()

	if OS.get_name() == "Web":
		$Buttons/HBoxContainer/CustomButton.hide()
	else:
		initialize_custom_levels()

		if not is_initialized:
			await self.has_initialized

	var previous_list: Array = get_meta("list", [])

	# Show official levels if playing one; otherwise, show custom levels.
	if previous_list.is_empty() or previous_list == official_list:
		official_levels.show()
	else:
		custom_levels.show()

func initialize_custom_levels() -> void:
	load_files()
	if custom_list.size() == 0:
		no_files.show()
		return

	no_files.hide()
	create_buttons(custom_list)

func load_files() -> void:
	var dir: DirAccess = DirAccess.open("user://Levels")
	if dir == null:
		printerr("Error opening directory user://Levels/ with error code: " + str(DirAccess.get_open_error()))
		return

	var files: PackedStringArray = dir.get_files()

	for idx in range(files.size()-1, -1, -1):
		if not files[idx].ends_with(".lvl"):
			continue

		custom_list.append("user://Levels/" + files[idx])

func create_buttons(files: PackedStringArray) -> void:
	var buttons_found: Array[String] = []

	for child in button_container.get_children():
		if child.name == "NoFiles":
			continue

		buttons_found.append(child.name)

	for idx in range(0, files.size()):
		var path: String = files[idx]

		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		if file == null:
			print("Error opening file: " + path + " with error code: " + str(FileAccess.get_open_error()))
			continue

		# Check if we're loading an actual level or if something is corrupted or wrong, if yes, then we ignore that file, else we create a button for it
		var loaded_data: Variant = file.get_var(true)
		file.close()

		if not loaded_data is Dictionary:
			continue

		var data: Dictionary = loaded_data as Dictionary

		var ver: String = data.get("ver", "")
		if not Level.accepted_versions.has(ver):
			continue

		if not data.has("name") or not data.has("data") or not data.has("author"):
			continue

		if buttons_found.has(data["name"]):
			buttons_found.erase(data["name"])
			continue

		var level_button: LevelButtonCustom = LEVEL_BUTTON_CUSTOM.instantiate()

		level_button.title = data.get("name", "My level")
		level_button.author = data.get("author", "Anon")
		level_button.level_id = idx

		level_button.play_pressed.connect(_on_custom_play_pressed)

		button_container.add_child(level_button)

	for name in buttons_found:
		button_container.get_node(name).queue_free()

	if button_container.get_child_count() == 1:
		no_files.show()

	is_initialized = true
	has_initialized.emit()

func _on_level_button_official_level_pressed(button: LevelButtonOfficial) -> void:
	if animation_player.is_playing():
		return

	Globals.menu_theme.stop()
	Globals.go_to_with_fade("res://src/Game/Game.tscn", {"list": official_list.duplicate(), "id": button.level_id})

func _on_custom_play_pressed(button: LevelButtonCustom) -> void:
	if animation_player.is_playing():
		return

	Globals.menu_theme.stop()
	Globals.go_to_with_fade("res://src/Game/Game.tscn", {"list": custom_list.duplicate(), "id": button.level_id})

func _on_official_button_pressed() -> void:
	Globals.button_click.play()

	if official_levels.visible:
		return

	animation_player.play("Official")

func _on_custom_button_pressed() -> void:
	Globals.button_click.play()

	if custom_levels.visible:
		return

	animation_player.play("Custom")

func _on_menu_button_pressed() -> void:
	Globals.go_to_with_fade("res://src/Menus/MainMenu/MainMenu.tscn")
