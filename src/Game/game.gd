extends Node2D

signal game_paused()
signal game_reset()
signal game_over()
signal game_won()

@onready var goodpowerup: AudioStreamPlayer = $Audio/Goodpowerup
@onready var badpowerup: AudioStreamPlayer = $Audio/Badpowerup
@onready var shoot_sound: AudioStreamPlayer = $Audio/Shoot
@onready var win: AudioStreamPlayer = $Audio/Win
@onready var gameover: AudioStreamPlayer = $Audio/Gameover
@onready var fail: AudioStreamPlayer = $Audio/Fail
@onready var bouncepaddle: AudioStreamPlayer = $Audio/Bouncepaddle
@onready var bouncenormal: AudioStreamPlayer = $Audio/Bouncenormal
@onready var bouncearmor: AudioStreamPlayer = $Audio/Bouncearmor

@onready var sounds: Array[AudioStreamPlayer] = [
	goodpowerup, badpowerup, shoot_sound, win, gameover, fail, bouncepaddle, bouncenormal, bouncearmor
]

@onready var music_player: MusicPlayer = $MusicPlayer
@onready var track_name: Label = %TrackName
@onready var loop_status: Label = %LoopStatus

@onready var load_panel: Panel = $CanvasLayer/UI/LoadPanel
@onready var ui: Control = %UI
@onready var pause_ui: Control = $CanvasLayer/PauseUi
@onready var help: Label = %Help
@onready var level_title: Label = %LevelTitle
@onready var level_author: Label = %LevelAuthor
@onready var time_text: Label = %TimeText
@onready var score_text: Label = %ScoreText
@onready var brick_text: Label = %BrickText
@onready var lives_text: Label = %LivesText
@onready var editor_button: TextureButton = %EditorButton
@onready var win_editor_button: TextureButton = %WinEditorButton
@onready var next_button: TextureButton = %NextButton

@onready var win_panel: Control = %WinPanel
@onready var win_time: Label = %WinTime
@onready var win_score: Label = %WinScore
@onready var win_bricks: Label = %WinBricks

@onready var lose_panel: Control = %LosePanel
@onready var lose_time: Label = %LoseTime
@onready var lose_score: Label = %LoseScore
@onready var lose_bricks: Label = %LoseBricks

@onready var resize: Label = %Resize
@onready var weak: Label = %Weak
@onready var strong: Label = %Strong
@onready var slow: Label = %Slow
@onready var fast: Label = %Fast
@onready var shoot: Label = %Shoot

@onready var ball: Ball = $Ball
@onready var left_ball: Ball = $LeftBall
@onready var right_ball: Ball = $RightBall
@onready var paddle: Paddle = $Paddle
@onready var bricks: Node2D = $Bricks
@onready var balls: Array[Ball] = [ball, left_ball, right_ball]

@onready var time_timer: Timer = $TimeTimer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

const BALL = preload("res://src/Game/Ball/Ball.tscn")
const BRICK = preload("res://src/Game/Brick/Brick.tscn")
const POWERUP = preload("res://src/Game/Powerup/Powerup.tscn")

const X_INCREMENT: float = 212
const Y_INCREMENT: float = 112

var file_path: String
var levels_list: Array[String] = []
var level_id: int = 0

var level_data: Level

var time: int = 0
var score: int = 0
var destroyed: int = 0
var lives: int = 3
var balls_left: int = 1

var bricks_left: int = 0
var powerup_chance: float = 0
var powerups: Array[Powerup] = []

var is_game_over: bool = false

var size_timer: Timer
var size_wait_time: int = 15

var speed_timer: Timer
var speed_wait_time: int = 15

var ball_power_timer: Timer
var ball_power_wait_time: int = 15

var shoot_timer: Timer
var shoot_wait_time: int = 10
var firerate: Timer

var is_triple_active: bool = false

func _ready() -> void:
	set_process_input(false)
	ui.show()
	load_panel.show()

	var test_powerup: Powerup = POWERUP.instantiate()
	add_child(test_powerup)
	await get_tree().create_timer(0.1).timeout
	test_powerup.queue_free()

	# Preloading the sounds helps preventing lag on web build
	if OS.get_name() == "Web":
		await Globals.transition.finished_fade_out

		music_player.initialize()
		if not music_player.has_initialized:
			await music_player.finished_loading

		for x in range(0, sounds.size()):
			sounds[x].volume_db = linear_to_db(0.0)
			sounds[x].play()
			await get_tree().create_timer(0.01).timeout
			sounds[x].stop()
			sounds[x].volume_db = linear_to_db(1.0)

	load_panel.hide()
	lose_panel.hide()
	win_panel.hide()

	if has_meta("list"):
		levels_list = get_meta("list")

	if has_meta("id"):
		level_id = get_meta("id")

	if has_meta("level_data"):
		level_data = get_meta("level_data", Level.new())
		setup_level(level_data)
	else:
		load_file(levels_list[level_id])

	update_ui()
	set_process_input(true)

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("reset"):
		_on_reset_button_pressed()

	if Input.is_action_just_pressed("pause"):
		set_process_input(false)
		get_tree().paused = true
		game_paused.emit()

	if Input.is_action_just_pressed("menu"):
		_on_menu_button_pressed()

func update_ui() -> void:
	if get_meta("editor_launch", false):
		editor_button.show()

	level_title.text = level_data.level_name.replace("_", " ")
	level_author.text = "By: " + level_data.level_author

	time_text.text = "Time: " + str(time)
	score_text.text = "Score: " + str(score)
	brick_text.text = "Destroyed: " + str(destroyed)
	lives_text.text = "Balls: " + str(lives)

func load_file(path: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)

	if file == null:
		printerr("ERROR: Couldn't load level " + path + " with error code " + str(FileAccess.get_open_error()))
		return

	var data: Variant = file.get_var(true)
	file.close()

	level_data = Level.new()
	level_data.level_name = data["name"]
	level_data.level_author = data["author"]

	var level_dict: Dictionary[Vector2i, BrickLevelType]
	for key: Vector2i in data["data"].keys():
		level_dict[key] = data["data"][key] as BrickLevelType

	level_data.level_dict = level_dict

	setup_level(level_data)

func setup_level(data: Level) -> void:
	var x_init_pos: float = 860
	var y_init_pos: float = 154

	# Create the bricks for the level
	for key: Vector2i in data.level_dict.keys():
		var brick_data: BrickLevelType = data.level_dict[key]

		var brick: Brick = BRICK.instantiate()
		brick.color = brick_data.button_id
		brick.health = brick_data.type_id
		brick.position = Vector2(x_init_pos + (key.x * X_INCREMENT), y_init_pos + (key.y * Y_INCREMENT))
		brick.brick_hit.connect(_on_brick_hit)
		brick.brick_destroyed.connect(_on_brick_destroyed)

		if brick.health < 3:
			bricks_left += 1

		bricks.add_child(brick)

func start_game() -> void:
	music_player.enable()
	time_timer.start()

func spawn_powerup(brick_pos: Vector2) -> void:
	if is_game_over: return

	var powerup: Powerup = POWERUP.instantiate()
	powerup.powerup_collected.connect(_on_powerup_collected)
	powerup.powerup_gone.connect(_on_powerup_gone)
	call_deferred("add_child", powerup)
	powerups.append(powerup)

	powerup.global_position = brick_pos
	# Prevent triple ball from spawning if it's already active.
	if is_triple_active:
		powerup.powerup_type = randi_range(1, 7)
	else:
		powerup.powerup_type = randi_range(1, 8)

	if powerup.powerup_type == 8:
		is_triple_active = true

func small_paddle() -> void:
	if size_timer != null:
		size_timer.stop()
		size_timer.queue_free()

	var scale_tween: Tween = get_tree().create_tween()
	scale_tween.tween_property(paddle, "scale", Vector2(0.75, 0.75), 0.5)

	size_wait_time = 15
	resize.text = "Small Paddle: " + str(size_wait_time)
	resize.show()

	size_timer = Timer.new()
	size_timer.wait_time = 1
	size_timer.timeout.connect(
		func() -> void:
			size_wait_time -= 1
			resize.text = "Small Paddle: " + str(size_wait_time)
			if size_wait_time > 0:
				size_timer.start()
			else:
				var rescale_tween: Tween = get_tree().create_tween()
				rescale_tween.tween_property(paddle, "scale", Vector2(1.0, 1.0), 0.5)
				resize.hide()
				size_timer.queue_free()
	)
	add_child(size_timer)
	size_timer.start()

func long_paddle() -> void:
	if size_timer != null:
		size_timer.stop()
		size_timer.queue_free()

	var scale_tween: Tween = get_tree().create_tween()
	scale_tween.tween_property(paddle, "scale", Vector2(1.25, 1.25), 0.5)

	size_wait_time = 15
	resize.text = "Big Paddle: " + str(size_wait_time)
	resize.show()

	size_timer = Timer.new()
	size_timer.wait_time = 1
	size_timer.timeout.connect(
		func() -> void:
			size_wait_time -= 1
			resize.text = "Big Paddle: " + str(size_wait_time)
			if size_wait_time > 0:
				size_timer.start()
			else:
				var rescale_tween: Tween = get_tree().create_tween()
				rescale_tween.tween_property(paddle, "scale", Vector2(1.0, 1.0), 0.5)
				resize.hide()
				size_timer.queue_free()
	)
	add_child(size_timer)
	size_timer.start()

func weak_ball() -> void:
	if ball_power_timer != null:
		ball_power_timer.stop()
		ball_power_timer.queue_free()

	var scale_tween: Tween = get_tree().create_tween()
	scale_tween.set_parallel(true)

	for instance in balls:
		scale_tween.tween_property(instance, "scale", Vector2(0.5, 0.5), 0.5)
		if instance.is_weak: continue

		instance.is_weak = true
		instance.is_strong = false

	ball_power_wait_time = 10
	weak.text = "Weak Ball: " + str(ball_power_wait_time)
	weak.show()
	strong.hide()

	ball_power_timer = Timer.new()
	ball_power_timer.wait_time = 1
	ball_power_timer.timeout.connect(
		func() -> void:
			ball_power_wait_time -= 1
			weak.text = "Weak Ball: " + str(ball_power_wait_time)
			if ball_power_wait_time > 0:
				ball_power_timer.start()
			else:
				var rescale_tween: Tween = get_tree().create_tween()
				rescale_tween.set_parallel(true)

				for instance in balls:
					instance.is_weak = false
					rescale_tween.tween_property(instance, "scale", Vector2(1, 1), 0.5)

				weak.hide()
				ball_power_timer.queue_free()
	)
	add_child(ball_power_timer)
	ball_power_timer.start()

func strong_ball() -> void:
	if ball_power_timer != null:
		ball_power_timer.stop()
		ball_power_timer.queue_free()

	var scale_tween: Tween = get_tree().create_tween()
	scale_tween.set_parallel(true)

	for instance in balls:
		scale_tween.tween_property(instance, "scale", Vector2(1.5, 1.5), 0.5)
		if instance.is_strong: continue

		instance.is_strong = true
		instance.is_weak = false

	ball_power_wait_time = 10
	strong.text = "Strong Ball: " + str(ball_power_wait_time)
	strong.show()
	weak.hide()

	ball_power_timer = Timer.new()
	ball_power_timer.wait_time = 1
	ball_power_timer.timeout.connect(
		func() -> void:
			ball_power_wait_time -= 1
			strong.text = "Strong Ball: " + str(ball_power_wait_time)
			if ball_power_wait_time > 0:
				ball_power_timer.start()
			else:
				var rescale_tween: Tween = get_tree().create_tween()
				rescale_tween.set_parallel(true)

				for instance in balls:
					instance.is_strong = false
					rescale_tween.tween_property(instance, "scale", Vector2(1, 1), 0.5)

				strong.hide()
				ball_power_timer.queue_free()
	)
	add_child(ball_power_timer)
	ball_power_timer.start()

func slow_paddle() -> void:
	if speed_timer != null:
		speed_timer.stop()
		speed_timer.queue_free()

	paddle.speed = 30
	speed_wait_time = 15
	slow.text = "Slow Speed: " + str(speed_wait_time)

	slow.show()
	fast.hide()

	speed_timer = Timer.new()
	speed_timer.wait_time = 1
	speed_timer.timeout.connect(
		func() -> void:
			speed_wait_time -= 1
			slow.text = "Slow Speed: " + str(speed_wait_time)
			if speed_wait_time > 0:
				speed_timer.start()
			else:
				paddle.speed = 35.0
				slow.hide()
				speed_timer.queue_free()
	)
	add_child(speed_timer)
	speed_timer.start()

func fast_paddle() -> void:
	if speed_timer != null:
		speed_timer.stop()
		speed_timer.queue_free()

	paddle.speed = 40
	speed_wait_time = 15
	fast.text = "Fast Speed: " + str(speed_wait_time)

	fast.show()
	slow.hide()

	speed_timer = Timer.new()
	speed_timer.wait_time = 1
	speed_timer.timeout.connect(
		func() -> void:
			speed_wait_time -= 1
			fast.text = "Fast Speed: " + str(speed_wait_time)
			if speed_wait_time > 0:
				speed_timer.start()
			else:
				paddle.speed = 35.0
				fast.hide()
				speed_timer.queue_free()
	)
	add_child(speed_timer)
	speed_timer.start()

func paddle_shoot() -> void:
	if shoot_timer != null:
		firerate.stop()
		firerate.queue_free()

		shoot_timer.stop()
		shoot_timer.queue_free()

	shoot_wait_time = 10
	shoot.text = "Shooting: " + str(shoot_wait_time)
	shoot.show()

	shoot_timer = Timer.new()
	shoot_timer.wait_time = 1
	shoot_timer.timeout.connect(
		func() -> void:
			shoot_wait_time -= 1
			shoot.text = "Shooting: " + str(shoot_wait_time)
			if shoot_wait_time > 0:
				shoot_timer.start()
			else:
				shoot.hide()
				shoot_timer.queue_free()
				firerate.queue_free()
	)

	firerate = Timer.new()
	firerate.wait_time = 0.5
	firerate.timeout.connect(
		func() -> void:
			shoot_sound.play()
			paddle.shoot()
	)

	add_child(shoot_timer)
	add_child(firerate)
	shoot_timer.start()
	firerate.start()

func triple_balls() -> void:
	if balls_left > 1:
		return

	balls_left += 2

	ball.show()
	left_ball.show()
	right_ball.show()

	left_ball.global_position = Vector2(
		ball.global_position.x - 50,
		ball.global_position.y
	)

	right_ball.global_position = Vector2(
		ball.global_position.x + 50,
		ball.global_position.y
	)

	left_ball.start_ball(true, false, true)
	right_ball.start_ball(false, true, true)

func kill_powerups() -> void:
	# Reset all powerup effects and remove each powerup instance present on screen
	for powerup in powerups:
		powerup.queue_free()

	powerups.clear()

	resize.hide()
	weak.hide()
	strong.hide()
	shoot.hide()
	slow.hide()
	fast.hide()

	if size_timer != null:
		size_timer.stop()
		size_timer.queue_free()

	if speed_timer != null:
		speed_timer.stop()
		speed_timer.queue_free()

	if shoot_timer != null:
		firerate.stop()
		firerate.queue_free()

		shoot_timer.stop()
		shoot_timer.queue_free()

	if ball_power_timer != null:
		ball_power_timer.stop()
		ball_power_timer.queue_free()

	var scale_tween: Tween = get_tree().create_tween()
	scale_tween.tween_property(paddle, "scale", Vector2(1, 1), 0.5)
	paddle.speed = 35.0

	for instance in balls:
		instance.velocity = Vector2.ZERO
		instance.scale = Vector2(1, 1)
		instance.is_strong = false
		instance.is_weak = false

func _on_ball_first_start() -> void:
	start_game()

func _on_brick_hit() -> void:
	score += 25
	update_ui()

func _on_brick_destroyed(brick_pos: Vector2) -> void:
	# Increase the speed on the ball with each brick destroyed
	ball.speed = clampf(ball.speed + 0.1, 30.0, 35.0)
	left_ball.speed = ball.speed
	right_ball.speed = ball.speed

	# Increase the chance of spawning a powerup
	powerup_chance += 2
	var chance: float = randf_range(1, 100)
	if chance <= powerup_chance:
		spawn_powerup(brick_pos)
		powerup_chance = 0

	score += 100
	destroyed += 1
	bricks_left -= 1
	update_ui()

	if bricks_left == 0:
		await get_tree().create_timer(0.5).timeout

		game_won.emit()

func _on_ball_ball_dead(dead_ball: Ball) -> void:
	balls_left -= 1

	if dead_ball == left_ball or dead_ball == right_ball:
		dead_ball.hide()

	# Set the last remaining ball as the main one
	if balls_left == 1:
		is_triple_active = false

		if dead_ball == ball:
			var temp_ball: Ball
			if left_ball.visible:
				temp_ball = left_ball
				left_ball = ball
				ball = temp_ball
			elif right_ball.visible:
				temp_ball = right_ball
				right_ball = ball
				ball = temp_ball

	# Lose a life if there are no balls left on the screen
	if balls_left > 0:
		return

	time_timer.stop()

	kill_powerups()
	ball.show()

	fail.play()

	lives -= 1
	update_ui()

	if lives <= 0:
		await get_tree().create_timer(1.5).timeout

		game_over.emit()
		return

	left_ball.position = left_ball.start_pos
	right_ball.position = right_ball.start_pos

	balls_left = 1
	game_reset.emit()

func _on_powerup_gone(powerup: Powerup) -> void:
	# Allow the triple balls powerup to spawn again
	if powerup.powerup_type == 8 and balls_left == 1:
		is_triple_active = false

	powerups.erase(powerup)

func _on_powerup_collected(powerup: Powerup) -> void:
	if is_game_over: return

	if powerup.powerup_type == 1 or powerup.powerup_type == 3 or powerup.powerup_type == 5:
		badpowerup.play()
	else:
		goodpowerup.play()

	# Activate the correct powerup
	match powerup.powerup_type:
		1:
			small_paddle()
		2:
			long_paddle()
		3:
			weak_ball()
		4:
			strong_ball()
		5:
			slow_paddle()
		6:
			fast_paddle()
		7:
			paddle_shoot()
		8:
			triple_balls()

	powerups.erase(powerup)

func _on_time_timeout() -> void:
	time += 1
	update_ui()

func _on_game_won() -> void:
	is_game_over = true

	kill_powerups()

	music_player.disable()
	time_timer.stop()

	animation_player.play("GameOver")
	await animation_player.animation_finished

	win.play()

	# Show a button to return to editor if we're testing
	if get_meta("editor_launch", false):
		win_editor_button.show()
	else:
		if level_id	== levels_list.size() - 1:
			next_button.hide()
		else:
			next_button.show()

	win_time.text = "Total Time: " + str(time)
	win_score.text = "Total Score: " + str(score)
	win_bricks.text = "Destroyed Bricks: " + str(destroyed)

	win_panel.show()

func _on_game_over() -> void:
	is_game_over = true

	kill_powerups()

	music_player.disable()
	time_timer.stop()

	animation_player.play("GameOver")
	await animation_player.animation_finished

	gameover.play()

	lose_time.text = "Total Time: " + str(time)
	lose_score.text = "Total Score: " + str(score)
	lose_bricks.text = "Missed Bricks: " + str(bricks_left)

	lose_panel.show()

func _on_next_button_pressed() -> void:
	# Get the next level
	level_id += 1
	if levels_list.size() == level_id:
		level_id = 0

	Globals.go_to_with_fade("res://src/Game/Game.tscn", {"list": levels_list, "id": level_id})

func _on_editor_button_pressed() -> void:
	Globals.go_to_with_fade("res://src/Menus/Editor/Editor.tscn", {"editor_data": level_data})

func _on_reset_button_pressed() -> void:
	var	editor_launch: bool = get_meta("editor_launch", false)

	if has_meta("level_data"):
		Globals.go_to_with_fade("res://src/Game/Game.tscn", {"list": levels_list, "id": level_id, "editor_launch": editor_launch, "level_data": level_data})
	else:
		Globals.go_to_with_fade("res://src/Game/Game.tscn", {"list": levels_list, "id": level_id, "editor_launch": editor_launch})

func _on_menu_button_pressed() -> void:
	Globals.go_to_with_fade("res://src/Menus/LevelSelect/LevelSelect.tscn", {"list": levels_list})

func _on_paddle_show_help() -> void:
	help.show()

func _on_ball_hide_help() -> void:
	time_timer.start()

	help.hide()

func _on_music_player_loop_changed(is_on: bool) -> void:
	if is_on:
		loop_status.text = "Music Loop: ON"
	else:
		loop_status.text = "Music Loop: OFF"

func _on_music_player_track_changed(name: String) -> void:
	track_name.text = "Playing:\n" + name

func _on_ball_ball_paddle_bounced() -> void:
	bouncepaddle.play()

func _on_ball_ball_brick_normal_bounced() -> void:
	bouncenormal.play()

func _on_ball_ball_brick_armour_bounced() -> void:
	bouncearmor.play()

func _on_pause_ui_game_unpaused() -> void:
	get_tree().paused = false
	Globals.button_click.play()

	await get_tree().create_timer(0.5).timeout
	set_process_input(true)
