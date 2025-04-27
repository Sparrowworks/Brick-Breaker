class_name Bullet extends Area2D

const SPEED: float = 2000.0

func _ready() -> void:
	get_tree().create_timer(3).timeout.connect(
		func() -> void:
			queue_free()
	)

func _physics_process(delta: float) -> void:
	global_position.y -= SPEED * delta

func _on_body_entered(body: Node2D) -> void:
	if body is Brick:
		body.lower_health()

	queue_free()
