class_name Shooter
extends Node2D

signal shot(dir: Vector2)

@export var shooter_stat: ShooterStat
@onready var player_input: PlayerInput = $"../PlayerInput"
@onready var bullet_spawner: MultiplayerSpawner = $"../BulletSpawner"
const BULLET_SCENE = preload("uid://ssa5260nc2ff")

var next_bullet_direction: Vector2
@onready var shooting_point: Marker2D = $ShootingPoint

func _ready() -> void:
	set_process(multiplayer.is_server())
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if player_input.consume_shoot():
		var bullet_dir = _calculate_bullet_dir(player_input.get_click_pos())
		_spawn_bullet(bullet_dir)
		shot.emit(get_knockback_force(bullet_dir))
		
	look_at(player_input.get_click_pos())
	

func _spawn_bullet(bullet_dir: Vector2) -> void:
	if not multiplayer.is_server():
		return
	var bullet : Bullet = BULLET_SCENE.instantiate()
	bullet.global_position = shooting_point.global_position
	bullet.set_velocity(bullet_dir * bullet.bullet_stat.velocity)
	bullet_spawner.add_child(bullet, true)
		
func _calculate_bullet_dir(click_pos: Vector2) -> Vector2:
	# click_pos should already be in world coordinates
	var dir: Vector2 = (click_pos - global_position).normalized()
	return dir
	
func _calculate_spawn_position() -> Vector2:
	return global_position + next_bullet_direction * 5000
	
func get_knockback_force(dir: Vector2) -> Vector2:
	return -dir * shooter_stat.knockback_force
	
	
