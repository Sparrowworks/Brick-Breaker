class_name Powerup extends Area2D

signal powerup_collected(powerup: Powerup)
signal powerup_gone(powerup: Powerup)

@export_enum("Small: 1", "Long: 2", "Weak: 3", "Strong: 4", "Slow: 5", "Fast: 6", "Shoot: 7", "Triple: 8") var powerup_type: int = 1:
	set(val):
		powerup_type = val
		if sprite != null:
			set_icon(powerup_type)

@onready var icons: Array = [
	preload("res://assets/images/Game/small.png"),
	preload("res://assets/images/Game/long.png"),
	preload("res://assets/images/Game/weak.png"),
	preload("res://assets/images/Game/strong.png"),
	preload("res://assets/images/Game/slow.png"),
	preload("res://assets/images/Game/fast.png"),
	preload("res://assets/images/Game/shoot.png"),
	preload("res://assets/images/Game/triple.png"),
]

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

const SPEED: float = 200.0

func _ready() -> void:
	set_icon(powerup_type)
	get_tree().create_timer(10).timeout.connect(
		func() -> void:
			powerup_gone.emit(self)
			queue_free()
	)

func _physics_process(delta: float) -> void:
	global_position.y += SPEED * delta

func set_icon(type: int) -> void:
	sprite.texture = icons[type-1]

func _on_body_entered(body: Node2D) -> void:
	powerup_collected.emit(self)
	queue_free()
