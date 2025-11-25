class_name Bullet
extends RigidBody2D

@export var bullet_stat: BulletStat
@onready var timer: Timer = $Timer
@onready var explosion_area: Area2D = $ExplosionArea
@onready var mesh_instance_2d: MeshInstance2D = $MeshInstance2D
@onready var bullet_collider: CollisionShape2D = $BulletCollider

@export var multiplier: float

func _ready() -> void:
	gravity_scale = 0.0
	timer.wait_time = bullet_stat.lifetime
	timer.start()
	
	bullet_collider.scale *= multiplier
	mesh_instance_2d.scale *= multiplier
	
	_set_area_radius(explosion_area, bullet_stat.explosion_range)
	
	if multiplayer.is_server():
		timer.timeout.connect(_destroy_bullet_with_time)
		body_entered.connect(_destroy_bullet_with_target)
	
func _destroy_bullet_with_time():
	if !multiplayer.is_server():
		return
	_destroy_rpc.rpc()
	
func _destroy_bullet_with_target(target: Node):
	var applied_player_ids: Array[int] = []
	
	# Direct hit
	if target is Player:
		applied_player_ids.append(target.player_id)
		target.player_health.take_damage(bullet_stat.hit_damage)
		target.apply_knockback(_calculate_hitback_force(target))
	
	# Trigger area checks on next frame
	await get_tree().physics_frame
	
	# ✅ Check if bullet still exists
	if not is_instance_valid(self):
		return
	
	# Explosion damage
	for player in _get_area_bodies(explosion_area):
		if applied_player_ids.has(player.player_id):
			continue
		applied_player_ids.append(player.player_id)
		player.player_health.take_damage(bullet_stat.explosion_damage)
		player.apply_knockback(_calculate_hitback_force(player))
	
	timer.stop()
	if multiplayer.is_server():
		_destroy_rpc.rpc()

func set_velocity(velocity: Vector2):
	linear_velocity = velocity
	
func set_bullet_multiplier(mult: float):
	multiplier = mult

func _set_area_radius(area: Area2D, radius: float) -> void:
	for child in area.get_children():
		if child is CollisionShape2D:
			var shape = child.shape
			if shape is CircleShape2D:
				shape.radius = bullet_stat.explosion_range * multiplier
				
func _get_area_bodies(area: Area2D) -> Array[Player]:
	var bodies = area.get_overlapping_bodies()
	var players: Array[Player] = []
	for body in bodies:
		if body is Player:
			players.append(body)
	return players
	
func _calculate_hitback_force(target: Node2D):
	return (target.global_position - global_position).normalized() * bullet_stat.explosion_force * multiplier

@rpc("any_peer", "call_local", "reliable")
func _destroy_rpc():
	_fade_and_destroy()

func _fade_and_destroy() -> void:
	# Stop physics
	set_deferred("freeze", true)
	
	# Fade out over 1 second
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	
	# Only server destroys the object
	# Clients wait for replication to remove it
	if multiplayer.is_server():
		tween.tween_callback(queue_free.call_deferred)
