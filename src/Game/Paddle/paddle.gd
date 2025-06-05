class_name Paddle extends CharacterBody2D

signal show_help()

@export var ball: Ball

@onready var left_bullet_pos: Marker2D = $LeftBulletPos
@onready var right_bullet_pos: Marker2D = $RightBulletPos

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

const BULLET = preload("res://src/Game/Bullet/Bullet.tscn")

var direction: Vector2 = Vector2.ZERO
var speed: float = 35.0

var can_move: bool = true
var tween_finished: bool = true

var start_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	start_pos = position

func _physics_process(delta: float) -> void:
	if not can_move:
		return

	velocity.x = Input.get_axis("left", "right") * speed
	position.y = start_pos.y

	# Handle the collision with ball
	var collision := move_and_collide(velocity * speed * delta)
	if collision:
		var collider := collision.get_collider()
		if collider is Ball:
			collider.paddle_collision(collision, self, delta)

func _on_game_game_reset() -> void:
	tween_finished = false
	can_move = false

	# Move the paddle back to the starting position
	var move_tween: Tween = get_tree().create_tween()
	move_tween.set_trans(Tween.TRANS_CUBIC)
	move_tween.tween_property(self, "position:x", start_pos.x, 1.0)
	await move_tween.finished

	if not tween_finished:
		await ball.faded_out
	can_move = true

	show_help.emit()

func _on_ball_faded_out() -> void:
	tween_finished = true

func _on_game_game_over() -> void:
	can_move = false

func _on_game_game_won() -> void:
	can_move = false

func get_width() -> float:
	return collision_shape_2d.shape.get_rect().size.x

func shoot() -> void:
	var left_bullet: Bullet = BULLET.instantiate()
	var right_bullet: Bullet = BULLET.instantiate()

	left_bullet.global_position = left_bullet_pos.global_position
	right_bullet.global_position = right_bullet_pos.global_position

	get_parent().add_child(left_bullet)
	get_parent().add_child(right_bullet)
