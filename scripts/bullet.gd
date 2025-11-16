class_name Bullet
extends RigidBody2D

var self_velocity : Vector2
@export var bullet_stat: BulletStat
@onready var timer: Timer = $Timer
@onready var explosion_area: Area2D = $ExplosionArea

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gravity_scale = 0.0
	linear_velocity = self_velocity
	
	timer.wait_time = bullet_stat.lifetime
	timer.start()
	
	_set_area_radius(explosion_area, bullet_stat.explosion_range)
	
	timer.timeout.connect(_destroy_bullet_with_time)
	body_entered.connect(_destroy_bullet_with_target)

	
func _destroy_bullet_with_time():
	if !multiplayer.is_server():
		return
	_fade_and_destroy()
	
func _destroy_bullet_with_target(target: Node):
	var applied_player_ids: Array[int] = []
	
	# Direct hit
	if target is Player:
		applied_player_ids.append(target.player_id)
		target.player_health.take_damage(bullet_stat.hit_damage)
		target.apply_knockback(_calculate_hitback_force(target))
	
	# Trigger area checks on next frame
	await get_tree().physics_frame
	
	# Explosion damage
	for player in _get_area_bodies(explosion_area):
		if applied_player_ids.has(player.player_id):
			continue
		applied_player_ids.append(player.player_id)
		player.player_health.take_damage(bullet_stat.explosion_damage)
		player.apply_knockback(_calculate_hitback_force(player))
	
	timer.stop()
	if multiplayer.is_server():
		_fade_and_destroy()

func set_velocity(velocity: Vector2):
	self_velocity = velocity
	

func _set_area_radius(area: Area2D, radius: float) -> void:
	for child in area.get_children():
		if child is CollisionShape2D:
			var shape = child.shape
			if shape is CircleShape2D:
				shape.radius = radius 

func _get_area_bodies(area: Area2D) -> Array[Player]:
	var bodies = area.get_overlapping_bodies()
	var players : Array[Player] = []
	for body in bodies:
		if body is Player:
			players.append(body)
	print(area.name)
	print(len(players))
	return players
	
func _calculate_hitback_force(target: Node2D):
	return (target.global_position - global_position).normalized() * bullet_stat.explosion_force


func _fade_and_destroy() -> void:
	# Stop physics
	set_deferred("freeze", true)
	
	# Fade out over 1 second
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free.call_deferred)
