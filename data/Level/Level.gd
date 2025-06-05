class_name Level extends Resource

static var accepted_versions: Array[String] = [
	ProjectSettings.get_setting("application/config/version")
]

@export var level_name: String = ""
@export var level_author: String = ""
@export var level_path: String = ""
@export var game_ver: String = ""

@export var level_dict: Dictionary[Vector2i, BrickLevelType]

func _ready() -> void:
	game_ver = ProjectSettings.get_setting("application/config/version")

func save(modified_resource: Level) -> int:
	if modified_resource.level_name.is_empty():
		return 1

	if not modified_resource.level_name.is_valid_filename():
		return 1

	if modified_resource.level_author.is_empty():
		return 2

	if modified_resource.level_dict.is_empty():
		return 3

	# Ensure the level has bricks and not just immune ones.
	var is_immune_only: bool = true
	for value: BrickLevelType in modified_resource.level_dict.values():
		if value.type_id != 3:
			is_immune_only = false
			break

	if is_immune_only:
		return 3

	var file: FileAccess
	if OS.get_name() != "Web":
		file = FileAccess.open("user://Levels/" + modified_resource.level_name + ".lvl", FileAccess.WRITE)
		print(FileAccess.get_open_error())
		if file == null:
			file.close()
			return FileAccess.get_open_error()

	if self.level_path != "":
		DirAccess.remove_absolute(self.level_path)

	self.level_name = modified_resource.level_name
	self.level_author = modified_resource.level_author
	self.level_dict = modified_resource.level_dict.duplicate(true)
	self.level_path = "user://Levels/" + self.level_name + ".lvl"
	self.game_ver = ProjectSettings.get_setting("application/config/version")

	# Do not create a file on HTML build
	if OS.get_name() != "Web":
		var level_data: Dictionary = {
			"name": self.level_name,
			"author": self.level_author,
			"data": self.level_dict,
			"path": self.level_path,
			"ver": self.game_ver
		}

		file.store_var(level_data, true)
		file.close()

	return 0

func is_equal(compared_level: Level) -> bool:
	# Find any differences between this Level and the compared one
	if compared_level.level_name != self.level_name:
		return false

	if compared_level.level_author != self.level_author:
		return false

	if compared_level.level_dict.keys().size() != self.level_dict.keys().size():
		return false
	else:
		for key: Vector2i in self.level_dict.keys():
			if compared_level.level_dict.has(key):
				var org_value: BrickLevelType = self.level_dict[key]
				var new_value: BrickLevelType = compared_level.level_dict[key]

				if org_value.button_id != new_value.button_id or org_value.type_id != new_value.type_id:
					return false
			else:
				return false

	return true
