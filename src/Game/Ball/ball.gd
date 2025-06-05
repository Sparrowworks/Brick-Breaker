class_name Ball extends CharacterBody2D

signal first_start()

signal ball_dead(ball: Ball)
signal ball_paddle_bounced()
signal ball_brick_normal_bounced()
signal ball_brick_armour_bounced()

signal faded_out()
signal hide_help()

@export var paddle: Paddle

@export var is_locked: bool = false
@export var has_ball_started: bool = false
@export var is_first_start: bool = true

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var speed: float = 30

var start_pos: Vector2

var is_weak: bool = false
var is_strong: bool = false

func _ready() -> void:
	start_pos = position

func start_ball(align_left: bool = false, align_right: bool = false, custom_pos: bool = false) -> void:
	hide_help.emit()
	if not custom_pos:
		position = start_pos

	# Move the ball in the paddle’s movement direction.
	if align_left == false and align_right == false:
		velocity = Vector2(randf_range(-1, 1), randf_range(-0.5, -1)).normalized()
	elif align_left == true:
		velocity = Vector2(randf_range(-1, -0.5), randf_range(-0.5, -1)).normalized()
	elif align_right == true:
		velocity = Vector2(randf_range(0.5, 1), randf_range(-0.5, -1)).normalized()

	if is_first_start:
		is_first_start = false
		first_start.emit()

func _physics_process(delta: float) -> void:
	# Reenable collision with paddle when moving up
	if get_collision_mask_value(2) == false and global_position.y < 1700:
		paddle.set_collision_mask_value(1, true)
		set_collision_mask_value(2, true)

	if not has_ball_started:
		if Input.is_action_pressed("left"):
			has_ball_started = true
			start_ball(true, false)
		elif Input.is_action_pressed("right"):
			has_ball_started = true
			start_ball(false, true)
		else:
			return

	# Clamp the velocity to prevent vertical or horizontal movement
	if velocity.y > -0.3 and velocity.y < 0:
		velocity.y = -0.3
	elif velocity.y > 0 and velocity.y <= 0.3:
		velocity.y = 0.3

	if velocity.x > -0.2 and velocity.x < 0:
		velocity.x = -0.2
	elif velocity.x > 0 and velocity.x <= 0.2:
		velocity.x = 0.2

	# Kill the ball upon leaving the screen
	if position.y > 2200:
		velocity = Vector2.ZERO
		global_position.y = -200
		ball_dead.emit(self)

	var collision: KinematicCollision2D = move_and_collide(velocity * speed * speed * delta)
	if not collision:
		return

	var collider: Object = collision.get_collider()

	# Handle collision with paddle
	if collision.get_collider() is Paddle:
		paddle_collision(collision, collider as Paddle, delta)
		return

	ball_brick_normal_bounced.emit()

	# Handle collision with bricks
	if collider is Brick:
		if collider.health > 1:
			ball_brick_armour_bounced.emit()

		collider.lower_health(is_weak, is_strong)

		if is_strong and collider.health < 3:
			return

	velocity = velocity.bounce(collision.get_normal()).normalized()


func paddle_collision(collision: KinematicCollision2D, collider: Paddle, delta: float) -> void:
	ball_paddle_bounced.emit()
	# Disable collision with paddle to prevent getting the ball stuck and other bugs
	paddle.set_collision_mask_value(1, false)
	set_collision_mask_value(2, false)

	var ball_center_x: float = position.x
	var paddle_width: float = collider.get_width()
	var paddle_center_x: float = collider.position.x

	var vel_xy: float = velocity.length()
	var collision_x : float = (ball_center_x - paddle_center_x) / (paddle_width / 2)

	# Calculate the new velocity upon bouncing
	var new_vel: Vector2 = Vector2.ZERO
	new_vel.x = vel_xy * collision_x
	new_vel.y = sqrt(absf(vel_xy*vel_xy - new_vel.x*new_vel.x)) * Vector2.UP.y

	velocity = new_vel.normalized()

	move_and_collide(velocity * speed * speed * delta)

func _on_game_game_reset() -> void:
	if is_locked: return

	# Move the ball back to the starting position
	position = start_pos
	velocity = Vector2.ZERO
	modulate = Color.TRANSPARENT

	var fade_tween: Tween = get_tree().create_tween()
	fade_tween.tween_property(self, "modulate:a", 1, 1)
	await fade_tween.finished

	faded_out.emit()
	has_ball_started = false
