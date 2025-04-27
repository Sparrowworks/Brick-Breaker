class_name EditorLevelButton extends TextureButton

signal brick_left_pressed(button: EditorLevelButton)
signal brick_right_pressed(button: EditorLevelButton)

var brick_id: Vector2i = Vector2i.ZERO
var type_id: int = 0

var is_mouse_inside: bool = false

func _process(delta: float) -> void:
	if not is_mouse_inside: return

	if Globals.is_mouse_left_held:
		brick_left_pressed.emit(self)
	elif Globals.is_mouse_right_held:
		brick_right_pressed.emit(self)

func _on_mouse_entered() -> void:
	is_mouse_inside = true

func _on_mouse_exited() -> void:
	is_mouse_inside = false
