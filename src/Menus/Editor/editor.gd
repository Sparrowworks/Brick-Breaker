class_name Editor extends Control

signal type_changed(type_id: int)

@onready var editor_start: EditorStart = $EditorStart
@onready var editor_error: EditorError = $EditorError
@onready var editor_load: EditorLoad = $EditorLoad

@onready var brick_panel: Panel = $BrickPanel
@onready var info_panel: Panel = $InfoPanel
@onready var file_panel: Panel = $FilePanel
@onready var bricks: GridContainer = $Bricks

@onready var path_text: Label = %PathText
@onready var normal_text: Label = %NormalText
@onready var armour_text: Label = %ArmourText
@onready var immune_text: Label = %ImmuneText
@onready var name_edit: LineEdit = %NameEdit
@onready var author_edit: LineEdit = %AuthorEdit
@onready var auto_save: CheckBox = $InfoPanel/VBoxContainer/Save/Control/AutoSave

@onready var blue_brick: EditorBrickButton = $BrickPanel/VBoxContainer/BrickButtons/BlueBrick
@onready var green_brick: EditorBrickButton = $BrickPanel/VBoxContainer/BrickButtons/GreenBrick
@onready var grey_brick: EditorBrickButton = $BrickPanel/VBoxContainer/BrickButtons/GreyBrick
@onready var orange_brick: EditorBrickButton = $BrickPanel/VBoxContainer/BrickButtons/OrangeBrick
@onready var red_brick: EditorBrickButton = $BrickPanel/VBoxContainer/BrickButtons/RedBrick
@onready var yellow_brick: EditorBrickButton = $BrickPanel/VBoxContainer/BrickButtons/YellowBrick

@onready var type_normal: EditorTypeButton = $BrickPanel/VBoxContainer/TypeButton/TypeNormal
@onready var type_armoured: EditorTypeButton = $BrickPanel/VBoxContainer/TypeButton/TypeArmoured
@onready var type_immune: EditorTypeButton = $BrickPanel/VBoxContainer/TypeButton/TypeImmune

const BLACK_BRICK = preload("res://assets/images/Game/blackBrick.png")

enum SAVE_ERRORS {
	OK = 0,
	NAME = 1,
	AUTH = 2,
	LEVEL = 3
}

var selected_brick_color: EditorBrickButton
var selected_brick_type: EditorTypeButton

var main_resource: Level = null
var modified_resource: Level = null

var is_auto_save: bool = false
var is_unsaved: bool = false

var is_html: bool = false

var counters: Dictionary[int, int] = {
	1:0,
	2:0,
	3:0,
}

var brick_dict: Dictionary[Vector2i, EditorLevelButton] = {

}

var undo_tasks: Array[Task] = []
var redo_tasks: Array[Task] = []

var current_task: Task

func _ready() -> void:
	if OS.get_name() == "Web":
		is_html = true

	if not Globals.menu_theme.playing:
		Globals.menu_theme.play()

	# Set the editor to default values
	selected_brick_color = blue_brick
	selected_brick_type = type_normal

	setup_bricks()

	blue_brick.arrow.show()
	type_normal.arrow.show()
	hide_editor()

	editor_start.show()
	editor_error.hide()
	editor_load.hide()

	# If we're returning from a testing session, draw the tested level
	if has_meta("editor_data"):
		var editor_test_data: Level = get_meta("editor_data", Level.new())
		_on_editor_load_level_edit_pressed(editor_test_data)

		editor_start.hide()
		show_editor()

func setup_bricks() -> void:
	var x: int = 0
	var y: int = 0

	# Set up the brick dictionary
	for brick in bricks.get_children():
		brick.brick_id = Vector2i(x,y)
		brick_dict[Vector2i(x,y)] = brick
		x += 1
		if x > bricks.columns-1:
			y += 1
			x = 0

func show_editor() -> void:
	brick_panel.show()
	info_panel.show()
	file_panel.show()
	bricks.show()

	# Disable loading files for HTML build
	if is_html:
		$FilePanel/VBoxContainer/Buttons/LoadButton.hide()

func hide_editor() -> void:
	brick_panel.hide()
	info_panel.hide()
	file_panel.hide()
	bricks.hide()

func reset_editor() -> void:
	# Set the editor to default values and reset the UI
	current_task = null
	undo_tasks.clear()
	redo_tasks.clear()

	is_unsaved = false
	is_auto_save = false
	auto_save.button_pressed = false

	selected_brick_color.arrow.hide()
	selected_brick_type.arrow.hide()

	selected_brick_color = blue_brick
	selected_brick_type = type_normal

	type_changed.emit(selected_brick_type.type_id)

	blue_brick.arrow.show()
	type_normal.arrow.show()

	name_edit.text = ""
	author_edit.text = ""
	path_text.text = "(unsaved) file name: my_level.lvl"

	counters[1] = 0
	counters[2] = 0
	counters[3] = 0

	for key: Vector2i in modified_resource.level_dict.keys():
		var brick: EditorLevelButton = brick_dict[key]

		brick.type_id = 0
		brick.texture_normal = BLACK_BRICK
		brick.self_modulate = Color.from_rgba8(255, 255, 255, 96)

	update_counters()

func update_counters() -> void:
	# Update the brick counters
	normal_text.text = "Normal: " + str(counters[1])
	armour_text.text = "Armoured: " + str(counters[2])
	immune_text.text = "Immune: " + str(counters[3])

func compare_states() -> void:
	# Compare if the file has unsaved changes with the previously saved version
	if not is_html:
		if not FileAccess.file_exists("user://Levels/" + modified_resource.level_name + ".lvl"):
			is_unsaved = true
			if not path_text.text.begins_with("(unsaved) "):
				path_text.text = path_text.text.insert(0, "(unsaved) ")

			return

	if main_resource.is_equal(modified_resource):
		is_unsaved = false
		path_text.text = path_text.text.trim_prefix("(unsaved) ")
	else:
		is_unsaved = true
		if not path_text.text.begins_with("(unsaved) "):
			path_text.text = path_text.text.insert(0, "(unsaved) ")

func check_for_unsaved() -> bool:
	# Allow saving the file before leaving or canceling the operation and going back to Editor
	if is_unsaved:
		editor_error.show_error("Unsaved File", "The file you are editing has unsaved changes. Would you like to save now?", "Yes", true, true)
		await editor_error.btn_pressed
		editor_error.hide()

		if editor_error.last_btn_pressed == "Yes":
			var has_saved: bool = await save()
			if has_saved:
				return true
			else:
				return false
		elif editor_error.last_btn_pressed == "Cancel":
			return false

	return true

func save(quiet: bool = false) -> bool:
	# Do not create a file on HTML build
	if not is_html:
		if FileAccess.file_exists("user://Levels/" + modified_resource.level_name + ".lvl") and main_resource.level_name != modified_resource.level_name:
			editor_error.show_error("File Already Exists", "A level with this name already exists. Do you want to override it?", "Yes", true)
			await editor_error.btn_pressed
			editor_error.hide()

			if editor_error.last_btn_pressed == "No":
				return false

	# Save the level
	var error: int = main_resource.save(modified_resource)

	if not quiet:
		match error:
			SAVE_ERRORS.OK:
				compare_states()
			SAVE_ERRORS.NAME:
				editor_error.show_error("Level Name Error", "The name for the level is invalid. Please note that the name for the level can be max. 10 characters long, cannot be empty and must be a valid name for the file path.")
				await editor_error.btn_pressed
				editor_error.hide()
				return false
			SAVE_ERRORS.AUTH:
				editor_error.show_error("Author Name Error", "The name for the author is invalid. Please note that the name for the author can be max. 10 characters long and cannot be empty.")
				await editor_error.btn_pressed
				editor_error.hide()
				return false
			SAVE_ERRORS.LEVEL:
				editor_error.show_error("Empty Level Error", "The level cannot be empty and must include at least one block excluding the immune block type.")
				await editor_error.btn_pressed
				editor_error.hide()
				return false
			_:
				editor_error.show_error("File Error", "The file couldn't be saved due to an error with code: " + str(error))
				await editor_error.btn_pressed
				editor_error.hide()
				return false
	else:
		if error == SAVE_ERRORS.OK:
			compare_states()
			return true

	return true

func undo() -> void:
	# Undo the previous action
	if current_task != null:
		if not current_task.before.is_empty() or not current_task.after.is_empty():
			undo_tasks.append(current_task)

		Globals.is_mouse_left_held = false
		Globals.is_mouse_right_held = false
		current_task = null

	if undo_tasks.size() == 0:
		return

	# Allow the undone task to be redone
	var latest_task: Task = undo_tasks.pop_back()
	redo_tasks.append(latest_task)

	# Undo each operation on bricks
	for button: EditorLevelButton in latest_task.after:
		var old_type: BrickLevelType = latest_task.before[button]
		if old_type.type_id == 0:
			_on_editor_level_brick_right_pressed(button, true)
		else:
			_on_editor_brick_pressed(get_color_button(old_type.button_id))
			_on_editor_button_type_pressed(get_type_button(old_type.type_id))

			_on_editor_level_brick_left_pressed(button, true)


func redo() -> void:
	# Redo the previous action
	if redo_tasks.size() == 0:
		return

	# Allow the redone task to be undone
	var latest_task: Task = redo_tasks.pop_back()
	undo_tasks.append(latest_task)

	# Redo each operation on bricks
	for button: EditorLevelButton in latest_task.before:
		var old_type: BrickLevelType = latest_task.after[button]
		if old_type.type_id == 0:
			_on_editor_level_brick_right_pressed(button, true)
		else:
			_on_editor_brick_pressed(get_color_button(old_type.button_id))
			_on_editor_button_type_pressed(get_type_button(old_type.type_id))

			_on_editor_level_brick_left_pressed(button, true)

func _input(event: InputEvent) -> void:
	if editor_start.visible or editor_load.visible or editor_error.visible:
		return

	if event is InputEventMouseButton:
		# If we're holding down mouse button, start tracking the operations on bricks
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_LEFT:
				# Create a task to undo if it doesn't exist yet
				if current_task == null:
					current_task = Task.new()

				Globals.is_mouse_left_held = true

			if event.button_index == MOUSE_BUTTON_RIGHT:
				# Create a task to undo if it doesn't exist yet
				if current_task == null:
					current_task = Task.new()

				Globals.is_mouse_right_held = true
		else:
			# If we're not holding down any mouse buttons, stop tracking the operations on bricks
			if event.button_index == MOUSE_BUTTON_LEFT:
				if current_task != null and not Globals.is_mouse_right_held:
					# Add the task to undo only if its not empty
					if not current_task.before.is_empty() or not current_task.after.is_empty():
						undo_tasks.append(current_task)

					current_task = null

				Globals.is_mouse_left_held = false

			if event.button_index == MOUSE_BUTTON_RIGHT:
				if current_task != null and not Globals.is_mouse_left_held:
					# Add the task to undo only if its not empty
					if not current_task.before.is_empty() or not current_task.after.is_empty():
						undo_tasks.append(current_task)

					current_task = null

				Globals.is_mouse_right_held = false

	if Input.is_action_just_pressed("menu"):
		_on_editor_start_menu_selected()

	if Input.is_action_just_pressed("editor_save"):
		save()

	if Input.is_action_just_pressed("editor_new"):
		_on_new_button_pressed()

	if Input.is_action_just_pressed("editor_load"):
		_on_load_button_pressed()

	if Input.is_action_just_pressed("editor_play"):
		_on_play_button_pressed()

	if Input.is_action_pressed("editor_undo"):
		undo()

	if Input.is_action_pressed("editor_redo"):
		redo()

func _on_editor_start_new_file_selected() -> void:
	current_task = null
	undo_tasks.clear()
	redo_tasks.clear()

	is_unsaved = true

	main_resource = Level.new()
	modified_resource = main_resource.duplicate(true)

	editor_start.hide()
	show_editor()

func _on_editor_start_load_file_selected() -> void:
	editor_start.hide()

	editor_load.initialize()
	editor_load.show()

func _on_editor_load_level_edit_pressed(level: Level) -> void:
	# Draw the level that was playtested
	current_task = null
	undo_tasks.clear()
	redo_tasks.clear()

	is_unsaved = false
	main_resource = level.duplicate(true)
	modified_resource = level

	editor_load.hide()

	name_edit.text = modified_resource.level_name.replace("_", " ")
	author_edit.text = modified_resource.level_author
	path_text.text = "file name: " + modified_resource.level_path.trim_prefix("user://Levels/")

	for key: Vector2i in modified_resource.level_dict.keys():
		var resource: BrickLevelType = modified_resource.level_dict[key]
		var brick: EditorLevelButton = brick_dict[key]

		if resource.type_id == 3:
			brick.texture_normal = BLACK_BRICK
			brick.self_modulate = Color.WHITE
		else:
			brick.texture_normal = get_color_texture(resource.button_id, resource.type_id)
			brick.self_modulate = Color.WHITE

		brick.type_id = resource.type_id

		counters[brick.type_id] += 1
		update_counters()

	show_editor()

func get_color_texture(color: int, type: int) -> Texture2D:
	match color:
		1:
			if type == 1:
				return blue_brick.button_texture
			else:
				return blue_brick.armoured_button_texture
		2:
			if type == 1:
				return green_brick.button_texture
			else:
				return green_brick.armoured_button_texture
		3:
			if type == 1:
				return grey_brick.button_texture
			else:
				return grey_brick.armoured_button_texture
		4:
			if type == 1:
				return orange_brick.button_texture
			else:
				return orange_brick.armoured_button_texture
		5:
			if type == 1:
				return red_brick.button_texture
			else:
				return red_brick.armoured_button_texture
		6:
			if type == 1:
				return yellow_brick.button_texture
			else:
				return yellow_brick.armoured_button_texture

	return null

func get_color_button(color: int) -> EditorBrickButton:
	match color:
		1:
			return blue_brick
		2:
			return green_brick
		3:
			return grey_brick
		4:
			return orange_brick
		5:
			return red_brick
		6:
			return yellow_brick

	return null

func get_type_button(type: int) -> EditorTypeButton:
	match type:
		1:
			return type_normal
		2:
			return type_armoured
		3:
			return type_immune

	return null

func _on_editor_brick_pressed(button: EditorBrickButton) -> void:
	# Select the new color of brick
	if selected_brick_color == button:
		return

	if selected_brick_color != null:
		selected_brick_color.arrow.hide()

	selected_brick_color = button
	selected_brick_color.arrow.show()

func _on_editor_button_type_pressed(button: EditorTypeButton) -> void:
	# Select the new type of brick
	if selected_brick_type == button:
		return

	if selected_brick_type != null:
		selected_brick_type.arrow.hide()

	selected_brick_type = button
	selected_brick_type.arrow.show()

	type_changed.emit(selected_brick_type.type_id)

func _on_editor_level_brick_left_pressed(button: EditorLevelButton, is_undo: bool = false) -> void:
	# Add the brick to the level with the selected color and type
	if (button.type_id != selected_brick_type.type_id) or (button.texture_normal != selected_brick_color.texture_button.texture_normal and selected_brick_type.type_id != 3):
		if not is_undo:
			# Handle undo actions
			if button.type_id == 0:
				var empty_type: BrickLevelType = BrickLevelType.new()
				empty_type.type_id = 0
				empty_type.button_id = 0
				current_task.before[button] = empty_type
			else:
				current_task.before[button] = modified_resource.level_dict[button.brick_id].duplicate()

		# Draw the immune block if selected
		if selected_brick_type.type_id == 3:
			button.texture_normal = BLACK_BRICK
			button.self_modulate = Color.WHITE
		else:
			button.texture_normal = selected_brick_color.texture_button.texture_normal
			button.self_modulate = Color.WHITE

		# Update the counters if the type of the brick was different before
		if button.type_id > 0:
			counters[button.type_id] -= 1

		button.type_id = selected_brick_type.type_id

		counters[button.type_id] += 1
		update_counters()

		# Add the brick to the Level resource
		var brick_type: BrickLevelType = BrickLevelType.new()

		brick_type.button_id = selected_brick_color.button_id
		brick_type.type_id = selected_brick_type.type_id

		modified_resource.level_dict[button.brick_id] = brick_type

		if not is_undo:
			current_task.after[button] = modified_resource.level_dict[button.brick_id].duplicate()

	if is_auto_save:
		save(true)
	else:
		compare_states()

func _on_editor_level_brick_right_pressed(button: EditorLevelButton, is_undo: bool = false) -> void:
	# Clear the brick and remove it from the level
	button.texture_normal = BLACK_BRICK
	button.self_modulate = Color.from_rgba8(255, 255, 255, 96)

	if button.type_id > 0:
		if not is_undo:
			current_task.before[button] = modified_resource.level_dict[button.brick_id].duplicate()

		# Update the counters
		counters[button.type_id] -= 1
		update_counters()

		# Remove the brick from the Level resource
		button.type_id = 0
		modified_resource.level_dict.erase(button.brick_id)

		# Handle undo actions
		if not is_undo:
			var empty_type: BrickLevelType = BrickLevelType.new()
			empty_type.type_id = 0
			empty_type.button_id = 0
			current_task.after[button] = empty_type

		if is_auto_save:
			save(true)
		else:
			compare_states()

func _on_clear_button_pressed() -> void:
	# Reset the bricks back to empty level
	current_task = Task.new()

	Globals.button_click.play()

	for brick: EditorLevelButton in bricks.get_children():
		if brick.type_id != 0:
			current_task.before[brick] = modified_resource.level_dict[brick.brick_id].duplicate()

			var empty_type: BrickLevelType = BrickLevelType.new()
			empty_type.type_id = 0
			empty_type.button_id = 0
			current_task.after[brick] = empty_type

		brick.texture_normal = BLACK_BRICK
		brick.self_modulate = Color.from_rgba8(255, 255, 255, 96)
		brick.type_id = 0

	undo_tasks.append(current_task)
	current_task = null

	modified_resource.level_dict.clear()

	counters[1] = 0
	counters[2] = 0
	counters[3] = 0

	update_counters()

	compare_states()

func _on_name_edit_text_changed(new_text: String) -> void:
	modified_resource.level_name = new_text.to_lower().strip_edges().replace(" ", "_")
	path_text.text = "file name: " + modified_resource.level_name + ".lvl"

	if is_auto_save:
		save(true)
	else:
		compare_states()

func _on_name_edit_text_submitted(_new_text: String) -> void:
	name_edit.release_focus()

func _on_author_edit_text_changed(new_text: String) -> void:
	modified_resource.level_author = new_text.to_lower().strip_edges()

	if is_auto_save:
		save(true)
	else:
		compare_states()

func _on_author_edit_text_submitted(_new_text: String) -> void:
	author_edit.release_focus()

func _on_save_button_pressed() -> void:
	Globals.button_click.play()
	save()

func _on_check_box_toggled(toggled_on: bool) -> void:
	is_auto_save = toggled_on

func _on_play_button_pressed() -> void:
	Globals.button_click.play()

	# Check if we're not leaving an unsaved file
	var confirmed: bool = await check_for_unsaved()
	if not confirmed or editor_error.last_btn_pressed == "No":
		return

	# Playtest the edited level
	Globals.menu_theme.stop()
	Globals.go_to_with_fade("res://src/Game/Game.tscn", {"level_data": main_resource, "editor_launch": true})

func _on_load_button_pressed() -> void:
	Globals.button_click.play()

	# Check if we're not leaving an unsaved file
	var confirmed: bool = await check_for_unsaved()
	if not confirmed:
		return

	# Show the load menu
	hide_editor()
	reset_editor()

	editor_load.initialize()
	editor_load.show()

func _on_new_button_pressed() -> void:
	Globals.button_click.play()

	# Check if we're not leaving an unsaved file
	var confirmed: bool = await check_for_unsaved()
	if not confirmed:
		return

	# Create a new level and reset the editor
	reset_editor()

	main_resource = Level.new()
	modified_resource = main_resource.duplicate(true)

	editor_start.hide()
	show_editor()

func _on_editor_start_menu_selected() -> void:
	# Check if we're not leaving an unsaved file
	var confirmed: bool = await check_for_unsaved()
	if not confirmed:
		return

	Globals.go_to_with_fade("res://src/Menus/MainMenu/MainMenu.tscn")

func _on_editor_load_back_pressed() -> void:
	Globals.button_click.play()
	editor_load.hide()
	editor_start.show()
