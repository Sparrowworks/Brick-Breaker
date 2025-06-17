class_name Brick extends StaticBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

signal brick_hit()
signal brick_destroyed(brick_pos: Vector2)

var health: float = 1.0:
	set(val):
		health = val

		if animated_sprite_2d != null:
			if health > 0 and health < 3:
				animated_sprite_2d.animation = str(ceili(health)) + "_" + str(color)
			elif health == 3.0:
				animated_sprite_2d.animation = "3"

@export_enum("Blue: 1", "Green: 2", "Grey: 3", "Orange: 4", "Red: 5", "Orange: 6") var color: int = 1:
	set(val):
		color = val

		if animated_sprite_2d != null:
			animated_sprite_2d.animation = str(ceili(health)) + "_" + str(color)

func _ready() -> void:
	if health == 3:
		animated_sprite_2d.animation = "3"
	else:
		animated_sprite_2d.animation = str(ceili(health)) + "_" + str(color)

func lower_health(is_weak: bool = false, is_strong: bool = false) -> void:
	# Ignore the damage for immune blocks
	if health == 3 or health <= 0:
		return

	if is_weak:
		health -= 0.5
	elif is_strong:
		health = 0
	else:
		health -= 1

	if health <= 0:
		brick_destroyed.emit(global_position)
		queue_free()
	else:
		brick_hit.emit()
		animated_sprite_2d.animation = str(ceili(health)) + "_" + str(color)

func get_size() -> Vector2:
	return collision_shape_2d.shape.get_rect().size
