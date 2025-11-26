class_name Player
extends RigidBody2D

@export var player_stat: PlayerStat

@onready var input: PlayerInput = $PlayerInput
@onready var ground_check: RayCast2D = $GroundCheck
@onready var player_health: PlayerHealth = $PlayerHealth
@onready var shooter: Shooter = $Shooter
@onready var health_bar: HealthBar = $HealthBar


var knockback_time = 0.0


@export var player_id := 1:
	set(id):
		player_id = id
		# DON'T set authority on self (the player body)
		# player body stays under server authority

		# ONLY set authority on the input synchronizer child node
		if has_node("PlayerInput"):
			$PlayerInput.set_multiplayer_authority(id)


func _ready() -> void:
	linear_damp = 3.0 # Acts like air resistance/friction
	if multiplayer.is_server():
		player_health.died.connect(_on_died)
		shooter.shot.connect(apply_knockback)
	player_health.took_damage.connect(health_bar.update_bar)
	lock_rotation = true

func _process(delta: float) -> void:
	knockback_time = max(knockback_time - delta, 0)

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	
	var on_floor = ground_check.is_colliding()
	
	if knockback_time > 0:
		return # Skip normal movement force
		
	if not input.can_double_jump() and on_floor:
		input.reset_jump_count()
		
	# Jump - use impulse (instant velocity change is fine here)
	if input.consume_jump() and (on_floor or input.can_double_jump()):
		input.increase_jump_count()
		apply_central_impulse(Vector2(0, player_stat.jump_force))
	
	# Movement - apply forces
	var dir = input.direction
	
	if dir != Vector2.ZERO:
		var movement_multiplier = 1.0 if on_floor else player_stat.air_movement_coefficient
		var target_velocity = dir.x * player_stat.max_velocity
		var velocity_diff = target_velocity - linear_velocity.x
		apply_central_force(Vector2(velocity_diff * player_stat.movement_force * movement_multiplier, 0))
	elif on_floor:
		# Apply stopping force when no input
		apply_central_force(Vector2(-linear_velocity.x * player_stat.movement_force, 0))

func _on_died():
	if multiplayer.is_server():
		remove_player.rpc()
		GameManager.kill_player(player_id)
	if input.is_multiplayer_authority():
		#maybe lose screen or spectator etc. these will be local changes
		pass
	
@rpc("any_peer", "call_local", "reliable")
func remove_player():
	set_physics_process(false)
	hide()
	
func apply_knockback(force: Vector2):
	knockback_time = shooter.shooter_stat.knockback_duration
	apply_central_impulse(force)
