class_name PlayerInput
extends Node2D

@export var direction: Vector2 = Vector2.ZERO # Synced
@export var jump_count: int = 0 # Synced
@export var max_jump: int = 2

var _jump_requested: bool = false
var _shoot_requested: bool = false
var _mouse_position: Vector2
var _charge_start_time: float = 0.0
var _is_charging: bool = false

# Cooldown (server-only)
var _cooldown_duration: float = 0.0
var _current_cooldown: float = 0.0

@onready var sync: MultiplayerSynchronizer = $InputSynchronizer

func _ready() -> void:
	# Wait for the synchronizer to be ready in multiplayer scenarios
	if not has_node("InputSynchronizer"):
		await get_tree().process_frame
	set_process(sync.is_multiplayer_authority())

func _process(_delta: float) -> void:
	direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	_mouse_position = get_global_mouse_position()
	
	if Input.is_action_just_pressed("ui_accept"):
		_request_jump()
		
	if Input.is_action_just_pressed("click"):
		_start_charge()
		
	if Input.is_action_just_released("click"):
		_request_shoot()

func _physics_process(delta: float) -> void:
	# Server manages cooldown
	if multiplayer.is_server():
		_current_cooldown = max(0.0, _current_cooldown - delta)

# === Charging ===
func _start_charge() -> void:
	if multiplayer.is_server():
		_is_charging = true
		_charge_start_time = Time.get_ticks_msec() / 1000.0
	else:
		_start_charge_rpc.rpc_id(1)

@rpc("any_peer", "reliable")
func _start_charge_rpc() -> void:
	_is_charging = true
	_charge_start_time = Time.get_ticks_msec() / 1000.0

func get_shot_power() -> float:
	if not _is_charging:
		return 0.5
	var charge_time = (Time.get_ticks_msec() / 1000.0) - _charge_start_time
	var gauge = clamp(charge_time, 0.0, 1.0)
	return clamp(gauge * 2, 0.5, 2.0)

func reset_shot_gauge():
	_is_charging = false
	_charge_start_time = 0.0

# === Shooting ===
func _request_shoot() -> void:
	if multiplayer.is_server():
		_shoot_requested = true
	else:
		_request_shoot_rpc.rpc_id(1, _mouse_position)

@rpc("any_peer", "reliable")
func _request_shoot_rpc(pos: Vector2) -> void:
	_shoot_requested = true
	_mouse_position = pos

func consume_shoot() -> bool:
	var result = _shoot_requested
	_shoot_requested = false
	return result

func get_click_pos() -> Vector2:
	return _mouse_position

# === Jumping ===
func _request_jump() -> void:
	if multiplayer.is_server():
		_jump_requested = true
	else:
		_request_jump_rpc.rpc_id(1)

@rpc("any_peer", "reliable")
func _request_jump_rpc() -> void:
	_jump_requested = true

func consume_jump() -> bool:
	var result = _jump_requested
	_jump_requested = false
	return result

func can_double_jump() -> bool:
	if not multiplayer.is_server():
		return false
	return jump_count < max_jump

func reset_jump_count():
	if multiplayer.is_server():
		jump_count = 0

func increase_jump_count():
	if multiplayer.is_server():
		jump_count += 1

# === Cooldown ===
func set_cooldown(duration: float):
	_cooldown_duration = duration

func reset_current_cooldown():
	if multiplayer.is_server():
		_current_cooldown = _cooldown_duration

func is_on_cooldown() -> bool:
	return _current_cooldown > 0.0
