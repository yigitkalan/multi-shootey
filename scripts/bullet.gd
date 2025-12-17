class_name Bullet
extends RigidBody2D

@export var bullet_stat: BulletStat
@onready var timer: Timer = $Timer
@onready var explosion_area: Area2D = $ExplosionArea
@onready var mesh_instance_2d: MeshInstance2D = $MeshInstance2D
@onready var bullet_collider: CollisionShape2D = $BulletCollider

@export var multiplier: float
@export_flags_2d_physics var wall_layer_mask: int = 1

func _ready() -> void:
	gravity_scale = 0.0
	timer.wait_time = bullet_stat.lifetime
	timer.start()
	
	bullet_collider.scale *= multiplier
	mesh_instance_2d.scale *= multiplier
	
	_set_area_radius(explosion_area, bullet_stat.explosion_range)
	
	if Lobby.is_host():
		timer.timeout.connect(_destroy_bullet_with_time)
		body_entered.connect(_destroy_bullet_with_target)
	
func _destroy_bullet_with_time():
	if !Lobby.is_host():
		return
	_destroy_rpc.rpc()
	
func _destroy_bullet_with_target(target: Node):
	var applied_player_ids: Array[int] = []
	
	# Direct hit
	if target is DeathmatchPlayer:
		applied_player_ids.append(target.player_id)
		target.player_health.take_damage(bullet_stat.hit_damage)
		target.apply_knockback(_calculate_hitback_force(target))
	
	# Trigger area checks on next frame
	await get_tree().physics_frame
	
	if not is_instance_valid(self):
		return
	
	# Explosion damage
	for player in _get_area_bodies(explosion_area):
		if applied_player_ids.has(player.player_id):
			continue
			
		# Check if a wall is blocking the view
		if not _can_see_target(player):
			continue
			
		applied_player_ids.append(player.player_id)
		player.player_health.take_damage(bullet_stat.explosion_damage)
		player.apply_knockback(_calculate_hitback_force(player))
	
	timer.stop()
	if Lobby.is_host():
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
				
func _get_area_bodies(area: Area2D) -> Array[DeathmatchPlayer]:
	var bodies = area.get_overlapping_bodies()
	var players: Array[DeathmatchPlayer] = []
	for body in bodies:
		if body is DeathmatchPlayer:
			players.append(body)
	return players
	
func _calculate_hitback_force(target: Node2D):
	return (target.global_position - global_position).normalized() * bullet_stat.explosion_force * multiplier

func _can_see_target(target: Node2D) -> bool:
	# Get the physics world
	var space_state = get_world_2d().direct_space_state
	
	# Set up ray parameters
	var query = PhysicsRayQueryParameters2D.new()
	query.from = global_position
	query.to = target.global_position
	query.collision_mask = wall_layer_mask
	query.exclude = [self]
	
	# Cast the ray
	var result = space_state.intersect_ray(query)
	
	# If nothing hit = can see target
	return result.is_empty()

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
	if Lobby.is_host():
		tween.tween_callback(queue_free.call_deferred)
