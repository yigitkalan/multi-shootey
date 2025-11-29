extends Node

# State management
var current_state: Globals.GameState = Globals.GameState.NONE
var previous_state: Globals.GameState = Globals.GameState.NONE
var round_number: int = 0
var max_rounds: int = 3

# Mode management
var current_mode: GameMode = null

# Score tracking (persists across rounds)
var player_scores: Dictionary[int, int] = {}

# Signals
signal state_changed(new_state: Globals.GameState)
signal round_ended(winner_ids: Array[int])
signal mode_data_changed(data: Dictionary)


func _ready() -> void:
	# Will be set by the game scene when it loads
	pass


func set_active_mode(mode: GameMode) -> void:
	# Disconnect old mode if exists
	if current_mode:
		if current_mode.round_should_end.is_connected(_on_mode_round_end):
			current_mode.round_should_end.disconnect(_on_mode_round_end)
		if current_mode.data_updated.is_connected(_on_mode_data_updated):
			current_mode.data_updated.disconnect(_on_mode_data_updated)
	
	# Connect new mode
	current_mode = mode
	if current_mode:
		current_mode.round_should_end.connect(_on_mode_round_end)
		current_mode.data_updated.connect(_on_mode_data_updated)


func change_state(new_state: Globals.GameState) -> void:
	if not multiplayer.is_server():
		return
		
	_sync_state.rpc(new_state, previous_state)
	_on_state_entered(new_state)


@rpc("authority", "call_local", "reliable")
func _sync_state(new_state: Globals.GameState, old_state: Globals.GameState) -> void:
	current_state = new_state
	previous_state = old_state
	state_changed.emit(new_state)


func _on_state_entered(state: Globals.GameState) -> void:
	match state:
		Globals.GameState.PRE_ROUND:
			round_number += 1
				
		Globals.GameState.IN_ROUND:
			if current_mode:
				current_mode.on_round_start()
		Globals.GameState.POST_ROUND:
			# Score collection now happens in _on_mode_round_end BEFORE state change
			# Call on_round_end on mode if it still exists
			if current_mode:
				current_mode.on_round_end()
			
			# Auto-transition to next round after delay (if not max rounds)
			if Lobby.is_host():
				await get_tree().create_timer(5.0).timeout
				if round_number >= max_rounds:
					change_state(Globals.GameState.GAME_OVER)
				else:
					change_state(Globals.GameState.PRE_ROUND)


func _on_mode_round_end() -> void:
	# Mode signaled that round should end
	if multiplayer.is_server():
		# Collect score updates BEFORE state change (which destroys the scene/mode)
		if current_mode:
			var winner_ids = current_mode.get_winner_ids()
			var score_updates = current_mode.get_round_score_updates()
			
			# Update player scores
			for player_id in score_updates:
				if not player_scores.has(player_id):
					player_scores[player_id] = 0
				player_scores[player_id] += score_updates[player_id]
			
			# Emit round ended with winners
			round_ended.emit(winner_ids)
		
		# Now change state (this will trigger scene destruction)
		change_state(Globals.GameState.POST_ROUND)


func _on_mode_data_updated() -> void:
	# Mode signaled that UI data changed
	if current_mode:
		mode_data_changed.emit(current_mode.get_mode_data())


func init_player_score(player_id: int) -> void:
	if not player_scores.has(player_id):
		player_scores[player_id] = 0