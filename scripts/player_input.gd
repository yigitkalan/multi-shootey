class_name PlayerInput
# player_input.gd
extends Node2D

@export var direction: Vector2 = Vector2.ZERO  # Synced continuously
@export var max_jump: int = 2

var _cooldown: float
var _jump_requested: bool = false
var _shoot_requested: bool = false
var _current_cooldown: float = 0.0
var _shoot_gauge: float = 0.0
var _mouse_postition: Vector2
var _jump_count : int = 0

@onready var sync: MultiplayerSynchronizer = $InputSynchronizer

func _ready() -> void:
	set_process(sync.is_multiplayer_authority())

func _process(_delta: float) -> void:
	_current_cooldown = clamp(_current_cooldown - _delta, 0, _cooldown)
	
	direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	set_current_mouse_pos()
	
	if Input.is_action_just_pressed("ui_accept"):
		_request_jump()
		
	if Input.is_action_pressed("click") and !_is_on_cooldown():
		_shoot_gauge = clamp(_shoot_gauge + _delta, 0.0, 1.0)
		
	if Input.is_action_just_released("click") and !_is_on_cooldown():
		_request_shoot()

func _is_on_cooldown() -> bool:
	return _current_cooldown > 0.0

func set_cooldown(duration: float): 
	_cooldown = duration
	
func reset_current_cooldown():
	_current_cooldown = _cooldown

func _request_jump() -> void:
	if multiplayer.is_server():
		_jump_requested = true
	else:
		_request_jump_rpc.rpc_id(1)

func _request_shoot() -> void:
	set_current_mouse_pos()
	if multiplayer.is_server():
		_shoot_requested = true
	else:
		_request_shoot_rpc.rpc_id(1, _mouse_postition)
	
func reset_shot_gauge():
	_shoot_gauge = 0
	
func get_shot_power():
	return clamp(_shoot_gauge * 2, 0.5, 2)

@rpc("any_peer", "call_local", "reliable")
func _request_jump_rpc() -> void:
	_jump_requested = true

@rpc("any_peer", "call_local", "reliable")
func _request_shoot_rpc(pos: Vector2) -> void:
	_shoot_requested = true
	_mouse_postition = pos

# For the server to check
func consume_jump() -> bool:
	var result = _jump_requested
	_jump_requested = false
	return result
	
func set_current_mouse_pos() -> void:
	_mouse_postition = get_global_mouse_position()
		
func get_click_pos() -> Vector2:
	return _mouse_postition
	
func can_double_jump() -> bool:
	return _jump_count < max_jump
		
func reset_jump_count():
	_jump_count = 0
	
func increase_jump_count():
	_jump_count += 1
	
func consume_shoot() -> bool:
	var result = _shoot_requested
	_shoot_requested = false
	return result
