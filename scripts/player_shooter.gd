class_name Shooter
extends Node2D

signal shot(knockback_force: Vector2)

@export var shooter_stat: ShooterStat

@onready var player_input: PlayerInput = $"../PlayerInput"
@onready var bullet_spawner: MultiplayerSpawner = $"../BulletSpawner"
@onready var shooting_point: Marker2D = $ShootingPoint

const BULLET_SCENE = preload("uid://ssa5260nc2ff")

func _ready() -> void:
	# Ensure all child nodes are ready before accessing them
	await get_tree().process_frame
	
	# Only server processes shooting logic
	set_process(multiplayer.is_server())
	player_input.set_cooldown(shooter_stat.cooldown)

func _process(_delta: float) -> void:
	# Check if player wants to shoot
	if player_input.consume_shoot():
		_handle_shoot_request()
	
	# Visual feedback: point gun at mouse (even on server)
	_update_aim_direction()

func _handle_shoot_request() -> void:
	# Capture power before resetting (handles cooldown case)
	var shot_power = player_input.get_shot_power()
	player_input.reset_shot_gauge()
	
	# Only shoot if not on cooldown
	if player_input.is_on_cooldown():
		return
	
	var click_pos = player_input.get_click_pos()
	var bullet_dir = _calculate_bullet_dir(click_pos)
	
	_spawn_bullet(bullet_dir, shot_power)
	
	# Apply knockback to player
	var knockback = _calculate_knockback(bullet_dir, shot_power)
	shot.emit(knockback)
	
	# Start cooldown
	player_input.reset_current_cooldown()

func _spawn_bullet(bullet_dir: Vector2, shot_power: float) -> void:
	var bullet: Bullet = BULLET_SCENE.instantiate()
	bullet.global_position = shooting_point.global_position
	bullet.set_velocity(bullet_dir * bullet.bullet_stat.velocity)
	bullet.set_bullet_multiplier(shot_power)
	bullet_spawner.add_child(bullet, true)

func _calculate_bullet_dir(target_pos: Vector2) -> Vector2:
	return (target_pos - global_position).normalized()

func _calculate_knockback(bullet_dir: Vector2, shot_power: float) -> Vector2:
	return -bullet_dir * shooter_stat.knockback_force * shot_power

func _update_aim_direction() -> void:
	var target_pos = player_input.get_click_pos()
	look_at(target_pos)
