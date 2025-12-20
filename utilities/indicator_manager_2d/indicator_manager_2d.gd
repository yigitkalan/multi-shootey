class_name IndicatorManager2D
extends Control

var visible_rect: Rect2
var local_player: Node
@export var player_container: Node

@export var indicator_scene: PackedScene

# Cache indicators per player_id
var active_indicators: Dictionary = {} # { player_id: Sprite2D }

func _ready() -> void:
	GameManager.state_changed.connect(_on_state_changed)

func _on_state_changed(state: int) -> void:
	if state == Globals.GameState.POST_ROUND:
		hide()
func _process(_delta: float) -> void:
	if not player_container:
		push_error("Player container not found")
		return
	# Re-find local player if not set or if it was freed
	if not is_instance_valid(local_player):
		local_player = null # Clear the stale reference
		for player in player_container.get_children():
			if is_instance_valid(player) and player.player_id == Lobby.get_local_peer_id():
				local_player = player
				break
	
	_set_visible_rect()
	_update_all_indicators()


func _update_all_indicators() -> void:
	# Track which player IDs we've seen this frame
	var seen_player_ids: Array = []
	
	for player in player_container.get_children():
		# Skip the local player
		if player == local_player:
			continue

		# Skip invalid/dead players 
		if not is_instance_valid(player):
			continue
		
		var player_id = player.player_id
		seen_player_ids.append(player_id)
		
		var is_offscreen = not _is_position_on_screen(player.global_position)
		
		if is_offscreen:
			_show_or_update_indicator(player)
		else:
			_hide_indicator(player_id)
	
	# Cleanup indicators for players who left the game
	_cleanup_stale_indicators(seen_player_ids)


func _show_or_update_indicator(target_player: DMPlayer) -> void:
	# Safety check - players can be freed between check and call
	if not is_instance_valid(target_player) or not is_instance_valid(local_player):
		return
	
	var player_id = target_player.player_id
	var indicator: Node
	
	# Get or create the indicator
	if active_indicators.has(player_id):
		indicator = active_indicators[player_id]
	else:
		indicator = indicator_scene.instantiate()
		add_child(indicator)
		active_indicators[player_id] = indicator
	
	# Update position and rotation
	var direction = (target_player.global_position - local_player.global_position).normalized()
	var edge_pos = _get_screen_edge_position(direction)
	
	indicator.position = edge_pos # Use `position` not `global_position` since we're in a Control
	indicator.rotation = direction.angle()
	indicator.visible = true


func _hide_indicator(player_id: int) -> void:
	if active_indicators.has(player_id):
		active_indicators[player_id].visible = false


func _cleanup_stale_indicators(current_player_ids: Array) -> void:
	# Remove indicators for players who are no longer in the game
	var ids_to_remove: Array = []
	
	for player_id in active_indicators.keys():
		if player_id not in current_player_ids:
			ids_to_remove.append(player_id)
	
	for player_id in ids_to_remove:
		var indicator = active_indicators[player_id]
		if is_instance_valid(indicator):
			indicator.queue_free()
		active_indicators.erase(player_id)


func _set_visible_rect() -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if not camera:
		return
	
	var viewport_size = get_viewport_rect().size
	var zoom: Vector2 = camera.zoom
	
	var visible_size = viewport_size / zoom
	var top_left = camera.global_position - visible_size / 2
	
	visible_rect = Rect2(top_left, visible_size)

# Check if a position is in view
func _is_position_on_screen(pos: Vector2) -> bool:
	return visible_rect.has_point(pos)


func _get_screen_edge_position(direction: Vector2, margin: float = 25.0) -> Vector2:
	var screen_size := get_viewport_rect().size
	var screen_center := screen_size / 2
	
	# Calculate where the direction ray hits the screen boundary
	# We need to find the intersection with the screen rectangle
	
	var edge_pos = screen_center
	
	# Scale the direction to hit the screen edge
	var scale_x = INF
	var scale_y = INF
	
	if direction.x != 0:
		scale_x = ((screen_center.x - margin) / abs(direction.x))
	if direction.y != 0:
		scale_y = ((screen_center.y - margin) / abs(direction.y))
	
	# Choose min scale to hit the screen edge
	var visible_scale = min(scale_x, scale_y)
	edge_pos = screen_center + direction * visible_scale
	
	return edge_pos
